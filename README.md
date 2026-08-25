# PharoCodingAssistant

PharoCodingAssistant is a coding-agent runtime that runs inside a live Pharo image. It combines:

- one or more LLM providers and models;
- one or more independently configured agents;
- a filesystem workspace plus access to the live Pharo image;
- structured tools for inspecting and changing Smalltalk code;
- durable conversations, checkpoints, change review and rollback metadata;
- a minimal browser UI served directly by Zinc over HTTP/WebSocket;
- project/global instructions, skills, templates and settings.

The browser is deliberately static HTML/CSS/JavaScript. There is no Node.js, npm, bundler, transpiler or frontend framework build step.

## Installation

PharoCodingAssistant is developed and validated with Pharo 14. The normal installation uses the Metacello baseline from the public repository:

```smalltalk
Metacello new
    baseline: 'PharoCodingAssistant';
    repository: 'github://pavel-krivanek/PharoCodingAssistant:master/src';
    load.
```

Repository: <https://github.com/pavel-krivanek/PharoCodingAssistant>

The default baseline group loads only the production `PharoCodingAssistant` package. For development, including the SUnit package:

```smalltalk
Metacello new
    baseline: 'PharoCodingAssistant';
    repository: 'github://pavel-krivanek/PharoCodingAssistant:master/src';
    load: 'Development'.
```

`Tests` is also available when only the test package in addition to the core is wanted.

The Metacello baseline loads Smalltalk code. The browser UI is deliberately kept as ordinary static files in the repository's `web/` directory, so a full web setup should also have a checkout of the repository available locally. The web server is then pointed at that directory. A headless/API-only setup does not need the `web/` files.

For example, after cloning the repository to a convenient local directory, load the baseline above and use that checkout's `web/` directory in `PharoCAWebServer`.

## Quick setup: discover the model from a local provider

This is the shortest practical setup for a local server such as llama.cpp, LM Studio, vLLM, or another server exposing the OpenAI-compatible `chat/completions` and `models` endpoints.

The example assumes:

- PharoCodingAssistant has been loaded with the baseline above;
- your coding project is in `C:\work\MyProject`;
- this repository is in `C:\work\PharoCodingAssistant`;
- the local model server listens on port `8080`;
- the model server accepts requests without authentication;
- this endpoint exposes one model. If it exposes several, see the next section and select the one you want explicitly.

```smalltalk
| workspace harness providers localModels webServer |

workspace := PharoCAWorkspace
    rootedAt: 'C:\work\MyProject' asFileReference.

harness := PharoCACodingHarness new
    workspace: workspace;
    yourself.

"Loads global/project resources and restores ~/.pharo-ca/runtime.json if it exists."
harness reloadResources.

providers := harness providerRegistry.
(providers includesProviderNamed: 'local') ifFalse: [
    providers
        registerOpenAICompatible: 'local'
        baseUrl: 'http://127.0.0.1:8080/v1/chat/completions'
        credentialName: 'local-api-key'
        timeout: 3600 ].

"GET /v1/models, create PharoCAModel objects, and register them against 'local'."
harness discoverModelsFromProviderNamed: 'local'.

localModels := harness modelRegistry modelsForProvider: 'local'.
localModels size = 1 ifFalse: [
    Error signal: 'Expected one local model; inspect localModels and select one explicitly' ].

harness setModelNamed: localModels first name forAgentId: 'default'.

"Persist provider/model/agent configuration for the next image start.
 Secrets themselves are never written to runtime.json."
harness saveRuntimeProfile.

webServer := PharoCAWebServer
    on: harness
    webRoot: 'C:\work\PharoCodingAssistant\web' asFileReference.

webServer start.
webServer url.
```

`webServer url` normally answers:

```text
http://127.0.0.1:17080
```

Open that URL in a browser. The server binds to loopback (`127.0.0.1`) by design.

To stop it:

```smalltalk
webServer stop.
```

To use another port:

```smalltalk
webServer startOn: 17081.
```

### If the provider exposes several models

Discovery fills the registry; selection is still explicit:

```smalltalk
| discovered localModels |

discovered := harness discoverModelsFromProviderNamed: 'local'.
localModels := harness modelRegistry modelsForProvider: 'local'.

localModels collect: [ :each | each name ].
"Choose one of the returned IDs:"
harness setModelNamed: 'the-model-id-returned-by-the-provider' forAgentId: 'default'.
```

`discoverModelsFromProviderNamed:` is safe to call again. It adds newly visible models and can fill numeric metadata that was previously unknown. It does **not** replace explicit context/output settings already present on a registered model. If a discovered ID is already registered against another provider, the result reports it under `conflicts` rather than silently changing ownership.

The returned summary contains `added`, `updated`, `unchanged`, `conflicts`, and `discoveredCount`.

### Override metadata after discovery

The standard OpenAI Models API guarantees model IDs but does not guarantee context-window or capability metadata. OpenAI-compatible local servers may expose more. llama.cpp, for example, includes model metadata in `/v1/models`; when numeric context metadata is present PharoCodingAssistant imports it. If the provider does not report a value, or you want to use a different effective runtime limit, set it explicitly:

```smalltalk
| model |
model := harness modelRegistry modelNamed: 'the-model-id-returned-by-the-provider'.
model
    contextSize: 262144;
    maximumOutputTokens: 16384;
    supportsReasoning: true;
    supportsReasoningStreaming: true.

harness saveRuntimeProfile.
```

Explicit values survive later discovery runs.

Discovery is intentionally conservative about behavioral capabilities. A generic OpenAI-compatible model-list response is enough to register the model ID, but it is **not** treated as proof that reasoning, reasoning streaming, usage streaming, image input, or parallel tool calls are supported. Those flags remain conservative unless the adapter can derive them from explicit provider metadata or you override the discovered `PharoCAModel` yourself. This prevents auto-discovery from enabling request shapes that an otherwise OpenAI-compatible server does not implement.

### Custom model-list endpoint

For normal OpenAI-compatible endpoints, a chat URL ending in `/v1/chat/completions` automatically maps to `/v1/models`. If a provider uses a non-standard listing URL, configure it explicitly:

```smalltalk
harness providerRegistry
    registerOpenAICompatible: 'special-local'
    baseUrl: 'http://127.0.0.1:9000/v1/chat/completions'
    modelListUrl: 'http://127.0.0.1:9000/custom/models'
    credentialName: 'special-key'
    timeout: 3600.

harness discoverModelsFromProviderNamed: 'special-local'.
```

