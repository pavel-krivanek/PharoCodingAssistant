param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$Image,
    [Parameter(Mandatory=$true)][string]$Repository,
    [Parameter(Mandatory=$true)][string]$EvaluatorRoot,
    [Parameter(Mandatory=$true)][string]$Control,
    [Parameter(Mandatory=$true)][string]$Output,
    [Parameter(Mandatory=$true)][int]$TimeoutSeconds,
    [Parameter(Mandatory=$true)][string]$Stdout,
    [Parameter(Mandatory=$true)][string]$Stderr
)
$ErrorActionPreference = 'Stop'
$script = Join-Path $Repository 'scripts\run-benchmark-control.st'
$stdoutParent = Split-Path -Parent $Stdout
$stderrParent = Split-Path -Parent $Stderr
$outputParent = Split-Path -Parent $Output
if ($stdoutParent) { New-Item -ItemType Directory -Force -Path $stdoutParent | Out-Null }
if ($stderrParent) { New-Item -ItemType Directory -Force -Path $stderrParent | Out-Null }
if ($outputParent) { New-Item -ItemType Directory -Force -Path $outputParent | Out-Null }
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Vm
$psi.Arguments = "--headless `"$Image`" st --quit `"$script`""
$psi.WorkingDirectory = Split-Path -Parent $Vm
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['PCA_BENCH_REPOSITORY'] = $Repository
$psi.EnvironmentVariables['PCA_BENCH_EVALUATORS'] = $EvaluatorRoot
$psi.EnvironmentVariables['PCA_BENCH_CONTROL_FILE'] = $Control
$psi.EnvironmentVariables['PCA_BENCH_CONTROL_OUTPUT'] = $Output
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
if (-not $process.Start()) { exit 125 }
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
$timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
if ($timedOut) { try { $process.Kill() } catch { }; $process.WaitForExit() } else { $process.WaitForExit() }
[System.IO.File]::WriteAllText($Stdout, $stdoutTask.Result)
[System.IO.File]::WriteAllText($Stderr, $stderrTask.Result)
if ($timedOut) { exit 124 }
exit $process.ExitCode
