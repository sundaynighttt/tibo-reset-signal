from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable

from collector.scoring import level_for_score, score_post


DEFAULT_USERNAME = "thsottiaux"
DEFAULT_OUTPUT = Path("site/latest.json")
X_API_BASE = "https://api.x.com/2"
CODEX_RESET_FEED_URL = "https://codex-reset.com/api/feed"
DAYCLAW_ITEMS_BASE_URL = "https://api.dayclaw.com/api/source/public/x"
DEFAULT_LOW_CREDIT_USD = 1.0
POST_READ_PRICE_USD = Decimal("0.005")
USER_READ_PRICE_USD = Decimal("0.010")
ESTIMATE_PRECISION_USD = Decimal("0.001")


@dataclass(frozen=True)
class SourceResult:
    provider: str
    user_id: str | None
    posts: list[dict[str, Any]]
    is_fallback: bool = False
    message: str | None = None
    billed_post_reads: int = 0
    billed_user_reads: int = 0


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def load_previous(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def request_json(
    url: str,
    bearer_token: str | None = None,
    source_label: str = "Source",
) -> dict[str, Any]:
    headers = {
        "Accept": "application/json",
        "User-Agent": "tibo-reset-signal/0.1 (+https://github.com/sundaynighttt/tibo-reset-signal)",
    }
    if bearer_token:
        headers["Authorization"] = f"Bearer {bearer_token}"
    request = urllib.request.Request(
        url,
        headers=headers,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
            if not isinstance(payload, dict):
                raise RuntimeError(f"{source_label} returned a non-object JSON payload")
            return payload
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"{source_label} returned HTTP {error.code}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"{source_label} request failed: {error.reason}") from error
    except json.JSONDecodeError as error:
        raise RuntimeError(f"{source_label} returned invalid JSON") from error


def resolve_user_id(
    username: str,
    token: str,
    previous: dict[str, Any],
) -> tuple[str, int]:
    configured = os.environ.get("TARGET_USER_ID")
    if configured:
        return configured, 0
    previous_target = previous.get("target") or {}
    if previous_target.get("username") == username and previous_target.get("userId"):
        return str(previous_target["userId"]), 0

    encoded = urllib.parse.quote(username)
    payload = request_json(
        f"{X_API_BASE}/users/by/username/{encoded}",
        token,
        "X API",
    )
    user_id = (payload.get("data") or {}).get("id")
    if not user_id:
        raise RuntimeError("X API did not return the target user ID")
    return str(user_id), 1


def fetch_posts(
    user_id: str,
    token: str,
    since_id: str | None,
) -> list[dict[str, Any]]:
    query: dict[str, str] = {
        "max_results": "10",
        "exclude": "retweets",
        "tweet.fields": "created_at",
    }
    if since_id:
        query["since_id"] = since_id
    url = f"{X_API_BASE}/users/{urllib.parse.quote(user_id)}/tweets?{urllib.parse.urlencode(query)}"
    payload = request_json(url, token, "X API")
    return list(payload.get("data") or [])


def decimal_money(value: Any, label: str) -> Decimal:
    if isinstance(value, bool):
        raise RuntimeError(f"{label} is invalid")
    try:
        amount = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError) as error:
        raise RuntimeError(f"{label} is invalid") from error
    if not amount.is_finite():
        raise RuntimeError(f"{label} is invalid")
    return amount


def api_credit_status(total_balance: Any, low_threshold: float | Decimal) -> str:
    balance = decimal_money(total_balance, "Credit balance")
    threshold = decimal_money(low_threshold, "Low credit threshold")
    if balance <= 0:
        return "exhausted"
    if balance < threshold:
        return "low"
    return "sufficient"


def estimate_api_credit_status(
    previous: dict[str, Any],
    source_result: SourceResult | None,
    now: datetime,
    token_configured: bool,
    low_threshold: float | Decimal = DEFAULT_LOW_CREDIT_USD,
) -> dict[str, Any]:
    checked_at = isoformat(now)
    base_value = (os.environ.get("X_CREDIT_ESTIMATE_BASE_USD") or "").strip()
    revision = (os.environ.get("X_CREDIT_ESTIMATE_REVISION") or "").strip()
    if not token_configured or not base_value or not revision:
        return {"status": "unknown", "checkedAt": None}

    try:
        base_balance = decimal_money(base_value, "Credit estimate base")
        if base_balance < 0:
            raise RuntimeError("Credit estimate base is invalid")

        previous_credits = previous.get("apiCredits") or {}
        if (
            previous_credits.get("estimateRevision") == revision
            and previous_credits.get("estimatedBalanceUsd") is not None
        ):
            balance = decimal_money(
                previous_credits["estimatedBalanceUsd"],
                "Previous credit estimate",
            )
        else:
            balance = base_balance
        balance = max(Decimal("0"), balance)

        if source_result:
            charge = (
                Decimal(source_result.billed_post_reads) * POST_READ_PRICE_USD
                + Decimal(source_result.billed_user_reads) * USER_READ_PRICE_USD
            )
            balance = max(Decimal("0"), balance - charge)

        rounded = balance.quantize(ESTIMATE_PRECISION_USD, rounding=ROUND_HALF_UP)
        return {
            "status": api_credit_status(rounded, low_threshold),
            "checkedAt": checked_at,
            "estimatedBalanceUsd": float(rounded),
            "estimateRevision": revision,
        }
    except Exception:
        return {"status": "unknown", "checkedAt": checked_at}


def is_canonical_post_url(url: str, username: str, post_id: str) -> bool:
    try:
        parsed = urllib.parse.urlparse(url)
    except ValueError:
        return False
    if parsed.scheme != "https" or (parsed.hostname or "").lower() not in {
        "x.com",
        "www.x.com",
        "twitter.com",
        "www.twitter.com",
    }:
        return False
    parts = [urllib.parse.unquote(part) for part in parsed.path.split("/") if part]
    return (
        len(parts) >= 3
        and parts[0].casefold() == username.casefold()
        and parts[1].casefold() == "status"
        and parts[2] == post_id
    )


def only_new_posts(
    posts: list[dict[str, Any]],
    since_id: str | None,
) -> list[dict[str, Any]]:
    if not since_id or not since_id.isdigit():
        return posts
    return [
        post
        for post in posts
        if str(post.get("id", "")).isdigit()
        and int(str(post["id"])) > int(since_id)
    ]


def normalize_codex_reset_feed(
    payload: dict[str, Any],
    username: str,
) -> list[dict[str, Any]]:
    profile = payload.get("profile") or {}
    if str(profile.get("handle", "")).casefold() != username.casefold():
        raise RuntimeError("Codex Reset feed returned an unexpected source account")
    if payload.get("stale") is not False:
        raise RuntimeError("Codex Reset feed is stale")

    candidates = list(payload.get("tweets") or []) + list(
        payload.get("radar_context") or []
    )
    posts: dict[str, dict[str, Any]] = {}
    for item in candidates:
        if not isinstance(item, dict):
            continue
        post_id = str(item.get("id", ""))
        text = str(item.get("text") or item.get("summary") or "").strip()
        created_at = str(
            item.get("at") or item.get("created_at") or item.get("declared_at") or ""
        )
        url = str(item.get("url", ""))
        if (
            post_id.isdigit()
            and text
            and parse_datetime(created_at)
            and is_canonical_post_url(url, username, post_id)
        ):
            posts[post_id] = {"id": post_id, "text": text, "created_at": created_at}
    if not posts:
        raise RuntimeError("Codex Reset feed returned no verified posts")
    return sorted(posts.values(), key=lambda post: int(str(post["id"])), reverse=True)


def normalize_dayclaw_feed(
    payload: dict[str, Any],
    username: str,
) -> list[dict[str, Any]]:
    source = payload.get("source") or {}
    if str(source.get("user_name", "")).casefold() != username.casefold():
        raise RuntimeError("Dayclaw returned an unexpected source account")

    posts: dict[str, dict[str, Any]] = {}
    for item in list(payload.get("items") or []):
        if not isinstance(item, dict):
            continue
        post_id = str(item.get("external_id", ""))
        author = str(item.get("author", ""))
        text = str(item.get("content") or item.get("title") or "").strip()
        created_at = str(item.get("published_at", ""))
        url = str(item.get("url", ""))
        if (
            post_id.isdigit()
            and author.casefold() == username.casefold()
            and text
            and parse_datetime(created_at)
            and is_canonical_post_url(url, username, post_id)
        ):
            posts[post_id] = {"id": post_id, "text": text, "created_at": created_at}
    if not posts:
        raise RuntimeError("Dayclaw returned no verified posts")
    return sorted(posts.values(), key=lambda post: int(str(post["id"])), reverse=True)


def fetch_x_api_source(
    username: str,
    token: str,
    previous: dict[str, Any],
    since_id: str | None,
) -> SourceResult:
    user_id, billed_user_reads = resolve_user_id(username, token, previous)
    posts = fetch_posts(user_id, token, since_id)
    return SourceResult(
        "x_api",
        user_id,
        posts,
        billed_post_reads=len(posts),
        billed_user_reads=billed_user_reads,
    )


def fetch_codex_reset_source(username: str, since_id: str | None) -> SourceResult:
    url = os.environ.get("CODEX_RESET_FEED_URL", CODEX_RESET_FEED_URL).strip()
    if not url:
        raise RuntimeError("Codex Reset feed is disabled")
    posts = normalize_codex_reset_feed(
        request_json(url, source_label="Codex Reset feed"),
        username,
    )
    return SourceResult("codex_reset_feed", None, only_new_posts(posts, since_id), True)


def fetch_dayclaw_source(username: str, since_id: str | None) -> SourceResult:
    base_url = os.environ.get(
        "DAYCLAW_ITEMS_BASE_URL",
        DAYCLAW_ITEMS_BASE_URL,
    ).strip()
    if not base_url:
        raise RuntimeError("Dayclaw feed is disabled")
    url = f"{base_url.rstrip('/')}/{urllib.parse.quote(username)}/items"
    posts = normalize_dayclaw_feed(request_json(url, source_label="Dayclaw"), username)
    return SourceResult("dayclaw", None, only_new_posts(posts, since_id), True)


def collect_live_source(
    username: str,
    previous: dict[str, Any],
    since_id: str | None,
    source_mode: str = "auto",
) -> SourceResult:
    failures: list[str] = []
    token = (os.environ.get("X_BEARER_TOKEN") or "").strip()
    providers: list[tuple[str, Callable[[], SourceResult]]] = []
    if source_mode in {"auto", "x-api"}:
        if token:
            providers.append(
                ("x_api", lambda: fetch_x_api_source(username, token, previous, since_id))
            )
        elif source_mode == "x-api":
            raise RuntimeError("X_BEARER_TOKEN is not configured")
        else:
            failures.append("X API not configured")
    if source_mode in {"auto", "codex-reset"}:
        providers.append(
            ("codex_reset_feed", lambda: fetch_codex_reset_source(username, since_id))
        )
    if source_mode in {"auto", "dayclaw"}:
        providers.append(("dayclaw", lambda: fetch_dayclaw_source(username, since_id)))

    for provider, fetch in providers:
        try:
            result = fetch()
            if failures:
                return SourceResult(
                    result.provider,
                    result.user_id,
                    result.posts,
                    result.is_fallback,
                    f"Using {provider} after: {'; '.join(failures)}",
                    result.billed_post_reads,
                    result.billed_user_reads,
                )
            return result
        except Exception as error:
            failures.append(f"{provider}: {error}")
    raise RuntimeError("All configured sources failed: " + "; ".join(failures))


def load_fixture(path: Path) -> tuple[str, list[dict[str, Any]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return str(payload.get("userId", "fixture-user")), list(payload.get("posts") or [])


def build_evidence(
    username: str,
    posts: list[dict[str, Any]],
    now: datetime,
) -> list[dict[str, Any]]:
    evidence: list[dict[str, Any]] = []
    for post in posts:
        post_id = str(post.get("id", ""))
        text = str(post.get("text", ""))
        if not post_id or not text:
            continue
        result = score_post(text)
        if result.score < 3:
            continue
        published_at = parse_datetime(str(post.get("created_at") or ""))
        active_from = (
            published_at
            if published_at and published_at <= now + timedelta(minutes=5)
            else now
        )
        active_until = active_from + timedelta(hours=result.active_hours)
        if active_until <= now:
            continue
        evidence.append(
            {
                "postId": post_id,
                "url": f"https://x.com/{username}/status/{post_id}",
                "score": result.score,
                "reasonCodes": list(result.reason_codes),
                "detectedAt": isoformat(now),
                "activeUntil": isoformat(active_until),
            }
        )
    return evidence


def merge_active_evidence(
    previous: dict[str, Any],
    new_evidence: list[dict[str, Any]],
    now: datetime,
) -> list[dict[str, Any]]:
    merged: dict[str, dict[str, Any]] = {}
    for item in list(previous.get("evidence") or []) + new_evidence:
        post_id = str(item.get("postId", ""))
        active_until = parse_datetime(item.get("activeUntil"))
        if post_id and active_until and active_until > now:
            merged[post_id] = item
    return sorted(
        merged.values(),
        key=lambda item: (int(item.get("score", 0)), str(item.get("postId", ""))),
        reverse=True,
    )[:5]


def compute_signal(evidence: list[dict[str, Any]]) -> dict[str, Any]:
    if not evidence:
        return {"level": "red", "score": 0, "summary": "No active reset signal"}
    best = max(int(item.get("score", 0)) for item in evidence)
    combined = min(10, best + min(2, max(0, len(evidence) - 1)))
    level = level_for_score(combined)
    summaries = {
        "red": "No active reset signal",
        "yellow": "Possible reset signal",
        "green": "Strong reset signal",
    }
    return {"level": level, "score": combined, "summary": summaries[level]}


def newest_post_id(posts: list[dict[str, Any]], previous_id: str | None) -> str | None:
    ids = [str(post.get("id")) for post in posts if str(post.get("id", "")).isdigit()]
    candidates = ids + ([previous_id] if previous_id and previous_id.isdigit() else [])
    return max(candidates, key=int) if candidates else previous_id


def write_payload(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def collect(args: argparse.Namespace) -> int:
    now = utc_now()
    output = Path(args.output)
    previous_path = Path(args.previous) if args.previous else output
    previous = load_previous(previous_path)
    previous_id = previous.get("lastSeenPostId")
    username = args.username
    token = (os.environ.get("X_BEARER_TOKEN") or "").strip()
    try:
        low_credit_usd = decimal_money(
            os.environ.get("X_CREDIT_LOW_USD", str(DEFAULT_LOW_CREDIT_USD)),
            "Low credit threshold",
        )
        if low_credit_usd <= 0:
            raise RuntimeError("Low credit threshold is invalid")
    except RuntimeError:
        low_credit_usd = Decimal(str(DEFAULT_LOW_CREDIT_USD))

    try:
        if args.fixture:
            user_id, posts = load_fixture(Path(args.fixture))
            source_result = SourceResult("fixture", user_id, posts)
        else:
            source_result = collect_live_source(
                username,
                previous,
                str(previous_id) if previous_id else None,
                args.source,
            )

        user_id = source_result.user_id or (previous.get("target") or {}).get("userId")
        posts = source_result.posts
        api_credits = (
            {"status": "unknown", "checkedAt": None}
            if args.fixture
            else estimate_api_credit_status(
                previous,
                source_result,
                now,
                bool(token),
                low_credit_usd,
            )
        )

        evidence = merge_active_evidence(previous, build_evidence(username, posts, now), now)
        source_payload: dict[str, Any] = {
            "status": "ok",
            "provider": source_result.provider,
            "isFallback": source_result.is_fallback,
            "checkedAt": isoformat(now),
            "lastSuccessfulCheckAt": isoformat(now),
        }
        if source_result.message:
            source_payload["message"] = source_result.message[:240]
        payload = {
            "schemaVersion": 1,
            "target": {"username": username, "userId": user_id},
            "signal": compute_signal(evidence),
            "source": source_payload,
            "apiCredits": api_credits,
            "lastSeenPostId": newest_post_id(posts, str(previous_id) if previous_id else None),
            "evidence": evidence,
        }
        write_payload(output, payload)
        return 0
    except Exception as error:  # Keep the last good signal while exposing source failure.
        previous_source = previous.get("source") or {}
        api_credits = (
            {"status": "unknown", "checkedAt": None}
            if args.fixture
            else estimate_api_credit_status(
                previous,
                None,
                now,
                bool(token),
                low_credit_usd,
            )
        )
        payload = {
            "schemaVersion": 1,
            "target": previous.get("target") or {"username": username, "userId": None},
            "signal": previous.get("signal") or {
                "level": "red",
                "score": 0,
                "summary": "No active reset signal",
            },
            "source": {
                "status": "error",
                "provider": previous_source.get("provider"),
                "isFallback": previous_source.get("isFallback", False),
                "checkedAt": isoformat(now),
                "lastSuccessfulCheckAt": previous_source.get("lastSuccessfulCheckAt"),
                "message": str(error)[:240],
            },
            "apiCredits": api_credits,
            "lastSeenPostId": previous_id,
            "evidence": previous.get("evidence") or [],
        }
        write_payload(output, payload)
        print(f"collector error: {error}", file=sys.stderr)
        return 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Collect and score Tibo reset signals")
    parser.add_argument("--username", default=DEFAULT_USERNAME)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--previous")
    parser.add_argument("--fixture")
    parser.add_argument(
        "--source",
        choices=("auto", "x-api", "codex-reset", "dayclaw"),
        default="auto",
        help="Live source selection; auto prefers X API and then verified public feeds",
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(collect(parse_args()))