The custom `modelListUrl` is persisted with the provider configuration.

### Test the agent without the web UI

The same harness can be used directly from Pharo:

```smalltalk
| run |
run := harness run: 'Inspect OrderedCollection and explain how #add: is implemented.'.
run answer.
```

`run:` blocks until the run finishes. For a non-blocking run use `start:`:

```smalltalk
| run |
run := harness start: 'Find the implementors of #asDictionary and summarize them.'.
run status.      "Initially #running"
run wait.
run answer.
```

## Direct Tonel loading (development fallback)

Metacello via the baseline is the preferred installation path. If you are developing an unpacked bundle or intentionally want to bypass Metacello, the production package can still be loaded directly with Pharo's installed Tonel reader:

```smalltalk
| src |
src := 'C:\work\PharoCodingAssistant\src' asFileReference.
(TonelReader on: src fileName: 'PharoCodingAssistant') version load.
```

For development/testing, load the test package too:

```smalltalk
(TonelReader on: src fileName: 'PharoCodingAssistant-Tests') version load.
```

The project is developed and validated with Pharo 14.

## Configuration model

PharoCodingAssistant keeps four concepts separate:

1. **Provider** — an API endpoint/protocol adapter, for example a local OpenAI-compatible endpoint or Anthropic.
2. **Model** — a provider-neutral model descriptor: model ID, context size, output limit and supported capabilities.
3. **Agent** — an independently running agent bound to a model/provider and its own session manager, reasoning effort and current sessions.
4. **Workspace** — the filesystem project on which tools operate, plus project-local instructions/settings/resources.

A model is registered against a provider ID. An agent selects a model; selecting the model also selects the provider registered for that model.

This separation is important when one Pharo image uses several endpoints or several agents at once.

## Providers

### OpenAI-compatible providers

Use `#registerOpenAICompatible:baseUrl:credentialName:timeout:` for any endpoint implementing the OpenAI-compatible streaming Chat Completions shape expected by the adapter.

```smalltalk
harness providerRegistry
    registerOpenAICompatible: 'local-fast'
    baseUrl: 'http://127.0.0.1:8080/v1/chat/completions'
    credentialName: 'local-fast-key'
    timeout: 3600.
```

A second endpoint can be registered independently:

```smalltalk
harness providerRegistry
    registerOpenAICompatible: 'local-large'
    baseUrl: 'http://127.0.0.1:8081/v1/chat/completions'
    credentialName: 'local-large-key'
    timeout: 3600.
```

The registry ID (`local-fast`, `local-large`) is the stable application identity. Both providers use the `openai-compatible` wire family.

For an OpenAI-hosted Chat Completions compatible endpoint, the same adapter can be configured with the hosted endpoint:

```smalltalk
harness providerRegistry
    registerOpenAICompatible: 'openai'
    baseUrl: 'https://api.openai.com/v1/chat/completions'
    credentialName: 'openai-api-key'
    timeout: 3600.
```

Discovery uses the exact API model identifiers returned by `/v1/models`; do not substitute a consumer-UI display name unless it is also an API model ID.

### Provider-driven model discovery

A provider may advertise model discovery through `PharoCALLMProvider>>supportsModelDiscovery`. The built-in OpenAI-compatible and Anthropic adapters support it.

```smalltalk
harness providerRegistry providerSupportsModelDiscoveryNamed: 'local'.
harness discoverModelsFromProviderNamed: 'local'.
```

For several configured endpoints:

```smalltalk
harness discoverModelsFromProvidersNamed: #('fast-local' 'review-local').
```

Each provider is queried independently and each returned model is bound to that provider ID. The registry deliberately does not auto-rebind a duplicate model ID from one provider to another; such IDs appear in the discovery result's `conflicts` collection.

The browser/external protocol exposes the same operation as `providers.discoverModels` with a `providerId` parameter.

### Anthropic

An Anthropic provider is built in under provider ID `anthropic` and uses:

```text
https://api.anthropic.com/v1/messages
```

Configure the credential mapping first, then discover the models currently available to the API key:

```smalltalk
harness providerRegistry credentialResolver
    map: 'anthropic-api-key'
    toEnvironmentVariable: 'ANTHROPIC_API_KEY'.

harness discoverModelsFromProviderNamed: 'anthropic'.
harness modelRegistry modelsForProvider: 'anthropic'.
```

Anthropic's Models API currently publishes `max_input_tokens` and `max_tokens`; discovery maps those to `contextSize` and `maximumOutputTokens` when present. The current Anthropic adapter does not translate the generic `reasoningEffort` field into Anthropic extended-thinking configuration, so discovered Anthropic models deliberately keep generic reasoning support disabled until that adapter is extended accordingly.

## Credentials

Credentials are resolved by `PharoCACredentialResolver`. Secret values are intentionally separate from the persisted runtime profile.

### Local server without authentication

Do nothing. The OpenAI-compatible adapter omits the `Authorization` header when the named credential resolves to `nil`.

### In-memory credential

Useful for an interactive image, but it must be supplied again after restarting the image:

```smalltalk
harness providerRegistry credentialResolver
    at: 'openai-api-key'
    put: 'your-secret-value'.
```

### Environment-variable credential

Recommended for persistent setups:

```smalltalk
harness providerRegistry credentialResolver
    map: 'openai-api-key'
    toEnvironmentVariable: 'OPENAI_API_KEY'.
```

For Anthropic:

```smalltalk
harness providerRegistry credentialResolver
    map: 'anthropic-api-key'
    toEnvironmentVariable: 'ANTHROPIC_API_KEY'.
```

Then make the environment variable available to the process that starts Pharo.

The mapping can be persisted with `harness saveRuntimeProfile`; the secret value is not persisted.

## Models

A `PharoCAModel` describes what the agent may safely assume about a model. Normally these objects are created by provider discovery; manual registration remains available for providers that cannot list models or when you need a fully explicit descriptor.

```smalltalk
| model |
model := PharoCAModel named: 'my-model-api-id'.
model
    contextSize: 262144;
    maximumOutputTokens: 16384;
    supportsTools: true;
    supportsParallelToolCalls: true;
    supportsReasoning: true;
    supportsReasoningStreaming: true;
    supportsUsageStreaming: true;
    supportsImages: false;
    supportsSystemMessages: true.

harness modelRegistry register: model provider: 'local'.
```

The fields mean:

