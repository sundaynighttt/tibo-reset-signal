import unittest

from collector.scoring import score_post


class ScoringTests(unittest.TestCase):
    def test_explicit_timed_reset_is_green(self) -> None:
        result = score_post("We will do a full reset of usage tomorrow.")
        self.assertEqual(result.level, "green")
        self.assertGreaterEqual(result.score, 7)
        self.assertIn("explicit_reset", result.reason_codes)
        self.assertIn("specific_time", result.reason_codes)

    def test_investigation_without_reset_is_yellow(self) -> None:
        result = score_post("We are investigating Codex rate limits and cache efficiency.")
        self.assertEqual(result.level, "yellow")
        self.assertEqual(result.score, 3)

    def test_negated_reset_is_not_a_signal(self) -> None:
        result = score_post("There will be no reset today for usage limits.")
        self.assertEqual(result.level, "red")
        self.assertEqual(result.score, 0)
        self.assertIn("negated", result.reason_codes)

    def test_irrelevant_post_is_red(self) -> None:
        result = score_post("A pleasant day to build small tools.")
        self.assertEqual(result.level, "red")
        self.assertEqual(result.score, 0)


if __name__ == "__main__":
    unittest.main()
