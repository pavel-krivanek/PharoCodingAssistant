#!/usr/bin/env sh
set -u

if [ "$#" -ne 9 ]; then
    echo "usage: $0 VM IMAGE REPOSITORY EVALUATOR_ROOT CONTROL OUTPUT TIMEOUT_SECONDS STDOUT STDERR" >&2
    exit 2
fi

VM=$1
IMAGE=$2
REPOSITORY=$3
EVALUATOR_ROOT=$4
CONTROL=$5
OUTPUT=$6
TIMEOUT_SECONDS=$7
STDOUT=$8
STDERR=$9

export PCA_BENCH_REPOSITORY="$REPOSITORY"
export PCA_BENCH_EVALUATORS="$EVALUATOR_ROOT"
export PCA_BENCH_CONTROL_FILE="$CONTROL"
export PCA_BENCH_CONTROL_OUTPUT="$OUTPUT"

mkdir -p "$(dirname "$OUTPUT")" "$(dirname "$STDOUT")" "$(dirname "$STDERR")"

if command -v timeout >/dev/null 2>&1; then
    timeout --foreground --signal=TERM --kill-after=5s "$TIMEOUT_SECONDS" \
        "$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-control.st" \
        >"$STDOUT" 2>"$STDERR"
    exit $?
fi

TIMED_OUT="$OUTPUT.timeout"
rm -f "$TIMED_OUT"
"$VM" --headless "$IMAGE" st "$REPOSITORY/scripts/run-benchmark-control.st" \
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