- `name` — exact model identifier sent to the provider;
- `contextSize` — total context window used for budgeting and the web UI context-fill indicator;
- `maximumOutputTokens` — maximum output reservation advertised to the context builder;
- `supportsTools` — whether tool definitions/tool calls may be used;
- `supportsParallelToolCalls` — whether independent tool calls from one model turn may run concurrently;
- `supportsReasoning` — whether the generic reasoning-effort control is meaningful;
- `supportsReasoningStreaming` — whether reasoning deltas may be expected in the stream;
- `supportsUsageStreaming` — whether provider usage counters may arrive while streaming;
- `supportsImages` — whether image content can be sent;
- `supportsSystemMessages` — whether system messages are supported.

Do not blindly mark every capability `true`. The descriptor is a contract between the agent and the provider/model combination.

### Switching the default agent's model

```smalltalk
harness setModelNamed: 'my-model-api-id' forAgentId: 'default'.
```

In the browser, the same operation is available through the model selector and `/model` command.

## Multiple providers and multiple agents

One harness can host several configured agents. Each agent has an independent model/provider binding and independent current session.

The following example uses a fast local model as the default coding agent and a second, larger model on another endpoint as a reviewer.

```smalltalk
| workspace harness providers fastModels reviewModels reviewer webServer |

workspace := PharoCAWorkspace
    rootedAt: 'C:\work\MyProject' asFileReference.

harness := PharoCACodingHarness new
    workspace: workspace;
    yourself.

harness reloadResources.
providers := harness providerRegistry.

(providers includesProviderNamed: 'fast-local') ifFalse: [
    providers
        registerOpenAICompatible: 'fast-local'
        baseUrl: 'http://127.0.0.1:8080/v1/chat/completions'
        credentialName: 'fast-local-key'
        timeout: 3600 ].

(providers includesProviderNamed: 'review-local') ifFalse: [
    providers
        registerOpenAICompatible: 'review-local'
        baseUrl: 'http://127.0.0.1:8081/v1/chat/completions'
        credentialName: 'review-local-key'
        timeout: 3600 ].

"Each endpoint fills the model registry from its own /v1/models response."
harness discoverModelsFromProvidersNamed: #('fast-local' 'review-local').

fastModels := harness modelRegistry modelsForProvider: 'fast-local'.
reviewModels := harness modelRegistry modelsForProvider: 'review-local'.
fastModels size = 1 ifFalse: [ Error signal: 'Select a fast-local model explicitly' ].
reviewModels size = 1 ifFalse: [ Error signal: 'Select a review-local model explicitly' ].

harness setModelNamed: fastModels first name forAgentId: 'default'.

(harness agentManager registrations
    anySatisfy: [ :each | each identifier = 'reviewer' ])
        ifFalse: [
            reviewer := harness
                newAgentIdentifiedBy: 'reviewer'
                named: 'Reviewer'
                modelNamed: reviewModels first name ]
        ifTrue: [
            reviewer := harness agentNamed: 'reviewer'.
            harness setModelNamed: reviewModels first name forAgentId: 'reviewer' ].

reviewer reasoningEffort: #high.
harness agent reasoningEffort: #medium.

"Optional: make reviewer the initially selected/default runtime agent."
"harness agentManager defaultAgentId: 'reviewer'."

harness saveRuntimeProfile.

webServer := PharoCAWebServer
    on: harness
    webRoot: 'C:\work\PharoCodingAssistant\web' asFileReference.
webServer start.
```

The web UI discovers all registered agents and lets the user select an agent. Sessions are managed independently per agent.

### Agents using different provider families

A local OpenAI-compatible coding agent and an Anthropic reviewer can coexist in the same harness:

```smalltalk
| anthropicModels reviewer |

harness providerRegistry credentialResolver
    map: 'anthropic-api-key'
    toEnvironmentVariable: 'ANTHROPIC_API_KEY'.

harness discoverModelsFromProviderNamed: 'anthropic'.
anthropicModels := harness modelRegistry modelsForProvider: 'anthropic'.

"Choose the desired discovered model; this example uses the first one."
reviewer := harness
    newAgentIdentifiedBy: 'anthropic-reviewer'
    named: 'Anthropic reviewer'
    modelNamed: anthropicModels first name.

harness saveRuntimeProfile.
```

If the setup code can be executed repeatedly in the same image, guard agent creation as shown in the previous example to avoid duplicate identifiers.

## Reasoning effort

Each agent has its own reasoning-effort value:

```smalltalk
(harness agentNamed: 'default') reasoningEffort: #medium.
(harness agentNamed: 'reviewer') reasoningEffort: #high.
```

Supported UI values are:

- provider default (`nil` internally);
- `#none`;
- `#low`;
- `#medium`;
- `#high`;
- `#max`.

The request field is only emitted when the selected model advertises `supportsReasoning` and the agent's effort is not `nil`.

Use `nil` to omit the generic reasoning-effort field and let the provider choose its default:

```smalltalk
harness agent reasoningEffort: nil.
```

The browser exposes the same control, and `/reasoning` provides command-line-style access.

## Persistent runtime configuration

`PharoCACodingHarness` persists reconstructible runtime configuration in:

```text
~/.pharo-ca/runtime.json
```

when using the default `PharoCAResourceLoader`.

Save it after configuring providers/models/agents:

```smalltalk
harness saveRuntimeProfile.
```

A fresh harness restores it automatically on its first `reloadResources`:

```smalltalk
workspace := PharoCAWorkspace rootedAt: 'C:\work\MyProject' asFileReference.
harness := PharoCACodingHarness new workspace: workspace; yourself.
harness reloadResources.
```

The runtime profile persists:

- reconstructible custom OpenAI-compatible providers;
- registered models for persistable providers;
- agents and their selected models;
- default agent ID;
- per-agent reasoning effort;
- credential-to-environment-variable mappings.

It deliberately does **not** persist:

- secret credential values;
- arbitrary executable provider factory blocks;
- non-reconstructible custom provider implementations.

If you register a custom provider with `#register:factory:`, that provider is intentionally image-local unless you reconstruct it yourself on startup.

## Global and project resources

`harness reloadResources` loads two resource layers.

### Global resources

Default root:

```text
~/.pharo-ca/
```

Recognized files/directories include:

```text
~/.pharo-ca/
  runtime.json
  settings.json
  system.md
  instructions/
    *.md
  skills/
    *.md
  templates/
    *.md
  extensions.json
  sessions/
```

Global resources are trusted.

### Project resources

