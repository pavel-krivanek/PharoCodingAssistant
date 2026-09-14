param(
    [Parameter(Mandatory=$true)][string]$Image,
    [string]$Pharo = "pharo.exe",
    [string]$Task = "basic-001-expression",
    [string]$Output = "benchmark-results/result.json",
    [ValidateSet("normal", "preloaded")][string]$SkillMode = "normal",
    [ValidateRange(0,3)][int]$Verbosity = 1,
    [string]$Workspace = ""
)
$env:PCA_BENCH_TASK = $Task
$env:PCA_BENCH_OUTPUT = $Output
$env:PCA_BENCH_SKILL_MODE = $SkillMode
$env:PCA_BENCH_VERBOSITY = [string]$Verbosity
if ($Workspace) { $env:PCA_BENCH_WORKSPACE = $Workspace }
& $Pharo --headless $Image st --quit scripts/run-benchmark.st
exit $LASTEXITCODE
