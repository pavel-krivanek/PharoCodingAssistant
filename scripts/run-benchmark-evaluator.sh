#!/usr/bin/env sh
set -u

if [ "$#" -ne 10 ]; then
    echo "usage: $0 VM IMAGE REPOSITORY TASK WORKER_RESULT PLAN EVALUATION TIMEOUT_SECONDS STDOUT STDERR" >&2
    exit 2
fi

VM=$1
IMAGE=$2
REPOSITORY=$3
TASK=$4
WORKER_RESULT=$5
PLAN=$6
EVALUATION=$7
TIMEOUT_SECONDS=$8
STDOUT=$9
shift 9
STDERR=$1

export PCA_BENCH_REPOSITORY="$REPOSITORY"
export PCA_BENCH_TASK="$TASK"
export PCA_BENCH_WORKER_RESULT="$WORKER_RESULT"
export PCA_BENCH_EVALUATION_PLAN="$PLAN"
export PCA_BENCH_EVALUATION_OUTPUT="$EVALUATION"

mkdir -p "$(dirname "$STDOUT")" "$(dirname "$STDERR")"

if command -v timeout >/dev/null 2>&1; then
    timeout --foreground --signal=TERM --kill-after=5s "$TIMEOUT_SECONDS" \
        "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-evaluator.st" \
        >"$STDOUT" 2>"$STDERR"
    exit $?
fi

TIMED_OUT="$EVALUATION.timeout"
rm -f "$TIMED_OUT"
"$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-evaluator.st" \
    >"$STDOUT" 2>"$STDERR" &
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

if [ -f "$TIMED_OUT" ]; then
    rm -f "$TIMED_OUT"
    exit 124
fi
exit "$CODE"
