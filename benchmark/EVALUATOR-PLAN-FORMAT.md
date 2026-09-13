# Hidden evaluator plan format

Evaluator plans are supervisor-private JSON files stored outside the worker-visible PCA repository. A plan is selected by filename `<task-id>.json` and must repeat the same task id internally.

Example shape using deliberately non-benchmark placeholder values:

```json
{
  "taskId": "example-task",
  "checks": [
    {
      "kind": "answerEquals",
      "weight": 1.0,
      "expected": "<secret expected answer>"
    },
    {
      "kind": "expressionIsTrue",
      "weight": 2.0,
      "expression": "<hidden Smalltalk boolean expression>"
    },
    {
      "kind": "expressionPrintEquals",
      "weight": 1.0,
      "expression": "<hidden Smalltalk expression>",
      "expected": "<secret printString>"
    },
    {
      "kind": "sunitTonel",
      "weight": 4.0,
      "package": "Private-Benchmark-Tests",
      "class": "PrivateBenchmarkTest"
    }
  ]
}
```

For `sunitTonel`, `package` is a Tonel package directory beside the plan file. The package is loaded only in the post-worker evaluator image. Its test names/source are never written to the agent result or evaluation JSON. The check earns `weight * (passed tests / run tests)` points.

The generic evaluator catches a failing/erroring hidden expression as a failed check, allowing subsequent checks to run. A malformed plan itself produces `evaluatorFailed`.

Do not place real hidden plans or hidden Tonel packages under the PCA checkout if secrecy matters. Keep them in a separate directory and supply that path only to the supervisor.
