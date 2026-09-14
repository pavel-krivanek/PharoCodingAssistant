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
$verbosity = if ([string]::IsNullOrWhiteSpace($env:PCA_BENCH_VERBOSITY)) { 0 } else { [int]$env:PCA_BENCH_VERBOSITY }
$liveStdout = $verbosity -ge 2

$stdoutParent = Split-Path -Parent $Stdout
$stderrParent = Split-Path -Parent $Stderr
if ($stdoutParent) { New-Item -ItemType Directory -Force -Path $stdoutParent | Out-Null }
if ($stderrParent) { New-Item -ItemType Directory -Force -Path $stderrParent | Out-Null }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Vm
# All worker VMs are explicitly headless. Never fall back to a UI-capable invocation.
$psi.Arguments = "--headless `"$Image`" st --quit `"$workerScript`""
$psi.WorkingDirectory = Split-Path -Parent $Vm
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = -not $liveStdout
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['PCA_BENCH_REPOSITORY'] = $Repository
$psi.EnvironmentVariables['PCA_BENCH_TASK'] = $Task
$psi.EnvironmentVariables['PCA_BENCH_OUTPUT'] = $Output
$psi.EnvironmentVariables['PCA_BENCH_SKILL_MODE'] = $SkillMode
$psi.EnvironmentVariables['PCA_BENCH_WORKSPACE'] = $Workspace
if ($liveStdout) { $psi.EnvironmentVariables['PCA_BENCH_STDOUT_LOG'] = $Stdout } else { $psi.EnvironmentVariables.Remove('PCA_BENCH_STDOUT_LOG') }
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
$stdoutTask = if ($psi.RedirectStandardOutput) { $process.StandardOutput.ReadToEndAsync() } else { $null }
$stderrTask = $process.StandardError.ReadToEndAsync()

$timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
if ($timedOut) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
} else {
    $process.WaitForExit()
}

if ($psi.RedirectStandardOutput) {
    [System.IO.File]::WriteAllText($Stdout, $stdoutTask.Result)
} elseif (-not (Test-Path -LiteralPath $Stdout)) {
    [System.IO.File]::WriteAllText($Stdout, '')
}
[System.IO.File]::WriteAllText($Stderr, $stderrTask.Result)
if ($timedOut) { exit 124 }
exit $process.ExitCode
