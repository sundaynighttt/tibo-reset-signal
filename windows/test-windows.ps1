Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$project = Join-Path $PSScriptRoot 'TiboResetSignal.Windows\TiboResetSignal.Windows.csproj'
dotnet build $project -c Release
if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
dotnet run --project $project -c Release --no-build -- --self-test
if ($LASTEXITCODE -ne 0) { throw 'Windows model self-test failed.' }
Write-Output 'Windows build and model tests passed.'
