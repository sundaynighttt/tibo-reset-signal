using System.IO;
using System.Net.Http;
using System.Text.Json;

namespace TiboResetSignal.WinApp;

public sealed class SignalClient
{
    public static readonly Uri ProductionEndpoint = new(
        "https://sundaynighttt.github.io/tibo-reset-signal/latest.json");

    private readonly HttpClient _httpClient;
    private readonly Uri _endpoint;

    public SignalClient(HttpClient? httpClient = null, Uri? endpoint = null)
    {
        _httpClient = httpClient ?? new HttpClient { Timeout = TimeSpan.FromSeconds(20) };
        _endpoint = endpoint ?? ProductionEndpoint;
    }

    public async Task<SignalPayload> FetchAsync(CancellationToken cancellationToken = default)
    {
        var separator = string.IsNullOrEmpty(_endpoint.Query) ? "?" : "&";
        var minute = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / 60;
        using var request = new HttpRequestMessage(HttpMethod.Get, new Uri($"{_endpoint}{separator}minute={minute}"));
        request.Headers.Accept.ParseAdd("application/json");
        using var response = await _httpClient.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        var payload = await JsonSerializer.DeserializeAsync<SignalPayload>(stream, SignalJson.Options, cancellationToken)
                      ?? throw new InvalidDataException("Signal payload was empty.");
        if (payload.SchemaVersion != 1) throw new InvalidDataException("Unsupported signal schema.");
        return payload;
    }
}
