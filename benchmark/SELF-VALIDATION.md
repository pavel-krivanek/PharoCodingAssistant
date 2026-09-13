# Benchmark self-validation

Date: 2026-09-13
Target: supplied plain Pharo 14 image, Linux VM
Task set: 004, 51 public tasks

## Blind solvability pass

The public prompts were solved before any task-specific private evaluator plan was inspected. Each task was executed in isolation from the same clean public benchmark image and then scored by the private evaluator.

The first fixed candidate solution set contained one genuine semantic mistake in `exceptions-002-ensure-cleanup`: it used `workBlock value ensure:` rather than protecting evaluation with `[ workBlock value ] ensure:`. The evaluator correctly rejected it. The mistake was diagnosed from the public task specification, corrected without inspecting the private plan, and then passed.

Result after that correction: **51 / 51 tasks passed all hidden checks**.

This validates prompt solvability and evaluator consistency; it is not a measurement of PCA tool-use performance, because the self-validation solutions were applied directly rather than produced through a PCA LLM session.

## Automated development controls

The blind solutions and mutation probes have now been turned into reusable private development controls. The public repository contains only the generic runner; candidate implementations stay beside the private evaluator plans.

Current matrix:

- **51 positive controls** — one independently authored known-good implementation for every public task; all must score exactly `1.0`.
- **25 negative controls** — plausible shortcuts or incomplete implementations across exception handling, streams, regex, filesystem, reflection/discovery, concurrency, Announcer lifecycle, refactoring, navigation, Spec2, SUnit authoring and unfamiliar APIs; all must score below `1.0`.
- **76 / 76 controls valid** in isolated fresh images on the supplied Pharo 14 VM/image.
- Highest negative-control score: **0.875**, so no current mutation is accidentally accepted as a complete solution.

The control validator deliberately creates a fresh image per control. This avoids contamination from dynamically created evaluator probes and task mutations.

## Evaluator weaknesses found by mutation testing

The first mutation pass found behaviorally correct implementations that violated explicit task constraints but still received full credit: constructing formatted lines without a stream, recognizing identifiers without regex, opening a file stream without closing it, pre-testing a zero denominator instead of handling `ZeroDivide`, and manually splitting a filename instead of using the `FileReference` extension API. These evaluators were hardened with AST/protocol checks.

Reflection and discovery tasks were strengthened with evaluator-created dynamic classes/packages/selectors. Hard-coded lookup tables that previously scored `1.0` now score only partial credit.

A later architectural mutation pass exposed two additional holes in the SUnit-authoring tasks. Trivial passing tests could satisfy the original source/count checks. The factorial evaluator now temporarily installs a deliberately broken `Integer>>factorial` and requires the submitted tests to detect the regression before restoring the original implementation. The Dictionary evaluator now verifies that separate submitted test methods actually send the normal insertion/retrieval protocol and the expected-exception protocol to Dictionary code.

## Current interpretation

A score of `1.0` means both behavioral checks and the explicitly required implementation constraints passed. Partial scores are intentionally retained for implementations that produce some correct behavior while violating part of the task contract.

The benchmark is not designed as an adversarial security contest. Source/AST checks can still be intentionally spoofed by hostile benchmark-aware code. The goal is to distinguish normal coding-agent behavior, API discovery, navigation and skill use, not to resist a model that has access to hidden evaluator contents.
