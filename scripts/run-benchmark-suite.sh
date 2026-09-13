#!/usr/bin/env sh
set -eu
if [ "$#" -lt 3 ] || [ "$#" -gt 8 ]; then
    echo "usage: $0 VM BASE_IMAGE PROFILE_ROOT [EVALUATOR_PLAN_ROOT] [SKILL_MODES] [TASKS] [RUNS_ROOT] [OUTPUT]" >&2
    exit 2
fi
VM=$1
BASE_IMAGE=$2
PROFILE_ROOT=$3
EVALUATOR_PLAN_ROOT=${4:-}
SKILL_MODES=${5:-normal}
TASKS=${6:-}
REPOSITORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RUNS_ROOT=${7:-"$REPOSITORY/benchmark/runs"}
OUTPUT=${8:-}
[ "$SKILL_MODES" = both ] && SKILL_MODES=normal,preloaded
export PCA_BENCH_REPOSITORY="$REPOSITORY" PCA_BENCH_VM="$VM" PCA_BENCH_BASE_IMAGE="$BASE_IMAGE" PCA_BENCH_PROFILE_ROOT="$PROFILE_ROOT" PCA_BENCH_RUNS="$RUNS_ROOT" PCA_BENCH_SKILL_MODES="$SKILL_MODES" PCA_BENCH_TASKS="$TASKS"
if [ -n "$EVALUATOR_PLAN_ROOT" ]; then export PCA_BENCH_EVALUATORS="$EVALUATOR_PLAN_ROOT"; else unset PCA_BENCH_EVALUATORS 2>/dev/null || true; fi
if [ -n "$OUTPUT" ]; then export PCA_BENCH_SUITE_OUTPUT="$OUTPUT"; else unset PCA_BENCH_SUITE_OUTPUT 2>/dev/null || true; fi
"$VM" --headless "$BASE_IMAGE" st "$REPOSITORY/scripts/run-benchmark-suite.st"
