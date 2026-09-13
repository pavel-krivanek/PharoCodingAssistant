#!/usr/bin/env sh
set -eu
PHARO_VM=${PHARO_VM:-pharo}
PHARO_IMAGE=${PHARO_IMAGE:?Set PHARO_IMAGE to a Pharo 14 image}
PCA_BENCH_TASK=${1:-${PCA_BENCH_TASK:-basic-001-expression}}
PCA_BENCH_OUTPUT=${2:-${PCA_BENCH_OUTPUT:-benchmark-results/result.json}}
PCA_BENCH_SKILL_MODE=${3:-${PCA_BENCH_SKILL_MODE:-normal}}
export PCA_BENCH_TASK PCA_BENCH_OUTPUT PCA_BENCH_SKILL_MODE
exec "$PHARO_VM" --headless "$PHARO_IMAGE" st --quit scripts/run-benchmark.st
