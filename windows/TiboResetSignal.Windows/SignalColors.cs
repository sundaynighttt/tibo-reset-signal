using MediaColor = System.Windows.Media.Color;

namespace TiboResetSignal.WinApp;

internal static class SignalColors
{
    internal static MediaColor For(SignalLevel level) => level switch
    {
        SignalLevel.Red => MediaColor.FromRgb(235, 91, 91),
        SignalLevel.Yellow => MediaColor.FromRgb(236, 174, 73),
        SignalLevel.Green => MediaColor.FromRgb(91, 214, 150),
        _ => MediaColor.FromRgb(115, 115, 122)
    };
}