For workspace `C:\work\MyProject`, project-local resources are discovered from:

```text
C:\work\MyProject\AGENTS.md
C:\work\MyProject\.pharo-ca\settings.json
C:\work\MyProject\.pharo-ca\system.md
C:\work\MyProject\.pharo-ca\instructions\*.md
C:\work\MyProject\.pharo-ca\skills\*.md
C:\work\MyProject\.pharo-ca\templates\*.md
C:\work\MyProject\.pharo-ca\extensions.json
```

`AGENTS.md` is discovered as project instruction text. Project settings and executable extensions are gated by workspace trust.

To trust the current workspace and reload:

```smalltalk
harness trustWorkspace.
```

To revoke trust and reload:

```smalltalk
harness untrustWorkspace.
```

## Settings

`settings.json` may be a plain JSON object or the versioned settings envelope understood by `PharoCASettingsPersistence`.

A simple project `.pharo-ca/settings.json` can look like:

```json
{
  "temperature": 0.0,
  "maxIterations": 50,
  "toolTimeoutMilliseconds": 60000,
  "reasoningEffort": "medium",
  "context.reservedOutputTokens": 8192,
  "context.safetyMarginTokens": 512,
  "context.compactionEnabled": true,
  "context.summarizationEnabled": false,
  "skill.discoveryCharacterBudget": 4000,
  "tools.profile": "coding"
}
```

Known settings are:

- `maxIterations`
- `timeout`
- `temperature`
- `toolTimeoutMilliseconds`
- `reasoningEffort`
- `systemPrompt`
- `context.reservedOutputTokens`
- `context.safetyMarginTokens`
- `context.compactionEnabled`
- `context.summarizationEnabled`
- `context.overflowRecoveryAttempts`
- `context.overflowSafetyMarginIncrementTokens`
- `skill.discoveryCharacterBudget`
- `model`
- `tools.profile`
- `tools.allow`
- `tools.exclude`

Project settings take effect only for a trusted workspace. Programmatic harness setting overrides have the highest precedence.

Example override:

```smalltalk
harness settingOverrideAt: 'temperature' put: 0.1.
harness reloadResources.
```

## Tool profiles

The settings schema recognizes these tool profiles:

- `read-only` — inspection and session-management tools only;
- `coding` — the normal coding-agent profile: inspection, structured coding, testing, refactoring, and Pharo evaluation;
- `full` — `coding` plus debugging, destructive, and process-control capabilities.

Since iteration 055, Pharo evaluation is deliberately part of the normal `coding` profile. A coding agent must be able to execute expressions/DoIts while investigating and validating live-image behavior. Use `read-only` when evaluation must be prohibited, and `tools.exclude` when only selected evaluation tools should be removed.

A project can select one through `settings.json`:

```json
{
  "tools.profile": "coding"
}
```

Specific tools can also be allowed or excluded with `tools.allow` and `tools.exclude` arrays.

The default system prompt gives the model a compact map of the available families — browse/search, evaluation, edit/format/compile, tests/quality, debugging/profiling, refactoring, Tonel/Git/workspace operations, Transcript and screenshots — and tells it to use `tool_search` / `tool_enable` for exact names and lazy packs. It intentionally does not duplicate the full catalog in the prompt.

Iteration 057 adds the default-core `format_code` tool. It parses method or expression source with Pharo's native `OCParser` and returns `formattedCode` without changing the image. Formatted text is cursor-paginated, so large methods remain bounded.

### Tool packs and lazy discovery

The tool registry can contain more tools than are advertised to the model on every request. The original tool set remains in the default `core` pack, while larger/newer families can be activated lazily per durable session. The `catalog` pack is always active and contains:

- `tool_search` — search the complete registered tool catalog, including inactive packs; an optional `task` hint produces deterministic task-aware ranking and every row reports `rankScore`, current `profile`, and `availabilityReason`;
- `tool_enable` — activate a pack for the current session;
- `tool_disable` — deactivate a pack for the current session (the `catalog` pack itself cannot be disabled).

Pack activation is session-scoped and persisted with the session. It changes the schemas advertised on the **next model request**, including the next round of the same running agent. It does not bypass the selected tool profile or explicit `tools.allow`/`tools.exclude` policy.

Iteration 055 also put an explicit context budget around this catalog architecture. After iteration 058 the supplied image has 137 registered tools whose parameter schemas total 25,328 serialized JSON characters before lazy-pack filtering, while the default active surface remains exactly 25 definitions (8,670 serialized definition characters). Regression tests cap an individual parameter schema at 1,000 characters and the default advertised surface at 25 tools / 10,000 serialized characters; large result families must continue to use pagination, caller limits, handles, artifacts, or separate detail tools.

The lazy `browse` pack contains the Pharo-native browsing and structural-search tools. Iteration 048 introduced the pack and iteration 049 expanded it substantially:

- `get_method` — exact local method source plus package/tag/protocol/pragma metadata;
- `get_class_summary` — superclass, package/tag, slots, class variables, traits and method/subclass counts;
- `list_package_tags` — real Pharo package tags and class counts without mutating package organization;
- `search_classes` — class-name search with exact/prefix/substring and package/tag filters;
- `search_selectors` — implemented-selector search with package/tag/class filters and implementation counts;
- `search_method_source` — paginated live-image source search returning compact snippets and metadata; class/package/tag filters narrow the candidate methods *before* source scanning, so scoped searches do not traverse source for the complete image;
- `find_references` — references to an installed Smalltalk global binding;
- `find_slot_accesses` — structural reads/writes/accesses of a named instance slot;
- `find_pragmas` — exact pragma occurrence search with compact argument rendering;
- `get_package_dependencies` — direct package dependencies derived from superclass/trait relations and referenced classes;
- `get_method_ast` — paginated flat preorder projection of the real Opal AST;
- `search_ast` — structural code search using Pharo's native `OCParseTreeSearcher` pattern language, including native pattern-capture bindings;
- `ast_rewrite_preview` — parses a fresh copy of one installed method and previews an `OCParseTreeRewriter` expression/method rewrite without mutating live code.

The agent can therefore discover a capability with `tool_search`, enable `browse`, and use these tools on the next model request — including the next round of the same run — without carrying every future tool schema in every ordinary request.

#### `quality` pack

Iteration 058 adds a lazy read-only code-quality pack backed by the QualityAssistant/Smalllint implementation already present in the supported Pharo 14 image:

