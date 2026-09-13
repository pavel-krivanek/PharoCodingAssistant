param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$BaseImage,
    [Parameter(Mandatory=$true)][string]$Repository,
    [Parameter(Mandatory=$true)][string]$EvaluatorRoot,
    [Parameter(Mandatory=$true)][string]$OutputRoot,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$controlRoot = Join-Path $EvaluatorRoot 'controls'
$runner = Join-Path $Repository 'scripts\run-benchmark-control.ps1'
if (-not (Test-Path -LiteralPath $controlRoot -PathType Container)) {
    throw "Missing private control directory: $controlRoot"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$count = 0
$failures = 0
Get-ChildItem -LiteralPath $controlRoot -Filter '*.json' -File | Sort-Object Name | ForEach-Object {
    $count++
    $name = $_.BaseName
    $work = Join-Path $OutputRoot $name
    $image = Join-Path $work 'control.image'
    $result = Join-Path $work 'result.json'
    $stdout = Join-Path $work 'stdout.log'
    $stderr = Join-Path $work 'stderr.log'
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    Copy-Item -LiteralPath $BaseImage -Destination $image -Force
    $baseChanges = [System.IO.Path]::ChangeExtension($BaseImage, '.changes')
    $controlChanges = Join-Path $work 'control.changes'
    if (Test-Path -LiteralPath $baseChanges -PathType Leaf) {
        Copy-Item -LiteralPath $baseChanges -Destination $controlChanges -Force
    }

    & $runner -Vm $Vm -Image $image -Repository $Repository -EvaluatorRoot $EvaluatorRoot `
        -Control $_.FullName -Output $result -TimeoutSeconds $TimeoutSeconds -Stdout $stdout -Stderr $stderr
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        Write-Host "PASS $name"
    } else {
        Write-Host "FAIL $name (exit $code)"
        $failures++
    }
    Remove-Item -LiteralPath $image -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $controlChanges -Force -ErrorAction SilentlyContinue
}

$summary = "controls=$count passed=$($count - $failures) failed=$failures"
$summary | Tee-Object -FilePath (Join-Path $OutputRoot 'summary.txt')
[ordered]@{ controls = $count; passed = ($count - $failures); failed = $failures } | ConvertTo-Json -Compress | Set-Content -Path (Join-Path $OutputRoot 'summary.json')
if ($failures -ne 0) { exit 1 }
exit 0
