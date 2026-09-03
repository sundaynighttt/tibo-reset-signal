using System.Windows.Media;

namespace TiboResetSignal.WinApp;

internal static class SignalColors
{
    internal static Color For(SignalLevel level) => level switch
    {
        SignalLevel.Red => Color.FromRgb(235, 91, 91),
        SignalLevel.Yellow => Color.FromRgb(236, 174, 73),
        SignalLevel.Green => Color.FromRgb(91, 214, 150),
        _ => Color.FromRgb(115, 115, 122)
    };
}
