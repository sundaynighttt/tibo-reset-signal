using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using DrawingColor = System.Drawing.Color;
using DrawingFont = System.Drawing.Font;
using DrawingIcon = System.Drawing.Icon;
using Forms = System.Windows.Forms;

namespace TiboResetSignal.WinApp;

public sealed class SignalController : IDisposable
{
    private readonly AppSettings _settings = SettingsStore.Load();
    private readonly SignalClient _client = new();
    private readonly SemaphoreSlim _refreshGate = new(1, 1);
    private readonly TaskbarLabelWindow _taskbarLabel = new();
    private readonly FloatingPillWindow _floatingPill = new();
    private readonly DetailsWindow _details = new();
    private readonly DispatcherTimer _refreshTimer;
    private readonly DispatcherTimer _clockTimer;
    private readonly Forms.NotifyIcon _trayIcon;
    private readonly Forms.ContextMenuStrip _trayMenu;
    private DrawingIcon? _currentTrayIcon;
    private SignalPayload? _payload = SignalCache.Load();
    private string? _lastError;
    private bool _disposed;

    public SignalController()
    {
        _taskbarLabel.ToggleDetailsRequested += (_, _) => ToggleDetails(_taskbarLabel.AnchorBounds);
        _floatingPill.ToggleDetailsRequested += (_, _) => ToggleDetails(_floatingPill.AnchorBounds);
        _floatingPill.PositionCommitted += (_, args) =>
        {
            _settings.FloatingLeftPx = args.Left;
            _settings.FloatingTopPx = args.Top;
            SettingsStore.Save(_settings);
        };
        _taskbarLabel.ContextMenu = CreateWpfContextMenu();
        _floatingPill.ContextMenu = CreateWpfContextMenu();
        _details.ContextMenu = CreateWpfContextMenu();

        _trayMenu = new Forms.ContextMenuStrip();
        _trayMenu.Opening += RebuildTrayMenu;
        _currentTrayIcon = CreateTrayIcon(SignalLevel.Stale, null);
        _trayIcon = new Forms.NotifyIcon
        {
            Visible = true,
            Text = "Tibo Reset Signal · 확인 중",
            Icon = _currentTrayIcon,
            ContextMenuStrip = _trayMenu
        };
        _trayIcon.MouseClick += (_, args) =>
        {
            if (args.Button != Forms.MouseButtons.Left) return;
            var cursor = Forms.Control.MousePosition;
            ToggleDetails(new NativeMethods.NativeRect(cursor.X, cursor.Y, cursor.X + 1, cursor.Y + 1));
        };

        _refreshTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(10) };
        _refreshTimer.Tick += async (_, _) => await RefreshAsync();
        _clockTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(1) };
        _clockTimer.Tick += (_, _) => UpdateDisplays();
    }

    public async Task StartAsync()
    {
        ApplyDisplayMode();
        UpdateDisplays();
        _refreshTimer.Start();
        _clockTimer.Start();
        await RefreshAsync();
    }

    private async Task RefreshAsync()
    {
        if (!await _refreshGate.WaitAsync(0)) return;
        var previousLevel = _payload?.EffectiveLevel() ?? SignalLevel.Stale;
        try
        {
            _lastError = null;
            var latest = await _client.FetchAsync();
            _payload = latest;
            SignalCache.Save(latest);
            var newLevel = latest.EffectiveLevel();
            if (previousLevel != SignalLevel.Green && newLevel == SignalLevel.Green)
            {
                _trayIcon.ShowBalloonTip(
                    8000,
                    "Tibo Reset Signal",
                    $"강한 리셋 신호가 감지되었습니다 · {latest.Signal.Score}점",
                    Forms.ToolTipIcon.Info);
            }
        }
        catch (Exception exception)
        {
            _lastError = exception.Message;
            AppLog.Write(exception);
        }
        finally
        {
            _refreshGate.Release();
            UpdateDisplays();
        }
    }

    private void ApplyDisplayMode()
    {
        _details.Hide();
        if (_settings.DisplayMode == DisplayMode.TaskbarLabel)
        {
            _floatingPill.HidePill();
            _taskbarLabel.ShowLabel();
        }
        else
        {
            _taskbarLabel.HideLabel();
            _floatingPill.ShowPill(_settings.FloatingLeftPx, _settings.FloatingTopPx);
        }
    }

    private void SwitchMode(DisplayMode mode)
    {
        if (_settings.DisplayMode == mode) return;
        _settings.DisplayMode = mode;
        SettingsStore.Save(_settings);
        ApplyDisplayMode();
        UpdateDisplays();
    }

    private void ToggleDetails(NativeMethods.NativeRect anchor)
    {
        if (_details.IsVisible)
        {
            _details.Hide();
            return;
        }
        _details.UpdateSignal(_payload, _lastError);
        _details.ShowNear(anchor);
    }

    private void UpdateDisplays()
    {
        var level = _payload?.EffectiveLevel() ?? SignalLevel.Stale;
        var score = level == SignalLevel.Stale ? null : _payload?.Signal.Score;
        var label = $"Reset {SignalText.LevelName(level)} · {(score?.ToString() ?? "–")}";
        var tooltip = $"{SignalText.KoreanLevelName(level)}";
        if (_payload is not null) tooltip += $" · {SignalText.UpdateText(_payload.Source.LastSuccessfulCheckAt)}";
        if (_lastError is not null) tooltip += " · 새로고침 실패";

        _taskbarLabel.UpdateSignal(label, level, tooltip);
        _floatingPill.UpdateSignal(label, level, tooltip);
        _details.UpdateSignal(_payload, _lastError);
        UpdateTrayIcon(level, score, label);
    }

    private void UpdateTrayIcon(SignalLevel level, int? score, string tooltip)
    {
        var newIcon = CreateTrayIcon(level, score);
        var oldIcon = _currentTrayIcon;
        _trayIcon.Icon = newIcon;
        _currentTrayIcon = newIcon;
        _trayIcon.Text = tooltip.Length <= 63 ? tooltip : tooltip[..63];
        oldIcon?.Dispose();
    }

    private ContextMenu CreateWpfContextMenu()
    {
        var menu = new ContextMenu();
        menu.Opened += (_, _) =>
        {
            menu.Items.Clear();
            var refresh = new MenuItem { Header = "지금 새로고침" };
            refresh.Click += async (_, _) => await RefreshAsync();
            menu.Items.Add(refresh);
            menu.Items.Add(new Separator());
            AddModeItems(menu.Items);
            menu.Items.Add(new Separator());
            var profile = new MenuItem { Header = "@thsottiaux 프로필 열기" };
            profile.Click += (_, _) => OpenUrl("https://x.com/thsottiaux");
            menu.Items.Add(profile);
            var startup = new MenuItem
            {
                Header = "로그인 시 자동 실행",
                IsCheckable = true,
                IsChecked = StartupManager.IsEnabled
            };
            startup.Click += (_, _) => StartupManager.IsEnabled = !StartupManager.IsEnabled;
            menu.Items.Add(startup);
            var exit = new MenuItem { Header = "종료" };
            exit.Click += (_, _) => System.Windows.Application.Current.Shutdown();
            menu.Items.Add(exit);
        };
        return menu;
    }

    private void AddModeItems(ItemCollection items)
    {
        var taskbar = new MenuItem
        {
            Header = "작업표시줄 라벨",
            IsCheckable = true,
            IsChecked = _settings.DisplayMode == DisplayMode.TaskbarLabel
        };
        taskbar.Click += (_, _) => SwitchMode(DisplayMode.TaskbarLabel);
        items.Add(taskbar);
        var floating = new MenuItem
        {
            Header = "우상단 미니 위젯",
            IsCheckable = true,
            IsChecked = _settings.DisplayMode == DisplayMode.FloatingPill
        };
        floating.Click += (_, _) => SwitchMode(DisplayMode.FloatingPill);
        items.Add(floating);
    }

    private void RebuildTrayMenu(object? sender, CancelEventArgs e)
    {
        _trayMenu.Items.Clear();
        var refresh = new Forms.ToolStripMenuItem("지금 새로고침");
        refresh.Click += async (_, _) => await RefreshAsync();
        _trayMenu.Items.Add(refresh);
        _trayMenu.Items.Add(new Forms.ToolStripSeparator());
        var taskbar = new Forms.ToolStripMenuItem("작업표시줄 라벨")
        {
            Checked = _settings.DisplayMode == DisplayMode.TaskbarLabel
        };
        taskbar.Click += (_, _) => SwitchMode(DisplayMode.TaskbarLabel);
        _trayMenu.Items.Add(taskbar);
        var floating = new Forms.ToolStripMenuItem("우상단 미니 위젯")
        {
            Checked = _settings.DisplayMode == DisplayMode.FloatingPill
        };
        floating.Click += (_, _) => SwitchMode(DisplayMode.FloatingPill);
        _trayMenu.Items.Add(floating);
        _trayMenu.Items.Add(new Forms.ToolStripSeparator());
        var profile = new Forms.ToolStripMenuItem("@thsottiaux 프로필 열기");
        profile.Click += (_, _) => OpenUrl("https://x.com/thsottiaux");
        _trayMenu.Items.Add(profile);
        var startup = new Forms.ToolStripMenuItem("로그인 시 자동 실행")
        {
            Checked = StartupManager.IsEnabled
        };
        startup.Click += (_, _) => StartupManager.IsEnabled = !StartupManager.IsEnabled;
        _trayMenu.Items.Add(startup);
        var exit = new Forms.ToolStripMenuItem("종료");
        exit.Click += (_, _) => System.Windows.Application.Current.Shutdown();
        _trayMenu.Items.Add(exit);
    }

    private static void OpenUrl(string url) => Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });

    private static DrawingIcon CreateTrayIcon(SignalLevel level, int? score)
    {
        using var bitmap = new Bitmap(32, 32);
        using var graphics = Graphics.FromImage(bitmap);
        graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        graphics.Clear(DrawingColor.Transparent);
        var mediaColor = SignalColors.For(level);
        using var background = new SolidBrush(DrawingColor.FromArgb(mediaColor.R, mediaColor.G, mediaColor.B));
        graphics.FillEllipse(background, 1, 1, 30, 30);
        var text = score?.ToString() ?? "?";
        using var font = new DrawingFont("Segoe UI", 12f, FontStyle.Bold, GraphicsUnit.Pixel);
        using var format = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        graphics.DrawString(text, font, Brushes.White, new RectangleF(0, 0, 32, 31), format);
        var handle = bitmap.GetHicon();
        try { return (DrawingIcon)DrawingIcon.FromHandle(handle).Clone(); }
        finally { DestroyIcon(handle); }
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _refreshTimer.Stop();
        _clockTimer.Stop();
        _trayIcon.Visible = false;
        _trayIcon.Dispose();
        _currentTrayIcon?.Dispose();
        _trayMenu.Dispose();
        _taskbarLabel.Close();
        _floatingPill.Close();
        _details.Close();
        _refreshGate.Dispose();
    }

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyIcon(IntPtr icon);
}
