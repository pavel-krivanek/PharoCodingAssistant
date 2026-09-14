#!/usr/bin/env sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 10 ]; then
    echo "usage: $0 VM BASE_IMAGE [TASK] [SKILL_MODE] [RUNS_ROOT] [EVALUATION_REPOSITORY] [PROFILE_ROOT] [VERBOSITY] [COMMON_ISSUES_MODE] [COMMON_ISSUES_PATH]" >&2
    exit 2
fi

VM=$1
BASE_IMAGE=$2
TASK=${3:-basic-001-expression}
SKILL_MODE=${4:-normal}
REPOSITORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RUNS_ROOT=${5:-"$REPOSITORY/benchmark/runs"}
EVALUATION_REPOSITORY=${6:-}
PROFILE_ROOT=${7:-}
VERBOSITY=${8:-1}
COMMON_ISSUES_MODE=${9:-readwrite}
COMMON_ISSUES_PATH=${10:-"$HOME/.pharo-ca/common-issues.md"}
case "$COMMON_ISSUES_MODE" in
  readwrite) CI_READ=1; CI_WRITE=1 ;;
  readonly) CI_READ=1; CI_WRITE=0 ;;
  writeonly) CI_READ=0; CI_WRITE=1 ;;
  off) CI_READ=0; CI_WRITE=0 ;;
  *) echo "invalid common issues mode: $COMMON_ISSUES_MODE" >&2; exit 2 ;;
esac

export PCA_BENCH_REPOSITORY="$REPOSITORY"
export PCA_BENCH_VM="$VM"
export PCA_BENCH_BASE_IMAGE="$BASE_IMAGE"
export PCA_BENCH_RUNS="$RUNS_ROOT"
export PCA_BENCH_TASK="$TASK"
export PCA_BENCH_SKILL_MODE="$SKILL_MODE"
export PCA_BENCH_VERBOSITY="$VERBOSITY"
export PCA_BENCH_COMMON_ISSUES_READ="$CI_READ" PCA_BENCH_COMMON_ISSUES_WRITE="$CI_WRITE" PCA_BENCH_COMMON_ISSUES_PATH="$COMMON_ISSUES_PATH"
if [ -n "$PROFILE_ROOT" ]; then export PCA_BENCH_PROFILE_ROOT="$PROFILE_ROOT"; else unset PCA_BENCH_PROFILE_ROOT 2>/dev/null || true; fi
if [ -n "$EVALUATION_REPOSITORY" ]; then
    export PCA_BENCH_EVALUATION_REPOSITORY="$EVALUATION_REPOSITORY"
fi

"$VM" --headless "$BASE_IMAGE" st "$REPOSITORY/scripts/run-benchmark-supervisor.st"
