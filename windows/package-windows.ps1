param(
    [string] $Version = '0.1.0',
    [string] $Runtime = 'win-x64'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$distRoot = Join-Path $repoRoot 'dist'
$artifactName = "TiboResetSignal-Windows-$Version"
$stageRoot = Join-Path $distRoot $artifactName
$zipPath = Join-Path $distRoot "$artifactName.zip"
$publishRoot = Join-Path $distRoot "windows-publish-$Runtime"
$project = Join-Path $PSScriptRoot 'TiboResetSignal.Windows\TiboResetSignal.Windows.csproj'

if (Test-Path $stageRoot) { Remove-Item -Path $stageRoot -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
if (Test-Path $publishRoot) { Remove-Item -Path $publishRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

dotnet publish $project -c Release -r $Runtime --self-contained true `
    -p:Version=$Version -p:PublishSingleFile=true -p:PublishTrimmed=false `
    -o $publishRoot
if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed.' }

@('install.ps1', 'uninstall.ps1', 'INSTALL.txt') | ForEach-Object {
    Copy-Item -Path (Join-Path $PSScriptRoot $_) -Destination $stageRoot
}
Copy-Item -Path (Join-Path $publishRoot 'TiboResetSignal.exe') -Destination $stageRoot
Copy-Item -Path (Join-Path $repoRoot 'LICENSE') -Destination (Join-Path $stageRoot 'LICENSE.txt')

Compress-Archive -Path $stageRoot -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -Path $publishRoot -Recurse -Force
Write-Output $zipPath
