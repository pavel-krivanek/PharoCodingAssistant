#!/usr/bin/env sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 7 ]; then
    echo "usage: $0 VM BASE_IMAGE [TASK] [SKILL_MODE] [RUNS_ROOT] [EVALUATOR_PLAN_ROOT] [PROFILE_ROOT]" >&2
    exit 2
fi

VM=$1
BASE_IMAGE=$2
TASK=${3:-basic-001-expression}
SKILL_MODE=${4:-normal}
REPOSITORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RUNS_ROOT=${5:-"$REPOSITORY/benchmark/runs"}
EVALUATOR_PLAN_ROOT=${6:-}
PROFILE_ROOT=${7:-}

export PCA_BENCH_REPOSITORY="$REPOSITORY"
export PCA_BENCH_VM="$VM"
export PCA_BENCH_BASE_IMAGE="$BASE_IMAGE"
export PCA_BENCH_RUNS="$RUNS_ROOT"
export PCA_BENCH_TASK="$TASK"
export PCA_BENCH_SKILL_MODE="$SKILL_MODE"
if [ -n "$PROFILE_ROOT" ]; then export PCA_BENCH_PROFILE_ROOT="$PROFILE_ROOT"; else unset PCA_BENCH_PROFILE_ROOT 2>/dev/null || true; fi
if [ -n "$EVALUATOR_PLAN_ROOT" ]; then
    export PCA_BENCH_EVALUATORS="$EVALUATOR_PLAN_ROOT"
fi

"$VM" --headless "$BASE_IMAGE" st "$REPOSITORY/scripts/run-benchmark-supervisor.st"
