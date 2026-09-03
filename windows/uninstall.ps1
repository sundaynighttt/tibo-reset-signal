param([switch] $RemoveSettings)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\TiboResetSignal'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Tibo Reset Signal.lnk'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

Get-Process -Name 'TiboResetSignal' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
Remove-ItemProperty -Path $runKey -Name 'TiboResetSignal' -ErrorAction SilentlyContinue
Remove-Item -Path $shortcutPath -Force -ErrorAction SilentlyContinue
if (Test-Path $installRoot) { Remove-Item -Path $installRoot -Recurse -Force }

if ($RemoveSettings) {
    Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'TiboResetSignal') -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Tibo Reset Signal uninstalled.'
