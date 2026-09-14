# PharoCodingAssistant benchmarks

The benchmark is part of the PCA repository and reuses the production agent, provider, tool, skill and workspace code. It is deliberately headless; no Spec or browser UI is required.

## Architecture

There are now two execution modes.

`run-benchmark.st` is the lightweight single-image development entry point.

The real benchmark path is supervised:

```text
headless supervisor image
    |
    +-- durable benchmark/runs/<run-id>/
    |      manifest.json
    |      journal.jsonl
    |      result.json
    |      evaluation.json              (created after worker exit)
    |      worker.stdout.log / worker.stderr.log
    |      evaluator.stdout.log / evaluator.stderr.log
    |      worker.image
    |      evaluator.image
    |      workspace/
    |
    +-- disposable headless worker process
    |       PCA harness + normal tools/skills
    |
    +-- post-worker evaluator process
            generic evaluator + supervisor-private plan/tests
```

The supervisor owns the run identity and files. Every task starts from a copied base image. The worker's PCA filesystem workspace is a dedicated empty directory inside the run directory, not the PCA repository. After the task finishes, the worker snapshots its image so a later evaluator process can inspect classes/methods created by the model.

`journal.jsonl` is append-only and survives worker failure. If a worker exits without writing `result.json`, the supervisor creates a terminal result. Timeout is represented consistently as exit code 124 on Linux and Windows.

This separation is the basis for hidden evaluation and crash recovery. Task-specific expected values and hidden evaluator code are **not implemented in the worker package** and are injected only after the worker exits.

> Workspace separation is currently an architectural isolation boundary, not an OS security sandbox. A sufficiently unrestricted Smalltalk evaluation could still access paths outside `PharoCAWorkspace`. Hidden evaluators therefore must ultimately live only in the supervisor/evaluator process (or another genuinely isolated resource), rather than simply in a hidden directory beside the worker.

## Linux

```sh
./scripts/run-benchmark-supervisor.sh \
    /path/to/pharo \
    /path/to/Pharo14.image \
    basic-001-expression \
    normal
```

The optional fifth argument selects the run root. The default is `benchmark/runs`.

The Linux worker wrapper uses GNU `timeout` when available and has a shell watchdog fallback. Worker stdout and stderr are redirected into the run directory.

## Windows

```powershell
.\scripts\run-benchmark-supervisor.ps1 `
    -Vm C:\Pharo\PharoConsole.exe `
    -BaseImage C:\Pharo\Pharo14.image `
    -Task basic-001-expression `
    -SkillMode normal
```

The PowerShell worker uses `System.Diagnostics.Process`, asynchronously drains stdout/stderr, and kills the worker when the timeout expires.


## Console verbosity

Benchmark console output is controlled by verbosity level `0..3` and is written by the Pharo benchmark code through `Stdio stdout`:

- `0` — quiet agent execution; only files/results are produced;
- `1` — suite/task lifecycle and final per-task status/score;
- `2` — level 1 plus worker/evaluator lifecycle, model-request iterations, active skills and tool start/completion events;
- `3` — level 2 plus live streamed assistant text, reasoning deltas and tool-call deltas.

On Windows pass `-Verbosity 0`, `1`, `2`, or `3` to `run-benchmark-suite.ps1` / `run-benchmark-supervisor.ps1`. The top-level `run-pca-benchmark.ps1` propagates the same level through the entire process tree. At verbosity 2 or 3 worker stdout is inherited so `Stdio stdout` reaches the launching console while the task is running rather than being shown only after process exit.

All benchmark VM invocations on both Windows and Linux explicitly pass `--headless`; there is no UI-capable Windows fallback. If the supplied VM cannot execute the benchmark with `--headless`, preparation fails instead of silently starting a GUI image.

## Benchmark task set 004

The catalog intentionally begins below the difficulty of typical coding-agent benchmarks so small/local models remain measurable. Task set 004 contains **51 tasks**. In addition to the basic, Collections, standard-library, SUnit, exception, concurrency, Announcer, reflection, refactoring and headless Spec2 coverage from earlier sets, it now includes:

- 4 dedicated live-image API-discovery tasks using the package model, implementor/sender navigation and the Opal parser/AST;
- 5 unfamiliar benchmark-local API tasks, including a recursive multi-class document-tree traversal;
- 7 live-image navigation/debugging tasks, with multi-class call chains, configuration precedence and a stateful stale-cache defect;
- difficulty level 5 for tasks requiring sustained navigation across stateful or recursive APIs.

See `benchmark/TASKS.md` for the complete catalog and difficulty definitions. Task-specific expected values remain outside the PCA checkout in the private evaluator pack.

The benchmark currently targets the **plain supplied Pharo image only**. Tasks must not require downloading or loading external packages. Spec2 is used because it is already present in the image and is evaluated headlessly without opening windows.

## Skill experiments

The current paired modes are:

- `normal` — optional skills remain model-selected;
- `preloaded` — task-declared skills are activated before the run.

Additional ablation/irrelevant-skill conditions belong in the next skill-experiment slice. Runs with different skill conditions always use a fresh copy of the same base image.

## Infrastructure probe

`PCA_BENCH_INFRASTRUCTURE_PROBE=1` is reserved for infrastructure validation. In this mode the worker writes a probe result and snapshots without loading PCA or calling an LLM. `PCA_BENCH_INFRASTRUCTURE_PROBE_SLEEP_SECONDS` can deliberately hold the worker so timeout handling can be tested. These variables are not benchmark task features.

## Hidden evaluation

