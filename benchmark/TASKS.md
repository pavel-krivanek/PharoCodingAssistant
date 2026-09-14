# Benchmark task catalog

The public benchmark catalog deliberately starts below the difficulty of typical coding-agent benchmarks. The goal is to distinguish small/local models as well as strong coding models.

## Difficulty scale

- **1 — elementary**: one expression or one small method using basic Smalltalk syntax/messages. A weak model should have a realistic chance.
- **2 — basic developer**: a small class/method using a standard Pharo library or a non-trivial collection idiom. Image browsing may help but the target is explicit.
- **3 — navigation/debugging or advanced library use**: the task requires live-image API discovery, process/event behavior, or locating existing code.
- **4 — unfamiliar API**: the API is benchmark-local and cannot be recalled from public training data; the agent must inspect classes/protocols in the live image.
- **5 — sustained discovery/navigation**: stateful or recursive behavior requires following several collaborators and preserving architectural constraints. Later sets will add historical PCA tasks and crash-recovery variants.

## Current set (004)

### Elementary language and coding

- `basic-001-expression` — arithmetic evaluation.
- `basic-002-method` — one two-argument method.
- `basic-003-collection` — simple `collect:`-style transformation.
- `basic-004-precedence` — Smalltalk unary/binary/keyword precedence awareness.
- `basic-005-condition` — three-way conditional.
- `basic-006-block` — evaluate a block argument.
- `basic-007-range-sum` — interval/iteration behavior.
- `basic-008-palindrome` — elementary String behavior.
- `basic-009-repeat-string` — repeat a String a requested number of times.
- `basic-010-maximum-two` — choose the larger of two values.

### Collections

- `collections-001-select-even` — filtering while preserving order.
- `collections-002-frequency-table` — Dictionary accumulation.
- `collections-003-unique-order` — uniqueness with stable order.
- `collections-004-group-parity` — grouping with required empty groups.
- `collections-005-sort-descending` — sorting without mutating the input.
- `collections-006-any-negative` — elementary `anySatisfy:`-style predicate task.

All six declare the built-in `Collections` skill, allowing paired normal/preloaded runs.

### Standard libraries

- `library-001-stream-lines` — stream construction and exact line separators.
- `library-002-json-decode` — JSON/STON support already present in Pharo 14.
- `library-003-regex-identifier` — regex matching with whole-string semantics.
- `library-004-date-difference` — `Date`/`Duration` arithmetic.
- `library-005-file-first-line` — `FileReference` and stream lifetime.
- `library-006-path-extension` — query a `FileReference` path without manual String splitting.

### Testing

- `testing-001-sunit-factorial` — create and run a real SUnit `TestCase` subclass.
- `testing-002-sunit-exception` — use SUnit exception assertions alongside a normal Dictionary test.

### Exceptions and cleanup

- `exceptions-001-safe-division` — handle the actual `ZeroDivide` exception rather than pre-testing.
- `exceptions-002-ensure-cleanup` — `ensure:` semantics, result preservation, and propagation of the original error.

### Processes and announcements

- `concurrency-001-fork-wait` — fork a real Process and synchronize its result with a Semaphore. Hidden evaluation verifies the block did not run in the caller Process.
- `announcements-001-count-during` — discover the Pharo 14 `Announcer` subscription API, count events, and reliably unsubscribe on success or failure.

### Reflection

- `reflection-001-class-lookup` — resolve classes through the image/global environment.
- `reflection-002-selector-prefix` — inspect selectors defined directly by a class and return a sorted result.

### Live-image API discovery

These tasks intentionally specify the required behavior but not the concrete Pharo API. The agent must discover the relevant image facilities rather than rely on a named helper.

- `discovery-001-package-classes` — discover the package organizer/model and enumerate classes in a package.
- `discovery-002-implementor-classes` — discover image navigation for selector implementors.
- `discovery-003-sender-signatures` — discover sender navigation and work with `CompiledMethod` metadata.
- `discovery-004-ast-sent-selectors` — discover the Opal parser/AST API and extract sends without source-text scanning.

### Unknown benchmark-local APIs

These fixtures intentionally have no external documentation or training-data history. Their public protocols are visible in the live image, so success measures actual navigation/API learning.

- `unknown-001-telemetry-mean` — discover a custom telemetry API and compute a channel mean.
- `unknown-002-ledger-balance` — discover interacting ledger/posting protocols and compute a balance.
- `unknown-003-cheapest-direct-route` — discover route-map/leg protocols and choose the cheapest outgoing destination.
- `unknown-004-job-board-priority` — discover job-board/ticket protocols and select by ticket priority.
- `unknown-005-document-subtree-weight` — discover a tree/node protocol and recursively aggregate a subtree.


### Refactoring

- `refactoring-001-rename-selector` — rename an existing selector, update fixture senders, and remove the legacy API rather than leaving a forwarding method.
- `refactoring-002-pull-up-method` — move duplicated behavior into the superclass and verify both behavior and method ownership.

### Spec2 skill-sensitive UI

These tasks are deliberately executable and evaluable headlessly. All three declare the built-in `Spec2` skill so the same task can be compared in `normal` and `preloaded` skill modes.

- `spec2-001-counter-presenter` — label/button presenter lifecycle and live label updates.
- `spec2-002-greeting-presenter` — text input, button action, and dynamic label state.
- `spec2-003-todo-presenter` — list state, text input clearing, stable presenter identity, and button-driven updates.

### Navigation/debugging

- `navigation-001-codebook` — discover an existing fixture by selector/behavior and extend it without regressions.
- `navigation-002-running-total` — locate a deliberately buggy fixture from observed behavior and repair it without being told its class or selector.
- `navigation-003-invoice-tax-chain` — find an entry selector, trace through a collaborating policy object, and repair the underlying defect rather than patching the public entry point.
- `navigation-004-discount-chain` — trace a checkout request through pricing into the policy that owns the incorrect rule.
- `navigation-005-locale-chain` — follow service/renderer/catalog collaborators and repair locale selection at the catalog layer.
- `navigation-006-configuration-precedence` — locate layered configuration behind a service and repair override precedence.
- `navigation-007-cache-invalidation` — reproduce a stateful read/rename/read failure and repair cache invalidation without bypassing caching.

## Evaluation

Task definitions contain no expected values. The separate `PharoCodingAssistant-BenchmarkEvaluations` repository contains one private Evaluation class per task, with multiple independent checks for most coding tasks so partial correctness can be measured. It is loaded only into the post-worker evaluator process.
