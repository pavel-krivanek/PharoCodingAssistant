"Run a preloaded PCA MCP image as a stdio MCP server.
Load BaselineOfPharoCodingAssistant group #MCP once before using this script.
Environment variables:
  PCA_MCP_PROFILE          read-only | coding | full (default coding)
  PCA_MCP_WORKSPACE        optional workspace root
  PCA_MCP_TRUST_WORKSPACE  true to explicitly trust that workspace
  PCA_MCP_TOOL_TIMEOUT_MS  positive integer milliseconds (default 60000)
"
| env service profileName workspacePath trustWorkspace timeoutText timeout server workspace |

(Smalltalk globals includesKey: #PharoCAMCPServer) ifFalse: [
	Error signal: 'PCA MCP packages are not loaded. Load BaselineOfPharoCodingAssistant group MCP first.' ].

env := OSEnvironment current.
profileName := env at: 'PCA_MCP_PROFILE' ifAbsent: [ 'coding' ].
workspacePath := env at: 'PCA_MCP_WORKSPACE' ifAbsent: [ nil ].
trustWorkspace := (env at: 'PCA_MCP_TRUST_WORKSPACE' ifAbsent: [ 'false' ]) asLowercase = 'true'.
timeoutText := env at: 'PCA_MCP_TOOL_TIMEOUT_MS' ifAbsent: [ '60000' ].
timeout := [ timeoutText asInteger ]
	on: Error
	do: [ :error | Error signal: 'PCA_MCP_TOOL_TIMEOUT_MS must be a positive integer' ].
timeout > 0 ifFalse: [ Error signal: 'PCA_MCP_TOOL_TIMEOUT_MS must be positive' ].

service := PharoCAMCPService default
	profileNamed: profileName;
	toolTimeoutMilliseconds: timeout;
	yourself.
workspacePath ifNotNil: [
	workspace := PharoCAWorkspace rootedAt: workspacePath asFileReference.
	trustWorkspace ifTrue: [ workspace trust ].
	service workspace: workspace ].

server := PharoCAMCPServer on: service.
server serveStdio.
Smalltalk snapshot: false andQuit: true.
