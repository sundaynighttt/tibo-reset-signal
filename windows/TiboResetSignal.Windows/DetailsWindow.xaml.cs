using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Shapes;
using MediaBrushes = System.Windows.Media.Brushes;
using MediaColor = System.Windows.Media.Color;
using WpfButton = System.Windows.Controls.Button;
using WpfHorizontalAlignment = System.Windows.HorizontalAlignment;

namespace TiboResetSignal.WinApp;

public partial class DetailsWindow : Window
{
    private IntPtr _windowHandle;

    public DetailsWindow()
    {
        InitializeComponent();
        SourceInitialized += (_, _) =>
        {
            _windowHandle = new WindowInteropHelper(this).Handle;
            NativeMethods.ConfigureToolWindow(_windowHandle, noActivate: false);
        };
    }

    public void UpdateSignal(SignalPayload? payload, string? error)
    {
        RowsPanel.Children.Clear();
        var level = payload?.EffectiveLevel() ?? SignalLevel.Stale;
        MainDot.Fill = new SolidColorBrush(SignalColors.For(level));
        MainStatusText.Text = SignalText.KoreanLevelName(level);
        ScoreText.Text = level == SignalLevel.Stale ? "점수 –" : $"점수 {payload!.Signal.Score} / 10";
        StatusText.Text = error is null ? "@thsottiaux 공개 신호" : "마지막 값 표시 중 · 새로고침 실패";
        CreditText.Text = SignalText.ApiCreditName(payload?.ApiCredits?.Status);
        CreditText.Foreground = payload?.ApiCredits?.Status == ApiCreditStatus.Exhausted
            ? new SolidColorBrush(MediaColor.FromRgb(242, 95, 92))
            : new SolidColorBrush(MediaColor.FromRgb(185, 186, 193));

        if (payload?.Evidence.Count > 0)
        {
            foreach (var evidence in payload.Evidence) AddEvidence(evidence);
        }
        else
        {
            RowsPanel.Children.Add(new TextBlock
            {
                Text = "현재 활성 근거가 없습니다.",
                Foreground = new SolidColorBrush(MediaColor.FromRgb(185, 186, 193)),
                FontSize = 11.5,
                Margin = new Thickness(0, 4, 0, 4)
            });
        }

        UpdatedText.Text = payload is null
            ? "아직 정상 확인 기록이 없습니다."
            : SignalText.UpdateText(payload.Source.LastSuccessfulCheckAt);
    }

    internal void ShowNear(NativeMethods.NativeRect anchor)
    {
        new WindowInteropHelper(this).EnsureHandle();
        if (!IsVisible) Show();
        Activate();
        UpdateLayout();
        NativeMethods.PositionPopup(_windowHandle, anchor, ActualWidth, ActualHeight);
    }

    private void AddEvidence(SignalEvidence evidence)
    {
        var button = new WpfButton
        {
            Background = new SolidColorBrush(MediaColor.FromArgb(90, 52, 52, 57)),
            BorderThickness = new Thickness(0),
            Padding = new Thickness(10, 8, 10, 8),
            Margin = new Thickness(0, 0, 0, 6),
            HorizontalContentAlignment = WpfHorizontalAlignment.Stretch,
            Cursor = System.Windows.Input.Cursors.Hand,
            ToolTip = "X에서 원문 열기"
        };
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(42) });
        grid.ColumnDefinitions.Add(new ColumnDefinition());
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var score = new TextBlock
        {
            Text = evidence.Score.ToString(),
            Foreground = MediaBrushes.White,
            FontWeight = FontWeights.Bold,
            VerticalAlignment = VerticalAlignment.Center
        };
        var reasons = new TextBlock
        {
            Text = string.Join(" · ", evidence.ReasonCodes.Take(2).Select(SignalText.Reason)),
            Foreground = new SolidColorBrush(MediaColor.FromRgb(205, 206, 212)),
            FontSize = 11.5,
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center
        };
        var arrow = new TextBlock
        {
            Text = "↗",
            Foreground = new SolidColorBrush(MediaColor.FromRgb(159, 160, 168)),
            VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(reasons, 1);
        Grid.SetColumn(arrow, 2);
        grid.Children.Add(score);
        grid.Children.Add(reasons);
        grid.Children.Add(arrow);
        button.Content = grid;
        button.Click += (_, _) => Process.Start(new ProcessStartInfo(evidence.Url.ToString()) { UseShellExecute = true });
        RowsPanel.Children.Add(button);
    }

    private void CloseButton_OnClick(object sender, RoutedEventArgs e) => Hide();
}
