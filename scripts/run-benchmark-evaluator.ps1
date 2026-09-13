param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$Image,
    [Parameter(Mandatory=$true)][string]$Repository,
    [Parameter(Mandatory=$true)][string]$Task,
    [Parameter(Mandatory=$true)][string]$WorkerResult,
    [Parameter(Mandatory=$true)][string]$Plan,
    [Parameter(Mandatory=$true)][string]$Evaluation,
    [Parameter(Mandatory=$true)][int]$TimeoutSeconds,
    [Parameter(Mandatory=$true)][string]$Stdout,
    [Parameter(Mandatory=$true)][string]$Stderr
)

$ErrorActionPreference = 'Stop'
$evaluatorScript = Join-Path $Repository 'scripts\run-benchmark-evaluator.st'

$stdoutParent = Split-Path -Parent $Stdout
$stderrParent = Split-Path -Parent $Stderr
if ($stdoutParent) { New-Item -ItemType Directory -Force -Path $stdoutParent | Out-Null }
if ($stderrParent) { New-Item -ItemType Directory -Force -Path $stderrParent | Out-Null }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Vm
$psi.Arguments = "`"$Image`" st --quit `"$evaluatorScript`""
$psi.WorkingDirectory = Split-Path -Parent $Vm
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['PCA_BENCH_REPOSITORY'] = $Repository
$psi.EnvironmentVariables['PCA_BENCH_TASK'] = $Task
$psi.EnvironmentVariables['PCA_BENCH_WORKER_RESULT'] = $WorkerResult
$psi.EnvironmentVariables['PCA_BENCH_EVALUATION_PLAN'] = $Plan
$psi.EnvironmentVariables['PCA_BENCH_EVALUATION_OUTPUT'] = $Evaluation

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
if (-not $process.Start()) { exit 125 }

$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()

if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
    [System.IO.File]::WriteAllText($Stdout, $stdoutTask.Result)
    [System.IO.File]::WriteAllText($Stderr, $stderrTask.Result)
    exit 124
}

$process.WaitForExit()
[System.IO.File]::WriteAllText($Stdout, $stdoutTask.Result)
[System.IO.File]::WriteAllText($Stderr, $stderrTask.Result)
exit $process.ExitCode
