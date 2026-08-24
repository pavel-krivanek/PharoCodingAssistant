"Abstract base for tools operating on the explicitly configured coding workspace."
Class {
	#name : 'PharoCAWorkspaceTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Workspace'
}

{ #category : 'definition' }
PharoCAWorkspaceTool class >> requiresWorkspace [ ^ true ]

{ #category : 'workspace' }
PharoCAWorkspaceTool class >> workspaceFor: context [ ^ context requireWorkspace ]

{ #category : 'workspace' }
PharoCAWorkspaceTool class >> fileAccessFor: context [
	^ PharoCAWorkspaceFileAccess on: (self workspaceFor: context)
]

{ #category : 'workspace' }
PharoCAWorkspaceTool class >> commandRunnerFor: context [
	^ context workspaceCommandRunner ifNil: [ PharoCAWorkspaceCommandRunner new ]
]

{ #category : 'workspace' }
PharoCAWorkspaceTool class >> outputStoreFor: context [
	^ context workspaceOutputStore ifNil: [ PharoCAWorkspaceOutputStore new ]
]
