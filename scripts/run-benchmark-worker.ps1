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
$psi.Arguments = "--headless `"$Image`" st --quit `"$workerScript`""
$psi.WorkingDirectory = Split-Path -Parent $Vm
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
# Always capture the VM streams. At verbosity >= 2 we tee captured output to
# this PowerShell process's stdout/stderr, which are inherited by the suite.
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['PCA_BENCH_REPOSITORY'] = $Repository
$psi.EnvironmentVariables['PCA_BENCH_TASK'] = $Task
$psi.EnvironmentVariables['PCA_BENCH_OUTPUT'] = $Output
$psi.EnvironmentVariables['PCA_BENCH_SKILL_MODE'] = $SkillMode
$psi.EnvironmentVariables['PCA_BENCH_WORKSPACE'] = $Workspace
# The wrapper owns worker.stdout.log. The Pharo reporter writes only to Stdio
# stdout, avoiding two writers opening the same log file concurrently.
$psi.EnvironmentVariables.Remove('PCA_BENCH_STDOUT_LOG')
if (-not [string]::IsNullOrWhiteSpace($ProfileRoot)) {
    $psi.EnvironmentVariables['PCA_BENCH_PROFILE_ROOT'] = $ProfileRoot
} else {
    $psi.EnvironmentVariables.Remove('PCA_BENCH_PROFILE_ROOT')
}
# Do not leak supervisor-only evaluator locations into the agent process.
@('PCA_BENCH_EVALUATION_REPOSITORY','PCA_BENCH_EVALUATORS','PCA_BENCH_EVALUATOR_TIMEOUT','PCA_BENCH_EVALUATION_PLAN','PCA_BENCH_EVALUATION_OUTPUT','PCA_BENCH_WORKER_RESULT') | ForEach-Object {
    $psi.EnvironmentVariables.Remove($_)
}

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
if (-not $process.Start()) { exit 125 }

$stdoutWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $Stdout, $false
$stderrWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $Stderr, $false
$stdoutWriter.AutoFlush = $true
$stderrWriter.AutoFlush = $true

$stdoutBuffer = New-Object 'char[]' 4096
$stderrBuffer = New-Object 'char[]' 4096
$stdoutTask = $process.StandardOutput.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
$stderrTask = $process.StandardError.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
$stdoutDone = $false
$stderrDone = $false
$timedOut = $false
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

try {
    while (-not ($process.HasExited -and $stdoutDone -and $stderrDone)) {
        $didWork = $false

        if (-not $stdoutDone -and $stdoutTask.IsCompleted) {
            $count = $stdoutTask.Result
            if ($count -le 0) {
                $stdoutDone = $true
            } else {
                $text = -join $stdoutBuffer[0..($count - 1)]
                $stdoutWriter.Write($text)
                $stdoutWriter.Flush()
                if ($liveStdout) { [Console]::Out.Write($text) }
                $stdoutBuffer = New-Object 'char[]' 4096
                $stdoutTask = $process.StandardOutput.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
            }
            $didWork = $true
        }

        if (-not $stderrDone -and $stderrTask.IsCompleted) {
            $count = $stderrTask.Result
            if ($count -le 0) {
                $stderrDone = $true
            } else {
                $text = -join $stderrBuffer[0..($count - 1)]
                $stderrWriter.Write($text)
                $stderrWriter.Flush()
                if ($liveStdout) { [Console]::Error.Write($text) }
                $stderrBuffer = New-Object 'char[]' 4096
                $stderrTask = $process.StandardError.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
            }
            $didWork = $true
        }

        if (-not $process.HasExited -and -not $timedOut -and [DateTime]::UtcNow -ge $deadline) {
            $timedOut = $true
            try { $process.Kill() } catch { }
        }

        if (-not $didWork) { Start-Sleep -Milliseconds 10 }
    }
    $process.WaitForExit()
} finally {
    $stdoutWriter.Dispose()
    $stderrWriter.Dispose()
}

if ($timedOut) { exit 124 }
exit $process.ExitCode