- `quality_rules` — lists the enabled native `ReRuleManager` rules with deterministic pagination and optional name/class, group, severity and rationale filtering;
- `quality_check` — runs `ReCriticEngine` on an installed method, class, or bounded package scope and returns rule/group/severity/title plus source intervals where the native critique supplies one;
- `quality_results` — pages a short-lived saved analysis without rerunning the critique engine.

Enable it only when useful:

```text
tool_enable pack:"quality"
quality_rules query:"long method" severity:"warning"
quality_check scope:"method" className:"MyClass" selector:"calculate"
```

Class/package analysis is bounded by `maxEntities` (maximum 500), stored findings by `maxFindings` (maximum 1,000), and each returned page by `limit` (maximum 100). Full critique descriptions are opt-in because rule rationales can be verbose. When more saved findings exist, the first result contains an expiring session-local `analysisHandle`; `quality_results` uses that handle so pagination never reruns QualityAssistant. Package scans are deterministic by class/selector order, cancellation is checked between entities, and native rule exceptions are isolated into bounded `analysisErrors`. The tool uses the image's current QualityAssistant rule/manifests rather than duplicating lint logic in the assistant.

Iteration 058 also replaces the deprecated `Smalltalk os environment` credential lookup with Pharo 14's `OSEnvironment current`, removing the deprecation emitted by the full test suite.


Iteration 050 adds three additional lazy packs for stateful runtime work. They use session-scoped transient stores, so live object handles and detailed test-run records do not survive image/session restoration.

#### `execution` pack

The `execution` pack provides safer code checking plus explicit live-object interaction:

- `check_code` — parses/compiles a Pharo expression with Opal without executing it; returns validity, AST class/node count, and compiler notices;
- `evaluate_expression` — evaluates with `OpalEvaluator`, returns elapsed time, bounded `printString`, result class, and an opaque `obj-N` handle;
- `object_summary` — side-effect-conscious class/slot summary for a live handle;
- `object_slots` — paginated slot inspection; non-immediate slot values receive child handles only when their page is requested;
- `object_send` — sends a selector to a live handle, with JSON literal arguments or `{"handle":"obj-N"}` references;
- `object_release` — releases a transient handle explicitly.

Object handles are isolated by durable assistant session and have a sliding TTL. They are deliberately **not persisted**: reopening an old conversation cannot resurrect arbitrary object identities from an earlier image lifetime.

`check_code`, `object_summary`, `object_slots`, and `object_release` use inspection capability, whereas `evaluate_expression` and `object_send` require the `evaluation` capability and execute exclusively. The normal `coding` profile includes `evaluation` as of iteration 055, so enabling this pack makes those execution tools callable for a coding agent. `read-only` still blocks them, and explicit `tools.exclude` policy remains authoritative.

A typical exploratory sequence is:

```text
tool_enable pack:"execution"
check_code code:"OrderedCollection new add: 1; yourself"
evaluate_expression code:"OrderedCollection with: 1 with: 2"
object_slots handle:"obj-1" limit:20
object_send handle:"obj-1" selector:"size"
object_release handle:"obj-1"
```

#### `testing` pack

The richer SUnit tools keep large defect information out of the initial tool response:

- `test_discover` — discovers tests by method/class/package/tag scope;
- `run_tests` — executes method, class, package, tag, or explicit-selection scopes and returns a compact `test-run-N` identifier and summary;
- `test_results` — retrieves deterministically ordered, paginated per-test status rows;
- `test_failure` — retrieves the original captured exception class/message and a bounded signaler stack for one failure/error;
- `test_rerun` — reruns the exact scope/specification of a previous test run;
- `test_coverage` — runs an explicit SUnit scope under Pharo's native `CoverageCollector` and returns bounded method/sequence coverage totals plus a caller-limited uncovered-method list.

`run_tests` is deterministic unless shuffling is explicitly requested. A supplied shuffle seed is retained in the test-run specification and reused by `test_rerun`. Execution performs cooperative cancellation checks between individual SUnit tests rather than forcefully terminating arbitrary Pharo processes. Test-run records are transient and session-scoped.

`test_coverage` uses the same test scopes but has a separate explicit coverage scope (`method`, `class`, `package`, `tag`, or `selection`). Coverage instrumentation is capped at 2,000 methods, explicit selections at 500 methods, and uncovered details at the requested `detailLimit`; it does not rerun the test suite merely to paginate additional coverage rows.

#### `runtime` pack

Transcript access is exposed through a single image-level announcement bridge and bounded ring buffer:

- `transcript_status` — reports the current Transcript implementation and capture-buffer status;
- `transcript_tail` — returns entries after a monotonically increasing sequence cursor, with a bounded limit;
- `transcript_clear` — clears both the Pharo Transcript and the assistant capture buffer;
- `profile_expression` — evaluates an expression under Pharo's native `TimeProfiler` / `MessageTally` sampling profiler and returns a bounded list of leaf/self-time hotspots plus the normal transient result-object handle.

Interactive Transcript implementations announce entries and can therefore be tailed without polling the UI. In a headless image `Transcript` may be `NonInteractiveTranscript`, which writes to stdio and does not provide the same announcement stream; `transcript_status` reports the actual capture capability instead of claiming completeness. `profile_expression` requires the normal `evaluation` capability, is exclusive like other evaluation tools, and should be interpreted as sampling diagnostics rather than a deterministic microbenchmark.


Iteration 051 adds two more lazy packs for live debugging and process control.

#### `debug` pack

The debugger pack is based on Pharo 14's real `SindarinDebugger`, `DebugSession`, and DebugPoint APIs rather than debugger-window automation:

- `debug_start` — creates a new scriptable debugger for a Pharo expression and stops before the first executable expression;
- `debug_attach_process` — attaches Sindarin to a process handle after applying the protected-process guards;
- `debug_status` — current debugger state/source location;
- `debug_stack` / `debug_frame` — paginated stack plus receiver, temporaries and exact method source;
- `debug_step` — `into`, `over`, `through`, `bytecode`, `methodEntry`, and `return` modes;
- `debug_continue` — cooperative continue until completion or an about-to-be-signalled exception, with cancellation/timeout checks between steps;
- `debug_evaluate` — evaluates in an explicitly selected frame and returns a normal transient `obj-N` result handle;
- `debug_restart` — restarts sessions created by `debug_start`;
- `debug_resume` / `debug_terminate` — explicitly release a debugger by resuming or terminating its process;
- `debug_points`, `debug_set_breakpoint`, `debug_set_watchpoint`, `debug_remove_point` — native `BreakDebugPoint`/`WatchDebugPoint` control.

