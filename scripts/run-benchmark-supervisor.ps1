param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$BaseImage,
    [string]$Task = 'basic-001-expression',
    [ValidateSet('normal','preloaded')][string]$SkillMode = 'normal',
    [string]$RunsRoot = '',
    [string]$EvaluatorPlanRoot = '',
    [string]$ProfileRoot = ''
)

$ErrorActionPreference = 'Stop'
$repository = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($RunsRoot)) {
    $RunsRoot = Join-Path (Join-Path $repository 'benchmark') 'runs'
}

$env:PCA_BENCH_REPOSITORY = $repository
$env:PCA_BENCH_VM = $Vm
$env:PCA_BENCH_BASE_IMAGE = $BaseImage
$env:PCA_BENCH_RUNS = $RunsRoot
$env:PCA_BENCH_TASK = $Task
$env:PCA_BENCH_SKILL_MODE = $SkillMode
if (-not [string]::IsNullOrWhiteSpace($ProfileRoot)) { $env:PCA_BENCH_PROFILE_ROOT = $ProfileRoot } else { Remove-Item Env:PCA_BENCH_PROFILE_ROOT -ErrorAction SilentlyContinue }
if (-not [string]::IsNullOrWhiteSpace($EvaluatorPlanRoot)) {
    $env:PCA_BENCH_EVALUATORS = $EvaluatorPlanRoot
} else {
    Remove-Item Env:PCA_BENCH_EVALUATORS -ErrorAction SilentlyContinue
}

& $Vm --headless $BaseImage st (Join-Path $repository 'scripts\run-benchmark-supervisor.st')
exit $LASTEXITCODE
