from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class ScoreResult:
    score: int
    level: str
    reason_codes: tuple[str, ...]
    active_hours: int


EXPLICIT_RESET_PATTERNS = (
    r"\bfull reset\b",
    r"\bhard reset\b",
    r"\busage reset\b",
    r"\breset(?:ting|s|ted)? (?:the )?(?:usage|rate limits?|limits?|quota)\b",
    r"\b(?:usage|rate limits?|limits?|quota) (?:has |have |is |are )?reset\b",
    r"\breset has been propagated\b",
    r"\bpressed the (?:reset )?button\b",
)

GENERIC_RESET_PATTERN = r"\breset(?:ting|s|ted)?\b"
NEGATION_PATTERNS = (
    r"\bno (?:full |hard |usage )?reset\b",
    r"\bnot (?:a |the )?(?:full |hard |usage )?reset\b",
    r"\b(?:won't|will not|isn't|is not) reset\b",
    r"\bwithout (?:a |the )?reset\b",
)
TIME_PATTERNS = (
    r"\b(?:today|tomorrow|tonight)\b",
    r"\bin (?:the next )?\d+ (?:minute|minutes|hour|hours)\b",
    r"\b(?:at|around|by) \d{1,2}(?::\d{2})?\s?(?:am|pm)?\s?(?:pt|pst|pdt|utc)?\b",
)
COMMITMENT_PATTERNS = (
    r"\bwill (?:land|ship|roll out|reset|do|propagate)\b",
    r"\b(?:landing|shipping|rolling out|propagating)\b",
    r"\b(?:has|have) been propagated\b",
    r"\b(?:is|are) live\b",
)
USAGE_CONTEXT_PATTERNS = (
    r"\bcodex\b",
    r"\busage\b",
    r"\brate limits?\b",
    r"\bquota\b",
    r"\bpaid subscriptions?\b",
)
INVESTIGATION_PATTERNS = (
    r"\binvestigat(?:e|ing|ed|ion)\b",
    r"\btiger team\b",
    r"\bwar room\b",
    r"\bcache hit\b",
    r"\befficien(?:cy|t)\b",
    r"\bshipping fixes\b",
)


def _matches_any(text: str, patterns: tuple[str, ...]) -> bool:
    return any(re.search(pattern, text, flags=re.IGNORECASE) for pattern in patterns)


def level_for_score(score: int) -> str:
    if score >= 7:
        return "green"
    if score >= 3:
        return "yellow"
    return "red"


def score_post(text: str) -> ScoreResult:
    normalized = " ".join(text.split())
    reasons: list[str] = []
    score = 0

    explicit_reset = _matches_any(normalized, EXPLICIT_RESET_PATTERNS)
    generic_reset = bool(re.search(GENERIC_RESET_PATTERN, normalized, flags=re.IGNORECASE))
    negated = _matches_any(normalized, NEGATION_PATTERNS)

    if explicit_reset:
        score += 5
        reasons.append("explicit_reset")
    elif generic_reset:
        score += 3
        reasons.append("reset_mention")

    if _matches_any(normalized, USAGE_CONTEXT_PATTERNS):
        score += 2
        reasons.append("usage_context")

    if explicit_reset or generic_reset:
        if _matches_any(normalized, TIME_PATTERNS):
            score += 4
            reasons.append("specific_time")
        if _matches_any(normalized, COMMITMENT_PATTERNS):
            score += 2
            reasons.append("commitment")
    elif _matches_any(normalized, INVESTIGATION_PATTERNS):
        score += 1
        reasons.append("investigation")

    if negated:
        score = 0
        reasons.append("negated")

    score = max(0, min(10, score))
    level = level_for_score(score)
    active_hours = 24 if level == "green" else 12 if level == "yellow" else 0
    return ScoreResult(score, level, tuple(reasons), active_hours)
