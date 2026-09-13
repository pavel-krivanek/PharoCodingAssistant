param(
    [Parameter(Mandatory=$true)][string]$Destination,
    [string]$SourceRoot = (Join-Path $HOME '.pharo-ca'),
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$runtime = Join-Path $SourceRoot 'runtime.json'
if (-not (Test-Path $runtime)) { throw "No runtime.json found at $runtime. Configure PCA provider/model first and save the runtime profile." }
if (Test-Path $Destination) {
    $items = @(Get-ChildItem -Force $Destination)
    if ($items.Count -gt 0 -and -not $Force) { throw "Destination is not empty: $Destination. Use -Force to replace its contents." }
    if ($Force) { Remove-Item -Recurse -Force $Destination }
}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
Copy-Item $runtime (Join-Path $Destination 'runtime.json')
$settings = Join-Path $SourceRoot 'settings.json'
if (Test-Path $settings) { Copy-Item $settings (Join-Path $Destination 'settings.json') }
Write-Output (Resolve-Path $Destination).Path