Debugger handles (`debug-N`) are **strong and session-scoped**. They do not expire while an agent is reasoning because silently expiring a suspended execution would be unsafe. A durable session does not serialize these runtime handles. Session cleanup terminates executions owned by `debug_start`, removes assistant-installed DebugPoints, and releases runtime references. An attached external process is not silently terminated on cleanup.

Breakpoints use the same preorder AST node indexes returned by `get_method_ast`. They can be class-wide or scoped to an existing compatible `obj-N` receiver. Watchpoints can likewise be class-wide or object-scoped and support `read`, `write`, or `all` access. Assistant-created breakpoints/watchpoints can carry a Pharo DebugPoint condition, one-shot behavior, hit-count behavior, and (for watchpoints) a bounded history limit. Point summaries expose these behaviors and only a small recent-history preview. Only DebugPoints created by the current assistant session receive removable `point-N` handles; pre-existing user DebugPoints are visible but are not made removable through this API.

Example:

```text
tool_enable pack:"debug"
debug_start code:"| x | x := 1. x + 2"
debug_step debugHandle:"debug-1" kind:"into"
debug_frame debugHandle:"debug-1" frameIndex:1
debug_evaluate debugHandle:"debug-1" frameIndex:1 code:"x"
debug_continue debugHandle:"debug-1"
debug_resume debugHandle:"debug-1"
```

The normal `coding` tool profile does not authorize debugger execution. The `full` profile adds the `debugging` capability; destructive termination still uses the separate `destructive` capability.

#### `process` pack

The process pack operates on Pharo `Process` objects and `ProcessorScheduler`, not operating-system subprocesses:

- `process_list` — paginated live process inventory with strong `process-N` handles;
- `process_stack` — bounded/paginated suspended-context stack snapshot;
- `process_cpu_sample` — bounded CPU sampling through `ProcessorScheduler>>tallyCPUUsageFor:every:`;
- `process_suspend` / `process_resume`;
- `process_set_priority`;
- `process_terminate` — destructive;
- `process_debug` — bridge from a process handle into the Sindarin debugger.

Process handles are strong for the assistant session but **own no process lifetime**: merely listing a process never terminates or resumes it during cleanup. Mutating process tools reject protected processes, including the currently active execution process, high-priority system processes, and recognized Zinc/WebSocket/PharoCA/Morphic/UI/timer infrastructure. `process_terminate` additionally requires the `destructive` capability.

The existing `workspace_run_process` tool remains separate: it launches an operating-system command in the filesystem workspace, whereas this `process` pack controls Smalltalk processes inside the running Pharo image.

### Native refactoring pack

Iteration 052 adds the lazy `refactoring` pack. These tools use Pharo 14's actual `Re*`/`RB*` refactoring engine and `ReChangeManager`; they do not implement semantic refactorings through textual source replacement. The `coding` and `full` profiles include the separate `refactoring` capability.

Every named refactoring tool is a **preview operation**. It runs the native preconditions, generates the native change model, returns a compact bounded preview, and stores a strong session-scoped `refactor-N` handle. Preview creation never mutates the image. Large plans can be inspected with `refactor_preview_details`.

The pack contains:

- `refactor_rename_class`;
- `refactor_rename_method`;
- `refactor_rename_instance_variable`;
- `refactor_rename_local` for an argument or temporary in one method;
- `refactor_rename_package`;
- `refactor_extract_method`;
- `refactor_extract_temporary`;
- `refactor_inline_method`;
- `refactor_move_method`;
- `refactor_pull_up_method`;
- `refactor_push_down_method`;
- `refactor_add_parameter`;
- `refactor_remove_parameter`;
- `refactor_preview_details`;
- `refactor_apply`;
- `refactor_discard`.

A typical flow is:

```text
tool_enable pack:"refactoring"
refactor_rename_method className:"MyClass" selector:"oldName:" newSelector:"newName:"
refactor_preview_details refactorHandle:"refactor-1" limit:20
refactor_apply refactorHandle:"refactor-1"
```

`refactor_apply` does not trust the stored preview blindly. It rebuilds the same native refactoring from the original normalized arguments, regenerates the native changes against the **current image**, and compares a deterministic SHA-256 signature of the resulting plan with the preview signature. A native precondition failure or changed plan returns `status:"stale"` and performs no mutation. The verified native `ReAbstractTransformation>>performChanges` path then applies the already-generated `changes` through `ReChangeManager`; there is no independent second plan between signature validation and mutation.

Preview handles are one-shot after successful apply and may be explicitly released with `refactor_discard`. They are runtime handles only and are never serialized into durable sessions. Native `RBRefactoringWarning` conditions are captured as warning strings rather than allowed to open/block an interactive UI. Native `RBRefactoringError` precondition failures are returned as structured preview results.

Applied refactorings create one semantic `refactoringApplied` entry in the assistant Changes journal. Because the native refactoring may span many methods/classes and the journal currently records a compact semantic summary rather than a complete inverse native change graph, its rollback classification is deliberately **opaque** rather than pretending automatic rollback is safe. Checkpoints remain the appropriate higher-level recovery mechanism.


### Tonel and Iceberg/Git packs

Iteration 053 adds two lazy source/repository packs. Enable them only when needed, so the normal always-exposed tool catalog stays compact:

```text
tool_enable pack:"tonel"
tool_enable pack:"iceberg"
```

The `tonel` pack uses Pharo's installed `TonelParser` and `TonelWriter`. It can parse or validate bounded Tonel payloads, serialize/export live classes and packages, and import a package through an explicit preview/apply lifecycle:

- `tonel_parse`;
- `tonel_validate_package`;
- `tonel_serialize_class`;
- `tonel_export_class` / `tonel_export_package`;
- `tonel_import_preview` / `tonel_import_apply`.

Import preview returns a transient session-scoped `tonel-import-N` handle and never changes the image. Apply rechecks the current package snapshot first; if the image changed since preview it returns a stale result instead of applying an obsolete patch. A successful handle is one-shot. The payload API accepts Tonel source, not arbitrary filesystem destinations; use the workspace file tools when actual path-level I/O is required.

The `iceberg` pack works with repositories registered in the live Pharo image:

