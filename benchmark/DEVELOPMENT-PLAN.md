# PCA benchmark development plan

## 001 — headless foundation

- [x] Keep benchmarking in the PCA repository while making it opt-in from the normal baseline.
- [x] Add public task metadata with explicit difficulty/category/tags/skill hints and no hidden answers.
- [x] Add deliberately easy level-1 tasks for smaller models.
- [x] Reuse `PharoCACodingHarness` instead of creating a parallel agent implementation.
- [x] Add `normal` and `preloaded` skill modes for paired skill-effect runs.
- [x] Add machine-readable JSON run results.
- [x] Add a UI-independent `.st` entry point.
- [x] Add thin Linux shell and Windows PowerShell launchers.
- [x] Verify the benchmark package and initial SUnit tests on the supplied Pharo 14 image.

## 002 — isolated task execution

- [x] Add a headless supervisor process which owns run identity and result directories.
- [x] Start each task from a disposable copy of a pristine worker image.
- [x] Give the PCA worker a dedicated task workspace rather than the PCA repository tree.
- [x] Store an append-only supervisor JSONL lifecycle journal plus worker stdout/stderr.
- [x] Persist the completed worker image for later out-of-process evaluation.
- [x] Add deterministic timeout/kill handling and terminal-result synthesis.
- [x] Normalize POSIX `system(3)` wait status so timeout is represented as exit code 124 cross-platform.
- [x] Add Linux and Windows launcher command tests.
- [x] Exercise the full Linux supervisor -> worker -> persisted-result path on the supplied Pharo 14 VM/image.
- [x] Exercise a real Linux forced timeout and verify synthesized durable timeout state.
- [ ] Execute the PowerShell worker/supervisor integration tests on Windows (the Windows path is implemented but this environment is Linux-only).

## 003 — hidden evaluation

- [x] Put expected results and hidden SUnit evaluators in supervisor/evaluator-only state via an external evaluator-plan directory.
- [x] Evaluate after the agent worker exits, in a separate evaluator process/image copied from the completed worker image.
- [x] Never expose hidden test names, source, pass counts or aggregate score to the worker.
- [x] Keep the generic evaluator in PCA while injecting task-specific expected values/hidden Tonel packages only into the post-worker evaluator process.
- [x] Remove evaluator-plan environment variables from Linux and Windows worker processes and verify the worker probe cannot see them.
- [x] Add weighted partial-credit result schema while retaining `passed` / `partial` / `failed` as primary correctness outcomes.
- [x] Distinguish worker timeout, evaluator timeout and evaluator failure from ordinary task failure.
- [ ] Add an optional OS-level sandbox/account/ACL layer for adversarial secrecy against arbitrary unrestricted Smalltalk filesystem enumeration.
- [ ] Execute the PowerShell evaluator integration path on Windows (command generation and environment scrubbing are implemented).

## 004 — skill experiments

- [ ] Add paired modes: optional skills unavailable, available/model-selected, relevant skill preloaded, and controlled irrelevant-skill conditions.
- [ ] Record offered, activated and final active skills per task.
- [ ] Compute per-task and aggregate skill delta for identical task/model pairs.
- [ ] Keep `Smalltalk Core` semantics explicit because PCA treats it as a mandatory built-in skill.

## 005 — crash recovery

- [ ] Supervisor owns the durable run journal; worker image is disposable.
- [ ] Journal source mutations outside the worker image.
- [ ] Restore code/session/skill state after an injected worker crash.
- [ ] Add deterministic crash points (after N completed tool calls / after mutation / after skill activation).
- [ ] Measure repeated exploration and recovery overhead separately from task correctness.

## 006 — benchmark breadth

- [x] Add task set 001 with 21 tasks from genuinely elementary level-1 work through initial level-3 navigation/debugging.
- [x] Cover basic syntax/messages/precedence, blocks, conditionals, Strings and integer intervals.
- [x] Add five paired-skill Collections tasks with independent partial-credit hidden checks.
- [x] Cover streams, FileReference, STON/JSON, Date/Duration, regex and elementary SUnit authoring.
- [x] Add the first live-image navigation/debugging fixtures where the target class is not named in the prompt.
- [x] Validate every private task-001 evaluator against a known-correct implementation on the supplied Pharo 14 image.
- [x] Extend to task set 002 (30 tasks) and independently validate all 9 new private evaluator plans on Pharo 14.
- [x] Add exception handling, processes/semaphores, announcements and reflection tasks.
- [x] Add first unknown-API discovery tasks whose APIs cannot be memorized from public training data.
- [x] Extend to task set 003 (41 tasks); validate all 11 new hidden plans against independent golden implementations and match the 41-ID private manifest to the public catalog.
- [x] Add task set 003 structural refactoring tasks with behavior and method-ownership regression checks.
- [x] Add first headless Spec2 tasks specifically designed for paired skill-effect measurement.
- [x] Extend to task set 004 (51 tasks) with stronger live-image API discovery, deeper multi-class navigation, stateful cache debugging and recursive unknown-API traversal; validate all 10 new hidden plans against independent golden implementations.
- [ ] Broaden plain-image API-discovery and Spec2 coverage after measuring the first skill deltas. External-package tasks are intentionally deferred.
- [ ] Derive historical PCA repair/feature tasks from older repository states while keeping later solutions hidden.
- [x] Add automated private development controls: one known-good implementation for every current task plus mutation/negative controls for representative failure modes.
- [x] Run controls in fresh disposable images and fail validation if a golden solution stops passing or a known shortcut reaches full credit.
- [x] Use mutation controls to harden the two SUnit-authoring evaluators against trivial passing tests.
- [ ] Expand mutation coverage as new tasks are added; non-trivial tasks should gain plausible negative controls, not only positive/golden controls.
- [ ] Add long-horizon project tasks and crash-recovery variants.
