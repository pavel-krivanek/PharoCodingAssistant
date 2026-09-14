param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$BaseImage,
    [string]$Task = 'basic-001-expression',
    [ValidateSet('normal','preloaded')][string]$SkillMode = 'normal',
    [string]$RunsRoot = '',
    [string]$EvaluationRepository = '',
    [string]$ProfileRoot = '',
    [ValidateRange(0,3)][int]$Verbosity = 1,
    [ValidateSet('readwrite','readonly','writeonly','off')][string]$CommonIssuesMode = 'readwrite',
    [string]$CommonIssuesPath = ''
)
$ErrorActionPreference = 'Stop'
function Stop-ProcessTree {
    param([Parameter(Mandatory=$true)][int]$ProcessId)
    if ($ProcessId -le 0) { return }
    try {
        if ($null -eq (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) { return }
        $taskkill = Join-Path $env:SystemRoot 'System32\taskkill.exe'
        if (-not (Test-Path -LiteralPath $taskkill -PathType Leaf)) { $taskkill = 'taskkill.exe' }
        $killInfo = New-Object System.Diagnostics.ProcessStartInfo
        $killInfo.FileName = $taskkill
        $killInfo.Arguments = "/PID $ProcessId /T /F"
        $killInfo.UseShellExecute = $false
        $killInfo.CreateNoWindow = $true
        $killInfo.RedirectStandardOutput = $true
        $killInfo.RedirectStandardError = $true
        $killer = New-Object System.Diagnostics.Process
        $killer.StartInfo = $killInfo
        if ($killer.Start()) {
            $null = $killer.WaitForExit(10000)
            if (-not $killer.HasExited) { try { $killer.Kill() } catch { } }
        }
    } catch { }
}

function Invoke-HeadlessPharo {
    param(
        [Parameter(Mandatory=$true)][string]$Vm,
        [Parameter(Mandatory=$true)][string]$Image,
        [Parameter(Mandatory=$true)][string]$Script
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Vm
    $psi.Arguments = "--headless `"$Image`" st --quit `"$Script`""
    $psi.WorkingDirectory = Split-Path -Parent $Vm
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    if (-not $process.Start()) { return 125 }
    try {
        while (-not $process.WaitForExit(250)) { }
        return $process.ExitCode
    } finally {
        # This finally block runs on Ctrl+C / pipeline cancellation.
        try { if (-not $process.HasExited) { Stop-ProcessTree -ProcessId $process.Id } } catch { }
    }
}

$repository = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($RunsRoot)) { $RunsRoot = Join-Path (Join-Path $repository 'benchmark') 'runs' }
$env:PCA_BENCH_REPOSITORY = $repository
$env:PCA_BENCH_VM = $Vm
$env:PCA_BENCH_BASE_IMAGE = $BaseImage
$env:PCA_BENCH_RUNS = $RunsRoot
$env:PCA_BENCH_TASK = $Task
$env:PCA_BENCH_SKILL_MODE = $SkillMode
$env:PCA_BENCH_VERBOSITY = [string]$Verbosity
if ([string]::IsNullOrWhiteSpace($CommonIssuesPath)) { $CommonIssuesPath = Join-Path $HOME '.pharo-ca\common-issues.md' }
$env:PCA_BENCH_COMMON_ISSUES_PATH = [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($CommonIssuesPath))
$env:PCA_BENCH_COMMON_ISSUES_READ = $(if ($CommonIssuesMode -in @('readwrite','readonly')) { '1' } else { '0' })
$env:PCA_BENCH_COMMON_ISSUES_WRITE = $(if ($CommonIssuesMode -in @('readwrite','writeonly')) { '1' } else { '0' })
if (-not [string]::IsNullOrWhiteSpace($ProfileRoot)) { $env:PCA_BENCH_PROFILE_ROOT = $ProfileRoot } else { Remove-Item Env:PCA_BENCH_PROFILE_ROOT -ErrorAction SilentlyContinue }
if (-not [string]::IsNullOrWhiteSpace($EvaluationRepository)) { $env:PCA_BENCH_EVALUATION_REPOSITORY = $EvaluationRepository } else { Remove-Item Env:PCA_BENCH_EVALUATION_REPOSITORY -ErrorAction SilentlyContinue }
$script = Join-Path $repository 'scripts\run-benchmark-supervisor.st'
$exitCode = Invoke-HeadlessPharo -Vm $Vm -Image $BaseImage -Script $script
exit $exitCode
