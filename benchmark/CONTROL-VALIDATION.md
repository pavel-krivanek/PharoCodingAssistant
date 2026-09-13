# Benchmark development controls

Benchmark development controls are private known-good and known-bad implementations used to validate the evaluator itself. They are not benchmark tasks and must never be placed in a worker-visible repository or workspace.

The public PCA repository contains only the generic control runner and cross-platform launchers. The private evaluator directory may contain:

```text
controls/
    positive-<task-id>.json
    negative-<task-id>-<mutation>.json
    positive/
        <task-id>.st
    negative/
        <task-id>-<mutation>.st
```

A control JSON file names the task, a private candidate source file, and an expected score range:

```json
{
  "id": "negative-example-shortcut",
  "taskId": "example-task",
  "candidate": "negative/example-shortcut.st",
  "expect": {
    "minScore": 0.0,
    "maxScore": 0.99,
    "outcomes": ["partial", "failed"]
  }
}
```

The candidate `.st` file is evaluated inside a disposable Pharo image and must answer a Dictionary. The runner adds `taskId`, `status` and an empty `answer` when they are absent, then invokes the ordinary hidden evaluator. A positive control normally requires exactly score `1.0` and outcome `passed`. A negative/mutation control normally requires a score below `1.0`.

Each control must run in a fresh image. Hidden evaluators can create dynamic classes or modify methods and benchmark candidates can refactor fixture classes, so reusing one image across controls would make results order-dependent.

## Linux

```sh
scripts/validate-benchmark-controls.sh \
    /path/to/pharo \
    /path/to/public-benchmark.image \
    /path/to/PharoCodingAssistant \
    /private/evaluators \
    /tmp/pca-control-validation
```

An optional sixth argument specifies the per-control timeout in seconds. The validator exits non-zero if any control violates its expected score range.

## Windows

```powershell
scripts\validate-benchmark-controls.ps1 `
    -Vm C:\Pharo\pharo.exe `
    -BaseImage C:\Pharo\benchmark.image `
    -Repository C:\src\PharoCodingAssistant `
    -EvaluatorRoot D:\private\pca-evaluators `
    -OutputRoot D:\tmp\pca-control-validation
```

Every control gets its own directory with `result.json`, stdout and stderr. The root also receives `summary.txt` and `summary.json`.

## Policy for new tasks

For each new benchmark task, add at least one positive control before considering the evaluator validated. For non-trivial tasks, also add one or more negative controls that represent plausible shortcuts or common mistakes, not merely syntactically broken code. Examples include bypassing a collaborator, leaving a refactoring half-complete, performing asynchronous work synchronously, failing cleanup on exceptions, replacing a mutable presenter instead of updating it, or hard-coding currently known discovery results.

Mutation controls are development assets. Their source is effectively a solution oracle and therefore belongs with the private evaluator pack, never in the public benchmark repository.