- discovery/read: `iceberg_list_repositories`, `iceberg_repository_info`, `iceberg_status`, `iceberg_diff`, `iceberg_log`, `iceberg_commit_info`, `iceberg_branches`, `iceberg_remotes`, `iceberg_packages`;
- repository mutations: `iceberg_commit`, `iceberg_fetch`, `iceberg_pull`, `iceberg_push`, `iceberg_create_branch`, `iceberg_switch`, `iceberg_add_remote`, `iceberg_remove_remote`;
- package mutations: `iceberg_load_package`, `iceberg_unload_package`, `iceberg_discard_changes`;
- repository setup: `iceberg_clone`, `iceberg_add_local_repository`.

Normal mutations require the `coding` capability and are serialized as exclusive mutations. `iceberg_discard_changes` additionally requires the separate `destructive` capability, so it is not available through a normal coding profile. Pull is fast-forward-only and switch refuses dirty live packages rather than silently losing image-side edits.

#### Git executable requirement and Pharo 14 compatibility boundary

The supplied Pharo 14 image has a libgit/ThreadedFFI stack-safety problem on sufficiently deep same-thread call paths: native diff/commit/checkout/transport can segfault the VM depending on the remaining space in an 8 KB Smalltalk stack page. For that reason the 053 mutation/transport tools intentionally execute deep Git operations through the existing bounded OS-process runner and the system `git` executable, then use Tonel/Monticello to synchronize changed packages with the live image. Git commands are cancellation-aware, time-bounded and output-bounded.

Therefore **`git` must be available on `PATH` for Iceberg mutation/transport tools**. Read-only Iceberg inspection continues to use the verified native model/path where safe. Do not replace this boundary with direct `LGitDiff`/Iceberg commit/transport calls merely because a shallow interactive experiment succeeds; the failure is caller-stack-depth dependent.

This does not replace the existing workspace filesystem-Git tools. Those remain the direct repository/file-control family; the `iceberg` tools add Pharo-specific knowledge of registered Iceberg repositories and live packages.

A representative flow is:

```text
tool_enable pack:"iceberg"
iceberg_list_repositories limit:20
iceberg_status repository:"MyProject" limit:50
iceberg_commit repository:"MyProject" message:"Implement parser fix"
iceberg_push repository:"MyProject" remote:"origin"
```

### Artifact and UI screenshot pack

Iteration 054 adds an ephemeral binary artifact store and a lazy `ui` pack:

```text
tool_enable pack:"ui"
ui_list_windows limit:20
ui_screenshot target:"window" handle:"obj-1"
```

`ui_screenshot` can capture `world`, a listed `window`, an arbitrary Morph object handle, or a bounded rectangle in World coordinates. It renders through Morphic and encodes PNG directly in memory. The textual tool result contains only a compact artifact descriptor; image bytes are kept in the environment-scoped `PharoCAArtifactStore` and served to the local browser at `/artifacts/<artifactId>`. Default storage is bounded by entry count, per-artifact bytes, total bytes and a fixed lifetime, so repeated screenshots cannot grow the image indefinitely.

The static web UI recognizes image artifact descriptors and shows them inline in the corresponding tool row. No screenshot base64 crosses the normal WebSocket/tool-result path and no frontend build dependency is introduced.

### Direct method editing

Iteration 056 also fills two small core editing gaps. `remove_method` deletes one locally defined instance- or class-side method and records a checkpoint-rollbackable semantic method change; inherited selectors are rejected. `set_method_protocol` uses Pharo's native `Behavior>>classify:under:` to move an existing method to another protocol/category without recompiling its source. Both are `coding`/`exclusiveMutation` tools, and protocol-only changes are visible in change review as well as rollbackable.


Canonical LLM content also has a provider-neutral `imageArtifact` part. Since iteration 056, an image-capable model can consume an image artifact on the next round, but resolution is deliberately late: durable conversation state keeps only the opaque descriptor and the provider adapter reads/encodes bytes only while building the outgoing request. Automatic feedback accepts only a live PNG/JPEG/GIF/WebP artifact owned by the exact tool call (and current run/session), with fixed count and byte ceilings; text-only models, expired artifacts, unsupported MIME types, and oversized images degrade to compact textual diagnostics. Base64/data URLs therefore never enter ordinary tool JSON, durable sessions, run events, or request telemetry. OpenAI-compatible Chat Completions emits all consecutive textual tool results first and then a synthetic multimodal user image message; Anthropic keeps image blocks nested in the corresponding `tool_result` content.

## Skills, instructions and templates

### Instructions

Markdown files under `instructions/` are loaded as instruction sources. `system.md` is a special system-level source. Project `AGENTS.md` is also loaded as an instruction source.

### Skills

Each `skills/*.md` file becomes a named skill. The filename without `.md` is the skill name. The first non-empty Markdown line is used as the short description when possible; the complete file is the lazily activated skill body.

In the browser/command interface:

```text
/skills
```

lists available skills and their active state for the selected agent/session.

### Prompt templates

Each `templates/*.md` file becomes a prompt template. Use:

```text
/templates
```

to list them in the command interface.

## Sessions

Sessions are durable by default and stored under the global session repository (`~/.pharo-ca/sessions` with the default resource loader).

Typical Smalltalk operations:

```smalltalk
harness newSession.
harness newSessionNamed: 'Refactor collections'.
harness continueMostRecent.
harness renameCurrentSession: 'Better name'.
harness forkCurrentSessionNamed: 'Alternative approach'.
```

Each configured agent has its own current-session manager, although all use the harness session repository.

The browser provides session creation/resume and a conversation tree. Conversation names are derived from the first words of the first real prompt unless explicitly named.

## Web UI

The web application is served from the repository's `web/` directory:

```text
web/
  index.html
  app.js
  assets/
```

`PharoCAWebServer` uses Zinc only:

- static HTTP for HTML/JavaScript/assets;
- RFC 6455 WebSocket at `/ws` for the application protocol;
- loopback binding by default;
- default port `17080`.

The UI includes, among other things:

- multiple agents/models;
- slash-command completion;
- streamed assistant text, reasoning and tool calls in chronological order;
- live steering from the normal composer while a run is active (`Send` becomes `Steer`);
- queued follow-up messages for the distinct "finish this turn, then continue" behavior;
- compact expandable tool/reasoning traces;
- context occupancy and token telemetry;
- tokens/second and TTFT when data are available;
- reasoning-effort control;
- live Changes and conversation-tree projections;
- checkpoints/change review;
- light/dark/system theme switching;
- small `i` actions that open live Pharo Inspectors for supported entities when the image is interactive.

## Useful slash commands

The current built-in command set includes:

