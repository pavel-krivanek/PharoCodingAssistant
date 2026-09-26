"Run PCA as a dual-era Streamable HTTP tools server.
The endpoint is /mcp and supports handshake-era MCP 2025-03-26 as well as PCA's tools-only MCP 2026-07-28 path.
The same server can also be started directly from a Workspace in a running headful image; see README.
Load BaselineOfPharoCodingAssistant group #MCP once before using this script.
Environment variables:
  PCA_MCP_PROFILE          read-only | coding | full (default coding)
  PCA_MCP_WORKSPACE        optional workspace root
  PCA_MCP_TRUST_WORKSPACE  true to explicitly trust that workspace
  PCA_MCP_TOOL_TIMEOUT_MS  positive integer milliseconds (default 60000)
  PCA_MCP_HTTP_PORT        positive integer port (default 17081)
  PCA_MCP_HTTP_HOST        bind host/interface (default 127.0.0.1)
"
| env service profileName workspacePath trustWorkspace timeoutText timeout portText port host server workspace |

(Smalltalk globals includesKey: #PharoCAMCPHTTPServer) ifFalse: [
	Error signal: 'PCA MCP packages are not loaded. Load BaselineOfPharoCodingAssistant group MCP first.' ].

env := OSEnvironment current.
profileName := env at: 'PCA_MCP_PROFILE' ifAbsent: [ 'coding' ].
workspacePath := env at: 'PCA_MCP_WORKSPACE' ifAbsent: [ nil ].
trustWorkspace := (env at: 'PCA_MCP_TRUST_WORKSPACE' ifAbsent: [ 'false' ]) asLowercase = 'true'.
timeoutText := env at: 'PCA_MCP_TOOL_TIMEOUT_MS' ifAbsent: [ '60000' ].
portText := env at: 'PCA_MCP_HTTP_PORT' ifAbsent: [ '17081' ].
host := env at: 'PCA_MCP_HTTP_HOST' ifAbsent: [ '127.0.0.1' ].
timeout := [ timeoutText asInteger ] on: Error do: [ :error | Error signal: 'PCA_MCP_TOOL_TIMEOUT_MS must be a positive integer' ].
port := [ portText asInteger ] on: Error do: [ :error | Error signal: 'PCA_MCP_HTTP_PORT must be a positive integer' ].
timeout > 0 ifFalse: [ Error signal: 'PCA_MCP_TOOL_TIMEOUT_MS must be positive' ].
port > 0 ifFalse: [ Error signal: 'PCA_MCP_HTTP_PORT must be positive' ].

service := PharoCAMCPService default
	profileNamed: profileName;
	toolTimeoutMilliseconds: timeout;
	yourself.
workspacePath ifNotNil: [
	workspace := PharoCAWorkspace rootedAt: workspacePath asFileReference.
	trustWorkspace ifTrue: [ workspace trust ].
	service workspace: workspace ].

server := PharoCAMCPHTTPServer on: service.
server startOn: port host: host.
Stdio stderr nextPutAll: 'PCA MCP HTTP listening on ', server url; cr; flush.
[ server isRunning ] whileTrue: [ (Delay forSeconds: 1) wait ].
