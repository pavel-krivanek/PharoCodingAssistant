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
            PharoCodingAssistant-BenchmarkEvaluations repository
```

The supervisor owns the run identity and files. Every task starts from a copied base image. The worker's PCA filesystem workspace is a dedicated empty directory inside the run directory, not the PCA repository. After the task finishes, the worker snapshots its image so a later evaluator process can inspect classes/methods created by the model.

`journal.jsonl` is append-only and survives worker failure. If a worker exits without writing `result.json`, the supervisor creates a terminal result. Timeout is represented consistently as exit code 124 on Linux and Windows.

This separation is the basis for hidden evaluation and crash recovery. Each public task is its own concrete `PharoCABenchmarkTask` subclass. Hidden evaluator/solution classes are **not present in this repository or worker image**; they live in the separate `PharoCodingAssistant-BenchmarkEvaluations` repository and are loaded only after the worker exits.

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

On Windows pass `-Verbosity 0`, `1`, `2`, or `3` to `run-benchmark-suite.ps1` / `run-benchmark-supervisor.ps1`. The top-level `run-pca-benchmark.ps1` propagates the same level through the entire process tree. On Windows, Pharo stdout/stderr is always redirected by the launcher and actively tee'd to the parent console while it is also written to the per-run log files. This avoids unreliable native handle inheritance through the nested PowerShell/Pharo process chain. At verbosity 2 or 3, `Stdio stdout` output therefore remains live while preserving deterministic logs.

All benchmark VM invocations on both Windows and Linux explicitly pass `--headless`; there is no UI-capable Windows fallback. If the supplied VM cannot execute the benchmark with `--headless`, preparation fails instead of silently starting a GUI image.

## Benchmark task set 004

The catalog intentionally begins below the difficulty of typical coding-agent benchmarks so small/local models remain measurable. Task set 004 contains **51 tasks**. In addition to the basic, Collections, standard-library, SUnit, exception, concurrency, Announcer, reflection, refactoring and headless Spec2 coverage from earlier sets, it now includes:

- 4 dedicated live-image API-discovery tasks using the package model, implementor/sender navigation and the Opal parser/AST;
- 5 unfamiliar benchmark-local API tasks, including a recursive multi-class document-tree traversal;
- 7 live-image navigation/debugging tasks, with multi-class call chains, configuration precedence and a stateful stale-cache defect;
- difficulty level 5 for tasks requiring sustained navigation across stateful or recursive APIs.

See `benchmark/TASKS.md` for the complete catalog and difficulty definitions. Task-specific expected values remain outside the PCA checkout in the separate `PharoCodingAssistant-BenchmarkEvaluations` repository.

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
    +-- worker.image -> public task + PCA agent -> result.json -> snapshot/exit
    |
    +-- copy worker.image -> evaluator.image
                            + load separate PharoCodingAssistant-BenchmarkEvaluations repo
                            + select the one Evaluation class for task id
                            + evaluation.json
```

The public PCA checkout contains **no task-specific evaluator or solution classes**. Each task is represented by one concrete public task class such as `PharoCABenchmarkBasic002MethodTask`. The private companion repository contains the corresponding `PharoCABenchmarkBasic002MethodEvaluation` and `PharoCABenchmarkBasic002MethodSolution`. The stable join key is the task id (`basic-002-method`).

Pass the private repository as `-EvaluationRepository` on Windows or the evaluation-repository argument on Linux. The supervisor receives that path, but worker wrappers remove `PCA_BENCH_EVALUATION_REPOSITORY` (and legacy evaluator variables) before starting the tested worker VM. The path is absent from the task object, run manifest, worker command line and worker lifecycle events.

Hidden checks are owned by the concrete private Evaluation class. Hidden Smalltalk expressions are stored there as Strings and compiled only when a check executes. This is intentional: permanently compiling hidden selector literals into evaluator methods would alter sender/implementor results in the image being measured.

`evaluation.json` contains only scoring output (ordinal checks/weights, outcome, score and evaluator errors), never the hidden expected expressions or known-good source. Known-good Solution classes and mutation controls are development-only and are not loaded by ordinary benchmark evaluation.

This is strong process/protocol separation but still not an OS security sandbox. For adversarial benchmark secrecy, make the private repository unreadable to the worker process with a separate OS account/container/ACL boundary.

## Validation

See `SELF-VALIDATION.md` for the blind 51-task solvability run and mutation-testing results. `CONTROL-VALIDATION.md` documents the reusable private positive/negative control mechanism. The current private matrix contains 51 known-good controls and 25 mutation controls, each executed in its own disposable image. Private Evaluation, Solution and mutant/control classes are intentionally kept in the separate `PharoCodingAssistant-BenchmarkEvaluations` repository.

## Reusable common-issues learning in benchmarks

