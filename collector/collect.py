from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from collector.scoring import level_for_score, score_post


DEFAULT_USERNAME = "thsottiaux"
DEFAULT_OUTPUT = Path("site/latest.json")
X_API_BASE = "https://api.x.com/2"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_previous(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def request_json(url: str, bearer_token: str) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {bearer_token}",
            "User-Agent": "tibo-reset-signal/0.1 (+https://github.com/sundaynighttt/tibo-reset-signal)",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"X API returned HTTP {error.code}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"X API request failed: {error.reason}") from error


def resolve_user_id(username: str, token: str, previous: dict[str, Any]) -> str:
    configured = os.environ.get("TARGET_USER_ID")
    if configured:
        return configured
    previous_target = previous.get("target") or {}
    if previous_target.get("username") == username and previous_target.get("userId"):
        return str(previous_target["userId"])

    encoded = urllib.parse.quote(username)
    payload = request_json(f"{X_API_BASE}/users/by/username/{encoded}", token)
    user_id = (payload.get("data") or {}).get("id")
    if not user_id:
        raise RuntimeError("X API did not return the target user ID")
    return str(user_id)


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
    payload = request_json(url, token)
    return list(payload.get("data") or [])


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
        evidence.append(
            {
                "postId": post_id,
                "url": f"https://x.com/{username}/status/{post_id}",
                "score": result.score,
                "reasonCodes": list(result.reason_codes),
                "detectedAt": isoformat(now),
                "activeUntil": isoformat(now + timedelta(hours=result.active_hours)),
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

    try:
        if args.fixture:
            user_id, posts = load_fixture(Path(args.fixture))
        else:
            token = os.environ.get("X_BEARER_TOKEN")
            if not token:
                raise RuntimeError("X_BEARER_TOKEN is not configured")
            user_id = resolve_user_id(username, token, previous)
            posts = fetch_posts(user_id, token, str(previous_id) if previous_id else None)

        evidence = merge_active_evidence(previous, build_evidence(username, posts, now), now)
        payload = {
            "schemaVersion": 1,
            "target": {"username": username, "userId": user_id},
            "signal": compute_signal(evidence),
            "source": {
                "status": "ok",
                "checkedAt": isoformat(now),
                "lastSuccessfulCheckAt": isoformat(now),
            },
            "lastSeenPostId": newest_post_id(posts, str(previous_id) if previous_id else None),
            "evidence": evidence,
        }
        write_payload(output, payload)
        return 0
    except Exception as error:  # Keep the last good signal while exposing source failure.
        previous_source = previous.get("source") or {}
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
                "checkedAt": isoformat(now),
                "lastSuccessfulCheckAt": previous_source.get("lastSuccessfulCheckAt"),
                "message": str(error)[:240],
            },
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
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(collect(parse_args()))