```text
/help
/status
/sessions
/new [name]
/continue
/templates
/models
/model [modelId]
/skills
/reasoning [provider-default|none|low|medium|high|max]
/checkpoint [label]
/checkpoints
```

The root `/` completion is queried from the server rather than being hard-coded in the browser.

## Context and token telemetry

For useful context-fill information, configure `PharoCAModel>>contextSize:` accurately.

The UI distinguishes:

- estimated input/context occupancy (`~` prefix when estimated);
- provider-reported prompt/completion/reasoning token usage when available;
- time to first token;
- completion tokens per second;
- model-call count and context-compaction/omission information.

Provider-reported usage is authoritative when available. The agent does not pretend an estimate is an exact provider token count.

## Changing models at runtime

Smalltalk:

```smalltalk
harness setModelNamed: 'review-model' forAgentId: 'default'.
```

Browser command:

```text
/model review-model
```

The model must already be registered in `harness modelRegistry`. Switching a model also switches the agent to the provider associated with that model.

## Inspecting the current runtime

Useful objects to inspect directly in Pharo:

```smalltalk
harness runtime.
harness providerRegistry.
harness modelRegistry.
harness agentManager.
harness resources.
harness sessionManager.
harness asDictionary.
```

The web UI's `i` links resolve typed identities back to live objects and open a normal Pharo Inspector. They do not expose a remote arbitrary-Smalltalk-evaluation endpoint.

## Diagnostics and troubleshooting

### The web page loads but requests fail

Check the selected provider/model:

```smalltalk
harness agent provider providerId.
harness agent model name.
harness providerRegistry asArray.
harness modelRegistry asArray.
```

For an OpenAI-compatible endpoint, confirm that the configured URL includes the full Chat Completions path expected by your server, for example:

```text
http://127.0.0.1:8080/v1/chat/completions
```

### Missing credential

Inspect only credential **names/mappings**, not secret values:

```smalltalk
harness providerRegistry credentialResolver descriptionDictionary.
```

For Anthropic, a missing credential is an error at the transport boundary. For the OpenAI-compatible adapter, a missing credential simply means no `Authorization` header is emitted.

### `/model` has no expected model

First try discovery for the provider, then verify the model is registered:

```smalltalk
harness discoverModelsFromProviderNamed: 'local'.
```

Verify the resulting registry:

```smalltalk
harness modelRegistry modelIdentifiers.
```

and that its provider exists:

```smalltalk
harness modelRegistry providerIdentifierForModelNamed: 'my-model-api-id'.
harness providerRegistry providerIdentifiers.
```

### Project settings seem ignored

Project settings are trust-gated. Check:

```smalltalk
workspace trusted.
harness resources diagnostics.
```

Then, if appropriate:

```smalltalk
harness trustWorkspace.
```

### Configuration changed but the agent still uses old resources

Reload resources:

```smalltalk
harness reloadResources.
```

Remember that the runtime profile is loaded once per harness. A new harness will restore the persisted runtime profile during its first `reloadResources`.

### Wrong context percentage

Set the actual model context size:

```smalltalk
(harness modelRegistry modelNamed: 'my-model-api-id')
    contextSize: 131072.
```

Then save the runtime profile if the change should survive restart:

```smalltalk
harness saveRuntimeProfile.
```


## Package organization

`PharoCodingAssistant` intentionally remains a single production package for simple loading, but its classes are organized with Pharo **class tags**. In the System Browser the package is therefore split by responsibility instead of appearing as one flat list.

| Tag | Responsibility |
| --- | --- |
| `Core` | agent/run orchestration and compatibility facade |
| `Artifacts` | bounded ephemeral binary artifacts and metadata |
| `Runtime` | configured agents and persisted runtime control plane |
| `LLM` | provider protocol, providers, models, streaming and credentials |
| `Context` | context construction, compaction and token estimation |
| `Sessions` | durable conversations, entries, repositories and migration |
| `Changes` | change journal, review, checkpoints and rollback support |
| `Protocol` | external command/protocol surface and JSONL adapter |
| `Adapters` | headless/UI-facing projections and subscriptions |
| `Instructions` / `Skills` / `Extensions` | agent resource and extension mechanisms |
| `Tools` | generic tool contracts, invocation, scheduling and result handling |
| `Tools-Pharo` | tools that inspect or mutate the live Pharo image |
| `Tools-UI` | Morphic window and screenshot tools |
| `Tools-Workspace` | filesystem, process and repository workspace tools |
| `Workspace` | workspace, settings, resources, trust and harness support |
| `UI` | Morphic capture/UI-process boundary |
| `Web` | Zinc HTTP/WebSocket server |
| `Observability` | run telemetry |
| `Environment` | execution environment abstraction |

The test package is tagged in the same style (`Core`, `LLM`, `Protocol`, `Tools`, `Tools-Workspace`, `Web`, and so on), with additional `Fixtures`, `Support`, and `Contracts` tags for test-only code.

When adding a production class, assign a real package tag rather than leaving it in `Uncategorized`. The test suite contains a package-organization contract that fails if production classes drift back into the root tag.

## Development and tests

Load both Tonel packages, then run the test package with the normal Pharo test runner. The progress/testing/validation material generated during development is kept under `doc-progress/` in development bundles and is intentionally listed in `.gitignore`.

Production code is under:

```text
src/PharoCodingAssistant/
```

Tests are under:

```text
src/PharoCodingAssistant-Tests/
```

The browser is under:

```text
web/
```

## Minimal startup after configuration has been persisted

After the first setup has created `~/.pharo-ca/runtime.json`, startup can be as small as:

```smalltalk
| workspace harness webServer |

workspace := PharoCAWorkspace
    rootedAt: 'C:\work\MyProject' asFileReference.

harness := PharoCACodingHarness new
    workspace: workspace;
    yourself.

harness reloadResources.

webServer := PharoCAWebServer
    on: harness
    webRoot: 'C:\work\PharoCodingAssistant\web' asFileReference.

webServer start.
webServer url.
```

This is the recommended steady-state startup shape: configure providers/models/agents once, save the runtime profile, then let `reloadResources` restore it on subsequent starts.

### Source-search runtime note

Image-wide `search_method_source` searches only retrievable source text (`CompiledMethod>>sourceCodeOrNil`). It deliberately skips methods without real source instead of invoking Pharo's `codeForNoSource` reconstruction path. Pagination cursor/limit validation also happens before image-wide traversal, so invalid continuation cursors fail without rescanning the image.