Benchmark workers use the same `remember_common_issue` tool as ordinary PCA. The top-level Windows driver defaults to **read/write** access to `%USERPROFILE%\.pharo-ca\common-issues.md`, even though runtime/model settings use an isolated benchmark profile. This is intentional: by default benchmark agents can benefit from reusable Pharo lessons learned by previous runs and can contribute newly proven lessons.

For controlled comparisons, choose one of four modes:

```powershell
# default: read earlier lessons and append new ones
.\run-pca-benchmark.ps1 -Mode Full -CommonIssuesMode readwrite

# freeze the knowledge base during measurement
.\run-pca-benchmark.ps1 -Mode Full -CommonIssuesMode readonly

# collect struggles without giving the model previous lessons
.\run-pca-benchmark.ps1 -Mode Full -CommonIssuesMode writeonly

# clean-room benchmark
.\run-pca-benchmark.ps1 -Mode Full -CommonIssuesMode off
```

Use `-CommonIssuesPath` to create an independent knowledge stream, for example one file per model:

```powershell
.\run-pca-benchmark.ps1 -Mode Full `
    -ModelId ornith-1.5-35b-a3b `
    -CommonIssuesPath C:\tmp\benchmark\model-memory\ornith.md
```

The selected mode/path and the file's initial SHA-256 are recorded in `work\state\benchmark-environment.json`. This matters for reproducibility because an evolving shared knowledge file intentionally makes later runs different from earlier ones.

## Reproducible provider/model profiles

Benchmark workers can use an isolated PCA profile root instead of the normal `~/.pharo-ca`. This prevents personal instructions, skills and session state from silently changing benchmark behavior. The benchmark profile should contain only `runtime.json` and, optionally, `settings.json`; built-in skills still come from the PCA codebase. Common-issues learning is the deliberate exception and is independently controlled as described above.

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
    -EvaluationRepository C:\repos\PharoCodingAssistant-BenchmarkEvaluations `
    -Task discovery-003-senders `
    -SkillMode normal
```

The worker records the **effective** provider id/class, endpoint, model id, loaded context size, model maximum context, context-source metadata, maximum output tokens, selected reasoning effort, advertised reasoning options/default, metadata source, and model capability flags in `result.json`. After the worker exits the supervisor copies this non-secret metadata into `manifest.json` as `workerConfiguration`, so old run directories remain attributable even if the profile later changes.

## Running a suite

`run-benchmark-suite.ps1` runs the selected task catalog serially through the ordinary disposable-worker supervisor and writes one aggregate JSON report. A reproducible Windows run of all tasks is:

```powershell
.\scripts\run-benchmark-suite.ps1 `
    -Vm C:\Pharo14\PharoConsole.exe `
    -BaseImage C:\Pharo14\Pharo14.image `
    -ProfileRoot C:\PCA-Benchmark-Profiles\qwen38-q4 `
    -EvaluationRepository C:\repos\PharoCodingAssistant-BenchmarkEvaluations `
    -SkillModes both `
    -Verbosity 2
```

`both` means all tasks run in `normal` mode and tasks that declare relevant skills are additionally run in `preloaded` mode. Preloaded duplicates are skipped for tasks with no declared skills. Use `-Tasks "basic-001-expression,collections-001-select-even"` for a subset, `-TimeoutSeconds` for slow local models, `-Verbosity 0..3` for console detail, and `-Output` to choose the aggregate JSON file.

The suite report contains per-run paths/results, per-mode average scores and a paired `skillDelta` calculated only from skill-sensitive tasks that have both normal and preloaded scores.


## Stopping a Windows benchmark

The top-level Windows benchmark driver tracks the active suite process in `work\state\active-run.json` and owns the complete descendant process tree. Pressing **Ctrl+C** in the benchmark console now unwinds through a `finally` block that terminates the active suite with `taskkill /T /F`, so its supervisor, worker, evaluator and wrapper descendants are terminated as well. Completed logs/results and already-created workspaces remain on disk for diagnosis.

A run can also be stopped from another PowerShell window:

```powershell
.\run-pca-benchmark.ps1 -Mode Stop
```

`Stop` first validates and terminates the PID recorded in `active-run.json`. As a recovery fallback it also looks for Pharo processes using the disposable benchmark VM below `work\vm` and detached benchmark wrapper scripts belonging to this PCA checkout. It does not target LM Studio or Pharo executables from other installations. The stop request is recorded in `work\state\stop-request.json`.

The repository-level Windows launchers (`run-benchmark-suite.ps1`, `run-benchmark-supervisor.ps1`, `run-benchmark-worker.ps1`, `run-benchmark-evaluator.ps1` and `run-benchmark.ps1`) also terminate their current native Pharo child tree from `finally` when interrupted, so direct use of those scripts does not intentionally leave detached VMs either.
