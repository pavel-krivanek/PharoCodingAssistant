param(
    [Parameter(Mandatory=$true)][string]$Vm,
    [Parameter(Mandatory=$true)][string]$BaseImage,
    [string]$Task = 'basic-001-expression',
    [ValidateSet('normal','preloaded')][string]$SkillMode = 'normal',
    [string]$RunsRoot = '',
    [string]$EvaluationRepository = '',
    [string]$ProfileRoot = '',
    [ValidateRange(0,3)][int]$Verbosity = 1
)
$ErrorActionPreference = 'Stop'
$repository = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($RunsRoot)) { $RunsRoot = Join-Path (Join-Path $repository 'benchmark') 'runs' }
$env:PCA_BENCH_REPOSITORY = $repository
$env:PCA_BENCH_VM = $Vm
$env:PCA_BENCH_BASE_IMAGE = $BaseImage
$env:PCA_BENCH_RUNS = $RunsRoot
$env:PCA_BENCH_TASK = $Task
$env:PCA_BENCH_SKILL_MODE = $SkillMode
$env:PCA_BENCH_VERBOSITY = [string]$Verbosity
if (-not [string]::IsNullOrWhiteSpace($ProfileRoot)) { $env:PCA_BENCH_PROFILE_ROOT = $ProfileRoot } else { Remove-Item Env:PCA_BENCH_PROFILE_ROOT -ErrorAction SilentlyContinue }
if (-not [string]::IsNullOrWhiteSpace($EvaluationRepository)) { $env:PCA_BENCH_EVALUATION_REPOSITORY = $EvaluationRepository } else { Remove-Item Env:PCA_BENCH_EVALUATION_REPOSITORY -ErrorAction SilentlyContinue }
$script = Join-Path $repository 'scripts\run-benchmark-supervisor.st'
$vmDirectory = Split-Path -Parent $Vm
Push-Location $vmDirectory
try {
    & $Vm --headless $BaseImage st --quit $script
    $exitCode = $LASTEXITCODE
} finally { Pop-Location }
exit $exitCode
