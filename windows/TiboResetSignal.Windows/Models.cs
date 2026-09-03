using System.Text.Json;
using System.Text.Json.Serialization;

namespace TiboResetSignal.WinApp;

public enum SignalLevel
{
    Red,
    Yellow,
    Green,
    Stale
}

public sealed record SignalTarget(string Username, string? UserId);
public sealed record SignalSummary(SignalLevel Level, int Score, string Summary);
public sealed record SignalSource(
    string Status,
    DateTimeOffset? CheckedAt,
    DateTimeOffset? LastSuccessfulCheckAt,
    string? Message);
public enum ApiCreditStatus
{
    Sufficient,
    Low,
    Exhausted,
    Unknown
}
public sealed record ApiCredits(
    ApiCreditStatus Status,
    DateTimeOffset? CheckedAt,
    double? EstimatedBalanceUsd = null,
    string? EstimateRevision = null);
public sealed record SignalEvidence(
    string PostId,
    Uri Url,
    int Score,
    IReadOnlyList<string> ReasonCodes,
    DateTimeOffset DetectedAt,
    DateTimeOffset ActiveUntil);

public sealed record SignalPayload(
    int SchemaVersion,
    SignalTarget Target,
    SignalSummary Signal,
    SignalSource Source,
    ApiCredits? ApiCredits,
    string? LastSeenPostId,
    IReadOnlyList<SignalEvidence> Evidence)
{
    public SignalLevel EffectiveLevel(DateTimeOffset? now = null)
    {
        var current = now ?? DateTimeOffset.UtcNow;
        if (!string.Equals(Source.Status, "ok", StringComparison.OrdinalIgnoreCase) ||
            Source.LastSuccessfulCheckAt is null ||
            current - Source.LastSuccessfulCheckAt.Value > TimeSpan.FromHours(2))
        {
            return SignalLevel.Stale;
        }
        return Signal.Level;
    }
}

internal static class SignalJson
{
    internal static readonly JsonSerializerOptions Options = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
    };
}

internal static class SignalText
{
    internal static string LevelName(SignalLevel level) => level switch
    {
        SignalLevel.Red => "RED",
        SignalLevel.Yellow => "YELLOW",
        SignalLevel.Green => "GREEN",
        _ => "STALE"
    };

    internal static string KoreanLevelName(SignalLevel level) => level switch
    {
        SignalLevel.Red => "신호 없음",
        SignalLevel.Yellow => "가능성 있음",
        SignalLevel.Green => "강한 신호",
        _ => "확인 지연"
    };

    internal static string Reason(string code) => code switch
    {
        "explicit_reset" => "명확한 리셋 표현",
        "reset_mention" => "리셋 언급",
        "specific_time" => "구체적인 시간",
        "commitment" => "실행 확정 표현",
        "usage_context" => "사용량·한도 문맥",
        "investigation" => "문제 조사 정황",
        "negated" => "부정 표현",
        _ => code.Replace('_', ' ')
    };

    internal static string ApiCreditName(ApiCreditStatus? status) => status switch
    {
        ApiCreditStatus.Sufficient => "충분",
        ApiCreditStatus.Low => "낮음",
        ApiCreditStatus.Exhausted => "소진",
        _ => "확인 불가"
    };

    internal static string ApiCreditDescription(ApiCredits? credits)
    {
        var status = ApiCreditName(credits?.Status);
        return credits?.EstimatedBalanceUsd is double balance
            ? $"{status} · 약 ${balance:F2}"
            : status;
    }

    internal static string UpdateText(DateTimeOffset? date)
    {
        if (date is null) return "정상 확인 기록 없음";
        var minutes = Math.Max(0, (int)(DateTimeOffset.UtcNow - date.Value).TotalMinutes);
        if (minutes < 1) return "방금 확인";
        if (minutes < 60) return $"{minutes}분 전 확인";
        return $"{minutes / 60}시간 전 확인";
    }
}

internal static class SignalModelSelfTest
{
    internal static void Run()
    {
        const string json = """
        {
          "schemaVersion": 1,
          "target": {"username": "thsottiaux", "userId": "1"},
          "signal": {"level": "green", "score": 9, "summary": "Strong reset signal"},
          "source": {
            "status": "ok",
            "checkedAt": "2099-01-01T00:00:00Z",
            "lastSuccessfulCheckAt": "2099-01-01T00:00:00Z"
          },
          "apiCredits": {
            "status": "sufficient",
            "checkedAt": "2099-01-01T00:00:00Z",
            "estimatedBalanceUsd": 9.975,
            "estimateRevision": "initial"
          },
          "lastSeenPostId": "1",
          "evidence": []
        }
        """;
        var payload = JsonSerializer.Deserialize<SignalPayload>(json, SignalJson.Options)
                      ?? throw new InvalidOperationException("Payload did not decode.");
        if (payload.SchemaVersion != 1 || payload.Signal.Score != 9 ||
            payload.ApiCredits?.Status != ApiCreditStatus.Sufficient ||
            payload.ApiCredits?.EstimatedBalanceUsd != 9.975 ||
            payload.EffectiveLevel(new DateTimeOffset(2099, 1, 1, 0, 30, 0, TimeSpan.Zero)) != SignalLevel.Green)
        {
            throw new InvalidOperationException("Signal model self-test failed.");
        }
    }
}

public enum DisplayMode
{
    TaskbarLabel,
    FloatingPill
}