Task correctness is evaluated only after the agent worker has terminated. The evaluator is a second headless Pharo process started from a copy of the completed `worker.image`:

```text
supervisor
    |
    +-- worker.image  -> agent task -> result.json -> snapshot/exit
    |
    +-- copy worker.image -> evaluator.image
    |                       + hidden plan injected now
    |                       + optional hidden SUnit Tonel package
    |                       + evaluation.json
    |
    +-- journal.jsonl
```

The repository contains only the **generic evaluator engine**. Expected values, hidden expressions and hidden SUnit packages are stored in a separately configured evaluator-plan directory. Pass that directory as the optional sixth Linux argument or `-EvaluatorPlanRoot` on Windows. It should normally be outside the PCA checkout.

The hidden plan path is deliberately absent from `PharoCABenchmarkTask`, `manifest.json`, the worker command line and worker lifecycle events. The Linux and Windows worker wrappers also remove all `PCA_BENCH_EVALUAT*` variables before starting the agent VM, so a model inspecting `OSEnvironment` does not learn the hidden-plan location.

The worker never receives hidden-test feedback. `evaluation.json` is created only after the worker is gone. Per-check output contains only an ordinal, status and awarded/possible weight; expected values, expressions, test selectors and hidden source are not copied into the evaluation result.

Supported evaluator checks currently are:

- `answerEquals` — exact trimmed comparison with the final worker answer;
- `expressionIsTrue` — evaluate a hidden Smalltalk expression and require `true`;
- `expressionPrintEquals` — compare an evaluated object's `printString` with a hidden value;
- `sunitTonel` — load a hidden Tonel package from the private evaluator-plan directory and score the selected SUnit class by the fraction of passing tests.

Checks are weighted. `score` is in `[0,1]`, while the primary outcome remains `passed`, `partial`, or `failed`. Infrastructure conditions such as a worker timeout or evaluator timeout remain distinguishable as `notEvaluated` / `evaluatorFailed` rather than being disguised as ordinary test failures.

A private plan directory has one `<task-id>.json` plan per task. See `EVALUATOR-PLAN-FORMAT.md` for the schema. Private plans should not be committed to PCA.

This is strong separation at the PCA protocol/process level, but it is still **not an OS security sandbox**. Arbitrary unrestricted Smalltalk can in principle enumerate host files. For adversarial benchmark secrecy, run the worker under a separate OS account/container/ACL boundary that cannot read the private evaluator directory. The benchmark architecture is intentionally compatible with adding that layer later without changing task/evaluator semantics.

## Validation

See `SELF-VALIDATION.md` for the blind 51-task solvability run and mutation-testing results. `CONTROL-VALIDATION.md` documents the reusable private positive/negative control mechanism. The current private matrix contains 51 known-good controls and 25 mutation controls, each executed in its own disposable image. Private evaluator plans and control source are intentionally kept outside this repository tree.

## Reproducible provider/model profiles

Benchmark workers can use an isolated PCA profile root instead of the normal `~/.pharo-ca`. This prevents personal instructions, skills and session state from silently changing benchmark behavior. The benchmark profile should contain only `runtime.json` and, optionally, `settings.json`; built-in skills still come from the PCA codebase.

Configure and select the provider/model in ordinary PCA, call `saveRuntimeProfile`, then copy only the reproducible runtime/settings files:

```powershell
.\scripts\prepare-benchmark-profile.ps1 `
    -Destination C:\PCA-Benchmark-Profiles\qwen38-q4
```

By default the source is `$HOME\.pharo-ca`. `runtime.json` stores provider/model descriptors and credential *environment-variable mappings*, not secret values. Supply any required API key through the mapped environment variable when running the benchmark.

A single supervised Windows task can then use that profile explicitly:

```powershell
.\scripts\run-benchmark-supervisor.ps1 `
    -Vm C:\Pharo14\PharoConsole.exe `
    -BaseImage C:\Pharo14\Pharo14.image `
    -ProfileRoot C:\PCA-Benchmark-Profiles\qwen38-q4 `
    -EvaluatorPlanRoot D:\Private\PCAEvaluators `
    -Task discovery-003-senders `
    -SkillMode normal
```

The worker records the **effective** provider id/class, endpoint, model id, context size, maximum output tokens, reasoning effort and model capability flags in `result.json`. After the worker exits the supervisor copies this non-secret metadata into `manifest.json` as `workerConfiguration`, so old run directories remain attributable even if the profile later changes.

## Running a suite

`run-benchmark-suite.ps1` runs the selected task catalog serially through the ordinary disposable-worker supervisor and writes one aggregate JSON report. A reproducible Windows run of all tasks is:

```powershell
.\scripts\run-benchmark-suite.ps1 `
    -Vm C:\Pharo14\PharoConsole.exe `
    -BaseImage C:\Pharo14\Pharo14.image `
    -ProfileRoot C:\PCA-Benchmark-Profiles\qwen38-q4 `
    -EvaluatorPlanRoot D:\Private\PCAEvaluators `
    -SkillModes both `
    -Verbosity 2
```

`both` means all tasks run in `normal` mode and tasks that declare relevant skills are additionally run in `preloaded` mode. Preloaded duplicates are skipped for tasks with no declared skills. Use `-Tasks "basic-001-expression,collections-001-select-even"` for a subset, `-TimeoutSeconds` for slow local models, `-Verbosity 0..3` for console detail, and `-Output` to choose the aggregate JSON file.

The suite report contains per-run paths/results, per-mode average scores and a paired `skillDelta` calculated only from skill-sensitive tasks that have both normal and preloaded scores.
