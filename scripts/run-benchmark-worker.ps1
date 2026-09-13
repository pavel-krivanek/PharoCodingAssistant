param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$Image,
    [Parameter(Mandatory=$true)][string]$Repository,
    [Parameter(Mandatory=$true)][string]$Task,
    [Parameter(Mandatory=$true)][string]$Output,
    [Parameter(Mandatory=$true)][string]$SkillMode,
    [Parameter(Mandatory=$true)][string]$Workspace,
    [string]$ProfileRoot = '',
    [Parameter(Mandatory=$true)][int]$TimeoutSeconds,
    [Parameter(Mandatory=$true)][string]$Stdout,
    [Parameter(Mandatory=$true)][string]$Stderr
)

$ErrorActionPreference = 'Stop'
$workerScript = Join-Path $Repository 'scripts\run-benchmark-worker.st'

$stdoutParent = Split-Path -Parent $Stdout
$stderrParent = Split-Path -Parent $Stderr
if ($stdoutParent) { New-Item -ItemType Directory -Force -Path $stdoutParent | Out-Null }
if ($stderrParent) { New-Item -ItemType Directory -Force -Path $stderrParent | Out-Null }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Vm
$psi.Arguments = "--headless `"$Image`" st `"$workerScript`""
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['PCA_BENCH_REPOSITORY'] = $Repository
$psi.EnvironmentVariables['PCA_BENCH_TASK'] = $Task
$psi.EnvironmentVariables['PCA_BENCH_OUTPUT'] = $Output
$psi.EnvironmentVariables['PCA_BENCH_SKILL_MODE'] = $SkillMode
$psi.EnvironmentVariables['PCA_BENCH_WORKSPACE'] = $Workspace
if (-not [string]::IsNullOrWhiteSpace($ProfileRoot)) {
    $psi.EnvironmentVariables['PCA_BENCH_PROFILE_ROOT'] = $ProfileRoot
} else {
    $psi.EnvironmentVariables.Remove('PCA_BENCH_PROFILE_ROOT')
}
# Do not leak supervisor-only evaluator locations into the agent process.
@('PCA_BENCH_EVALUATORS','PCA_BENCH_EVALUATOR_TIMEOUT','PCA_BENCH_EVALUATION_PLAN','PCA_BENCH_EVALUATION_OUTPUT','PCA_BENCH_WORKER_RESULT') | ForEach-Object {
    $psi.EnvironmentVariables.Remove($_)
}

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
