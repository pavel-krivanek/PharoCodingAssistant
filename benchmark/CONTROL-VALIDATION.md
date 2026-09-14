# Benchmark development controls

Benchmark controls now live entirely in the separate **PharoCodingAssistant-BenchmarkEvaluations** repository.

Each public task has one known-good `...Solution` class. The repository also contains deliberately defective `...Mutant` classes for representative failure modes. `PharoCABenchmarkControlRunner` applies one control in a disposable image and scores it with the corresponding private `...Evaluation` class.

Current matrix:

- 51 positive Solution classes, one per public task;
- 25 negative Mutant classes;
- every positive control is expected to score exactly `1.0` / `passed`;
- every mutant has an explicit acceptable score range below full credit.

Solution and mutant source is a benchmark oracle and must never be loaded into a tested worker image. Ordinary post-worker evaluation loads only `PharoCodingAssistant-BenchmarkEvaluations`; the Solutions and Mutants packages are development-only.
