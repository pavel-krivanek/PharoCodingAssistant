# Hidden evaluator representation

Task set 004 no longer uses per-task JSON evaluator plans.

Each public benchmark task has one concrete task class in `PharoCodingAssistant`, while its hidden evaluator and known-good solution are concrete classes in the separate **PharoCodingAssistant-BenchmarkEvaluations** repository. See `benchmark/README.md` and the private repository README for the architecture.
