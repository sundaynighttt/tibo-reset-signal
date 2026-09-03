using System.IO;
using System.Text.Json;

namespace TiboResetSignal.WinApp;

internal static class SignalCache
{
    private static string CachePath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "TiboResetSignal",
        "latest.json");

    internal static SignalPayload? Load()
    {
        try
        {
            return JsonSerializer.Deserialize<SignalPayload>(File.ReadAllText(CachePath), SignalJson.Options);
        }
        catch
        {
            return null;
        }
    }

    internal static void Save(SignalPayload payload)
    {
        try
        {
            var directory = Path.GetDirectoryName(CachePath)!;
            Directory.CreateDirectory(directory);
            var temporary = Path.Combine(directory, $"latest-{Guid.NewGuid():N}.tmp");
            File.WriteAllText(temporary, JsonSerializer.Serialize(payload, SignalJson.Options));
            File.Move(temporary, CachePath, overwrite: true);
        }
        catch (Exception exception)
        {
            AppLog.Write(exception);
        }
    }
}
