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

- `read-only`
- `coding`
- `full`

A project can select one through `settings.json`:

```json
{
  "tools.profile": "coding"
}
```

Specific tools can also be allowed or excluded with `tools.allow` and `tools.exclude` arrays.

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
