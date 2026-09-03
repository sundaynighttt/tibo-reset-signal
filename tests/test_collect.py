import os
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from collector.collect import (
    SourceResult,
    api_credit_status,
    build_evidence,
    collect_live_source,
    estimate_api_credit_status,
    fetch_x_api_source,
    normalize_codex_reset_feed,
    normalize_dayclaw_feed,
)


class ApiCreditTests(unittest.TestCase):
    def test_maps_balance_to_public_status_without_exposing_amount(self) -> None:
        self.assertEqual(api_credit_status(0, 1.0), "exhausted")
        self.assertEqual(api_credit_status("0.75", 1.0), "low")
        self.assertEqual(api_credit_status(1, 1.0), "sufficient")

    def test_estimate_deducts_only_returned_resources(self) -> None:
        source = SourceResult(
            "x_api",
            "1",
            [{"id": "1"}, {"id": "2"}, {"id": "3"}],
            billed_post_reads=3,
            billed_user_reads=1,
        )
        with patch.dict(
            os.environ,
            {
                "X_CREDIT_ESTIMATE_BASE_USD": "10",
                "X_CREDIT_ESTIMATE_REVISION": "initial",
            },
            clear=False,
        ):
            payload = estimate_api_credit_status(
                {},
                source,
                datetime(2026, 9, 3, tzinfo=timezone.utc),
                True,
            )

        self.assertEqual(
            payload,
            {
                "status": "sufficient",
                "checkedAt": "2026-09-03T00:00:00Z",
                "estimatedBalanceUsd": 9.975,
                "estimateRevision": "initial",
            },
        )

    def test_estimate_continues_from_previous_published_state(self) -> None:
        previous = {
            "apiCredits": {
                "status": "sufficient",
                "estimatedBalanceUsd": 9.975,
                "estimateRevision": "initial",
            }
        }
        source = SourceResult(
            "x_api",
            "1",
            [{"id": "4"}],
            billed_post_reads=1,
        )
        with patch.dict(
            os.environ,
            {
                "X_CREDIT_ESTIMATE_BASE_USD": "10",
                "X_CREDIT_ESTIMATE_REVISION": "initial",
            },
            clear=False,
        ):
            payload = estimate_api_credit_status(
                previous,
                source,
                datetime(2026, 9, 3, 1, tzinfo=timezone.utc),
                True,
            )

        self.assertEqual(payload["estimatedBalanceUsd"], 9.97)

    def test_new_revision_resets_estimate_after_top_up(self) -> None:
        previous = {
            "apiCredits": {
                "status": "low",
                "estimatedBalanceUsd": 0.5,
                "estimateRevision": "before-top-up",
            }
        }
        with patch.dict(
            os.environ,
            {
                "X_CREDIT_ESTIMATE_BASE_USD": "5",
                "X_CREDIT_ESTIMATE_REVISION": "after-top-up",
            },
            clear=False,
        ):
            payload = estimate_api_credit_status(
                previous,
                None,
                datetime(2026, 9, 3, tzinfo=timezone.utc),
                True,
            )

        self.assertEqual(payload["estimatedBalanceUsd"], 5.0)
        self.assertEqual(payload["estimateRevision"], "after-top-up")

    def test_estimate_requires_operator_configuration(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            payload = estimate_api_credit_status(
                {},
                None,
                datetime(2026, 9, 3, tzinfo=timezone.utc),
                True,
            )

        self.assertEqual(payload, {"status": "unknown", "checkedAt": None})

    @patch("collector.collect.fetch_posts")
    @patch("collector.collect.resolve_user_id")
    def test_x_api_source_reports_returned_billable_resources(
        self,
        resolve_user_id,
        fetch_posts,
    ) -> None:
        resolve_user_id.return_value = ("1", 1)
        fetch_posts.return_value = [{"id": "10"}, {"id": "11"}]

        result = fetch_x_api_source("thsottiaux", "token", {}, None)

        self.assertEqual(result.billed_user_reads, 1)
        self.assertEqual(result.billed_post_reads, 2)


class PublicFeedTests(unittest.TestCase):
    def test_codex_reset_feed_accepts_only_verified_target_posts(self) -> None:
        payload = {
            "stale": False,
            "profile": {"handle": "thsottiaux"},
            "tweets": [
                {
                    "id": "2100000000000000001",
                    "text": "Codex usage reset will land tomorrow.",
                    "at": "2026-09-03T00:00:00Z",
                    "url": "https://x.com/thsottiaux/status/2100000000000000001",
                },
                {
                    "id": "2100000000000000002",
                    "text": "Injected post",
                    "at": "2026-09-03T00:01:00Z",
                    "url": "https://x.com/not-tibo/status/2100000000000000002",
                },
            ],
        }

        posts = normalize_codex_reset_feed(payload, "thsottiaux")

        self.assertEqual([post["id"] for post in posts], ["2100000000000000001"])

    def test_codex_reset_feed_rejects_stale_payload(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "stale"):
            normalize_codex_reset_feed(
                {"stale": True, "profile": {"handle": "thsottiaux"}, "tweets": []},
                "thsottiaux",
            )

    def test_dayclaw_feed_validates_author_and_canonical_url(self) -> None:
        payload = {
            "source": {"user_name": "thsottiaux"},
            "items": [
                {
                    "external_id": "2100000000000000003",
                    "content": "We reset Codex usage.",
                    "published_at": "2026-09-03T00:00:00",
                    "url": "https://x.com/thsottiaux/status/2100000000000000003",
                    "author": "thsottiaux",
                },
                {
                    "external_id": "2100000000000000004",
                    "content": "Wrong author",
                    "published_at": "2026-09-03T00:01:00",
                    "url": "https://x.com/thsottiaux/status/2100000000000000004",
                    "author": "someone_else",
                },
            ],
        }

        posts = normalize_dayclaw_feed(payload, "thsottiaux")

        self.assertEqual([post["id"] for post in posts], ["2100000000000000003"])

    def test_old_feed_posts_do_not_create_a_fresh_signal(self) -> None:
        posts = [
            {
                "id": "2100000000000000005",
                "text": "Codex usage reset will land tomorrow.",
                "created_at": "2026-08-01T00:00:00Z",
            }
        ]

        evidence = build_evidence(
            "thsottiaux",
            posts,
            datetime(2026, 9, 3, tzinfo=timezone.utc),
        )

        self.assertEqual(evidence, [])

    @patch("collector.collect.fetch_codex_reset_source")
    @patch("collector.collect.fetch_x_api_source")
    def test_auto_falls_back_when_x_api_fails(self, fetch_x, fetch_public) -> None:
        fetch_x.side_effect = RuntimeError("temporary failure")
        fetch_public.return_value = SourceResult(
            "codex_reset_feed",
            None,
            [],
            True,
        )

        with patch.dict(os.environ, {"X_BEARER_TOKEN": "test-token"}, clear=False):
            result = collect_live_source("thsottiaux", {}, None)

        self.assertEqual(result.provider, "codex_reset_feed")
        self.assertTrue(result.is_fallback)
        self.assertIn("temporary failure", result.message or "")


if __name__ == "__main__":
    unittest.main()
