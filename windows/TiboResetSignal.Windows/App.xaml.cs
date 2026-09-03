using System.Threading;
using System.Windows;

namespace TiboResetSignal.WinApp;

public partial class App : System.Windows.Application
{
    private Mutex? _singleInstanceMutex;
    private SignalController? _controller;

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        if (e.Args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
        {
            try
            {
                SignalModelSelfTest.Run();
                Shutdown(0);
            }
            catch
            {
                Shutdown(1);
            }
            return;
        }

        _singleInstanceMutex = new Mutex(true, @"Local\TiboResetSignal.Windows", out var createdNew);
        if (!createdNew)
        {
            Shutdown(0);
            return;
        }

        try
        {
            _controller = new SignalController();
            await _controller.StartAsync();
        }
        catch (Exception exception)
        {
            AppLog.Write(exception);
            System.Windows.MessageBox.Show(
                exception.Message,
                "Tibo Reset Signal",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
            Shutdown(1);
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _controller?.Dispose();
        _singleInstanceMutex?.Dispose();
        base.OnExit(e);
    }
}
