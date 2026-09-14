param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$BaseImage,
    [Parameter(Mandatory=$true)][string]$ProfileRoot,
    [string]$EvaluationRepository = '',
    [ValidateSet('normal','preloaded','both')][string]$SkillModes = 'normal',
    [string]$Tasks = '',
    [string]$RunsRoot = '',
    [string]$Output = '',
    [int]$TimeoutSeconds = 900,
    [int]$EvaluatorTimeoutSeconds = 120,
    [ValidateRange(0,3)][int]$Verbosity = 1
)
$ErrorActionPreference = 'Stop'
$repository = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ProfileRoot = (Resolve-Path $ProfileRoot).Path
if ([string]::IsNullOrWhiteSpace($RunsRoot)) { $RunsRoot = Join-Path (Join-Path $repository 'benchmark') 'runs' }
$effectiveSkillModes = if ($SkillModes -eq 'both') { 'normal,preloaded' } else { $SkillModes }
$env:PCA_BENCH_REPOSITORY = $repository
$env:PCA_BENCH_VM = $Vm
$env:PCA_BENCH_BASE_IMAGE = $BaseImage
$env:PCA_BENCH_PROFILE_ROOT = $ProfileRoot
$env:PCA_BENCH_RUNS = $RunsRoot
$env:PCA_BENCH_SKILL_MODES = $effectiveSkillModes
$env:PCA_BENCH_TASKS = $Tasks
$env:PCA_BENCH_TIMEOUT = [string]$TimeoutSeconds
$env:PCA_BENCH_EVALUATOR_TIMEOUT = [string]$EvaluatorTimeoutSeconds
$env:PCA_BENCH_VERBOSITY = [string]$Verbosity
if (-not [string]::IsNullOrWhiteSpace($EvaluationRepository)) { $env:PCA_BENCH_EVALUATION_REPOSITORY = (Resolve-Path $EvaluationRepository).Path } else { Remove-Item Env:PCA_BENCH_EVALUATION_REPOSITORY -ErrorAction SilentlyContinue }
if (-not [string]::IsNullOrWhiteSpace($Output)) { $env:PCA_BENCH_SUITE_OUTPUT = $Output } else { Remove-Item Env:PCA_BENCH_SUITE_OUTPUT -ErrorAction SilentlyContinue }
$script = Join-Path $repository 'scripts\run-benchmark-suite.st'
$vmDirectory = Split-Path -Parent $Vm
Push-Location $vmDirectory
try {
    & $Vm --headless $BaseImage st --quit $script
    $exitCode = $LASTEXITCODE
} finally { Pop-Location }
exit $exitCode
