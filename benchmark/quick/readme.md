I prepared the single Windows driver script:

[Download `run-pca-benchmark.ps1`](sandbox:/mnt/data/run-pca-benchmark.ps1)

SHA-256: `81f921144c8ec48cea2ca725e0ba097b9efff35e5cb0f3639d1e1053790243b3`

It assumes exactly this layout:

```
C:\tmp\benchmark\
    run-pca-benchmark.ps1

    resources\
        pharo-win-stable-signed.zip
        pharoImage-x86_64.zip

    private\
        basic-001-expression.json
        ...
        controls\
        ...

C:\repos\PharoCodingAssistant\
```

Everything generated goes under:

```
C:\tmp\benchmark\work\
```

including extracted VM, extracted Pharo image, isolated PCA model profile, runs, logs and aggregate results. The original ZIPs are never modified. `private` is also treated as read-only input; I deliberately preserve it on `Clean` because currently there is no private evaluator ZIP under `resources`.

The script automatically detects the actual image filename, so something such as:

```
Pharo14.0-SNAPSHOT-64bit-f5798ec105.image
```

needs no configuration.

It also prefers `PharoConsole.exe` and falls back to `Pharo.exe`.

### LM Studio configuration

The script queries:

```
http://127.0.0.1:1234/v1/models
```

and by default looks for:

```
*qwen3.8*27b*
```

so it should identify your `Qwen3.8-27B-GGUF` automatically. If several Qwen 27B variants are exposed, it refuses to guess and asks you to specify the API model ID.

For PCA I used the **actually loaded context from your screenshot**:

```
contextSize             196608
maximumOutputTokens      16384

tools                    true
parallelToolCalls        false
reasoning                false
reasoningStreaming       false
usageStreaming           false
images                   false
systemMessages           true
```

The `262144` value shown by LM Studio is the model's architectural maximum, but because you've actually loaded it at `196608`, **196608 is the correct benchmark context value**.

The script also records your visible LM Studio configuration---65 GPU offload layers, 9 CPU threads, 2048 evaluation batch, 512 physical batch, MTP with 3 draft tokens, Q8_0 KV caches, Flash Attention, etc.---in:

```
work\state\benchmark-environment.json
```

Those LM Studio engine parameters are recorded for reproducibility, but the script does **not** try to change them through the OpenAI API. Have the model loaded in LM Studio with the screenshot configuration before running.

### Running it

I suggest starting with:

```
cd C:\tmp\benchmark

powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 -Mode Models
```

That shows exactly what LM Studio calls the model.

Then:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 -Mode Prepare
```

This:

-   extracts VM and image;

-   detects both automatically;

-   verifies PCA contains the integrated benchmark;

-   verifies the private evaluator directory;

-   contacts LM Studio;

-   selects Qwen 3.8 27B;

-   creates a completely isolated PCA `runtime.json`;

-   records the benchmark environment.

It does **not** use your normal `~\.pharo-ca` at all.

Then I'd run:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 -Mode Smoke
```

`Smoke` currently exercises five deliberately different cases, including a basic expression, code creation, Collections, API discovery, and Spec2. Default `-SkillModes both` means the skill-sensitive cases also get their paired preloaded-skill run.

The useful modes are:

-   `Prepare` --- setup/verify only, no LLM benchmark.

-   `Models` --- show LM Studio model IDs.

-   `Smoke` --- 5 tasks, suitable for the first Windows proof.

-   `Quick` --- 13 representative tasks spanning easy through difficulty 5.

-   `Task` --- exactly the task(s) supplied with `-Tasks`.

-   `Full` --- complete 51-task suite.

-   `Status` --- summarize the newest aggregate result.

-   `Clean` --- delete the entire generated `work\` tree.

For example, a specific difficult task:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 `
    -Mode Task `
    -Tasks "navigation-007-cache-invalidation" `
    -SkillModes normal
```

A representative run:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 `
    -Mode Quick `
    -SkillModes both
```

And eventually the complete benchmark:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 `
    -Mode Full `
    -SkillModes both `
    -TimeoutSeconds 1800
```

You can repeat a complete experiment to measure variance:

```
powershell.exe -ExecutionPolicy Bypass -File .\run-pca-benchmark.ps1 `
    -Mode Full `
    -SkillModes both `
    -Repeat 3
```

Afterwards:

```
.\run-pca-benchmark.ps1 -Mode Status
```

prints average scores for normal/preloaded runs, pass/partial/fail counts, paired skill delta, and problem tasks.

By default it also deletes the large disposable `worker.image`/`evaluator.image` files **after each complete suite** while retaining results, logs, manifests, journals and workspaces. Disable that when debugging:

```
-PruneRunImages:$false
```

And everything generated can finally be discarded with:

```
.\run-pca-benchmark.ps1 -Mode Clean
```

For the first Windows proof, I would now do exactly **`Models`  `Prepare`  `Smoke`**. If you paste me that output, we can fix any Windows-specific issue before spending hours on `Full`.
