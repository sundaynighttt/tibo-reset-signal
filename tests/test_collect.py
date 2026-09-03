import os
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from collector.collect import (
    SourceResult,
    build_evidence,
    collect_live_source,
    normalize_codex_reset_feed,
    normalize_dayclaw_feed,
)


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
