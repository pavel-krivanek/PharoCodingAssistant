#!/usr/bin/env sh
set -u

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
    echo "usage: $0 VM BASE_IMAGE REPOSITORY EVALUATOR_ROOT OUTPUT_ROOT [TIMEOUT_SECONDS]" >&2
    exit 2
fi

VM=$1
BASE_IMAGE=$2
REPOSITORY=$3
EVALUATOR_ROOT=$4
OUTPUT_ROOT=$5
TIMEOUT_SECONDS=${6:-60}
CONTROL_ROOT="$EVALUATOR_ROOT/controls"
RUNNER="$REPOSITORY/scripts/run-benchmark-control.sh"

if [ ! -d "$CONTROL_ROOT" ]; then
    echo "missing private control directory: $CONTROL_ROOT" >&2
    exit 2
fi

mkdir -p "$OUTPUT_ROOT"
FAILURES=0
COUNT=0

for CONTROL in "$CONTROL_ROOT"/*.json; do
    [ -f "$CONTROL" ] || continue
    COUNT=$((COUNT + 1))
    NAME=$(basename "$CONTROL" .json)
    WORK="$OUTPUT_ROOT/$NAME"
    IMAGE="$WORK/control.image"
    RESULT="$WORK/result.json"
    STDOUT="$WORK/stdout.log"
    STDERR="$WORK/stderr.log"
    mkdir -p "$WORK"
    cp "$BASE_IMAGE" "$IMAGE"
    BASE_CHANGES=${BASE_IMAGE%.image}.changes
    if [ -f "$BASE_CHANGES" ]; then
        cp "$BASE_CHANGES" "$WORK/control.changes"
    fi

    "$RUNNER" "$VM" "$IMAGE" "$REPOSITORY" "$EVALUATOR_ROOT" "$CONTROL" "$RESULT" "$TIMEOUT_SECONDS" "$STDOUT" "$STDERR"
    CODE=$?
    if [ "$CODE" -eq 0 ]; then
        printf 'PASS %s\n' "$NAME"
    else
        printf 'FAIL %s (exit %s)\n' "$NAME" "$CODE"
        FAILURES=$((FAILURES + 1))
    fi
    rm -f "$IMAGE" "$WORK/control.changes"
done

printf 'controls=%s passed=%s failed=%s\n' "$COUNT" "$((COUNT - FAILURES))" "$FAILURES" | tee "$OUTPUT_ROOT/summary.txt"
printf '{"controls":%s,"passed":%s,"failed":%s}\n' "$COUNT" "$((COUNT - FAILURES))" "$FAILURES" > "$OUTPUT_ROOT/summary.json"
[ "$FAILURES" -eq 0 ]
