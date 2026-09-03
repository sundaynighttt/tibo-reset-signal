param([switch] $EnableStartup)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\TiboResetSignal'
$executable = Join-Path $installRoot 'TiboResetSignal.exe'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Tibo Reset Signal.lnk'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$startupWasEnabled = $EnableStartup -or $null -ne (
    Get-ItemProperty -Path $runKey -Name 'TiboResetSignal' -ErrorAction SilentlyContinue
)

Get-Process -Name 'TiboResetSignal' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'TiboResetSignal.exe') -Destination $executable -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'uninstall.ps1') -Destination (Join-Path $installRoot 'uninstall.ps1') -Force

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $executable
$shortcut.WorkingDirectory = $installRoot
$shortcut.Description = 'Tibo reset signal monitor'
$shortcut.Save()

if ($startupWasEnabled) {
    New-ItemProperty -Path $runKey -Name 'TiboResetSignal' -PropertyType String -Value "`"$executable`"" -Force | Out-Null
}

Start-Process $executable
Write-Host "Tibo Reset Signal installed: $installRoot"
