#!/usr/bin/env sh
set -u

if [ "$#" -ne 11 ]; then
    echo "usage: $0 VM IMAGE REPOSITORY TASK OUTPUT SKILL_MODE WORKSPACE PROFILE_ROOT TIMEOUT_SECONDS STDOUT STDERR" >&2
    exit 2
fi

VM=$1
IMAGE=$2
REPOSITORY=$3
TASK=$4
OUTPUT=$5
SKILL_MODE=$6
WORKSPACE=$7
PROFILE_ROOT=$8
TIMEOUT_SECONDS=$9
shift 9
STDOUT=$1
STDERR=$2
VERBOSITY=${PCA_BENCH_VERBOSITY:-0}
if [ "$VERBOSITY" -ge 2 ]; then export PCA_BENCH_STDOUT_LOG="$STDOUT"; else unset PCA_BENCH_STDOUT_LOG 2>/dev/null || true; fi

export PCA_BENCH_REPOSITORY="$REPOSITORY"
export PCA_BENCH_TASK="$TASK"
export PCA_BENCH_OUTPUT="$OUTPUT"
export PCA_BENCH_SKILL_MODE="$SKILL_MODE"
export PCA_BENCH_WORKSPACE="$WORKSPACE"
if [ -n "$PROFILE_ROOT" ]; then export PCA_BENCH_PROFILE_ROOT="$PROFILE_ROOT"; else unset PCA_BENCH_PROFILE_ROOT 2>/dev/null || true; fi
unset PCA_BENCH_EVALUATORS PCA_BENCH_EVALUATOR_TIMEOUT PCA_BENCH_EVALUATION_PLAN PCA_BENCH_EVALUATION_OUTPUT PCA_BENCH_WORKER_RESULT 2>/dev/null || true
mkdir -p "$(dirname "$STDOUT")" "$(dirname "$STDERR")"

run_worker() {
    if [ "$VERBOSITY" -ge 2 ]; then
        : >"$STDOUT"
        "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-worker.st" 2>"$STDERR"
    else
        "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-worker.st" >"$STDOUT" 2>"$STDERR"
    fi
}

if command -v timeout >/dev/null 2>&1; then
    if [ "$VERBOSITY" -ge 2 ]; then
        : >"$STDOUT"
        timeout --foreground --signal=TERM --kill-after=5s "$TIMEOUT_SECONDS" \
            "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-worker.st" 2>"$STDERR"
    else
        timeout --foreground --signal=TERM --kill-after=5s "$TIMEOUT_SECONDS" \
            "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-worker.st" >"$STDOUT" 2>"$STDERR"
    fi
    exit $?
fi

TIMED_OUT="$OUTPUT.timeout"
rm -f "$TIMED_OUT"
run_worker &
PID=$!
(
    sleep "$TIMEOUT_SECONDS"
    if kill -0 "$PID" 2>/dev/null; then
        : >"$TIMED_OUT"
        kill -TERM "$PID" 2>/dev/null || true
        sleep 5
        kill -KILL "$PID" 2>/dev/null || true
    fi
) &
WATCHDOG=$!
wait "$PID"
CODE=$?
kill "$WATCHDOG" 2>/dev/null || true
wait "$WATCHDOG" 2>/dev/null || true
if [ -f "$TIMED_OUT" ]; then rm -f "$TIMED_OUT"; exit 124; fi
exit "$CODE"
