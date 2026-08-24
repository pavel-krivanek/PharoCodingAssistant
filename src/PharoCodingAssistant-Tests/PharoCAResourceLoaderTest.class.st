Class {
	#name : 'PharoCAResourceLoaderTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'private' }
PharoCAResourceLoaderTest >> write: text to: file [
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: text ]
]

{ #category : 'private' }
PharoCAResourceLoaderTest >> fixture [
	| fs global root project |
	fs := FileSystem memory.
	global := fs / 'global'.
	root := fs / 'project'.
	project := root / '.pharo-ca'.
	global ensureCreateDirectory.
	root ensureCreateDirectory.
	project ensureCreateDirectory.
	^ { fs. global. root. project }
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testUntrustedProjectSettingsAreParsedButInactive [
	| fixture global root project workspace loader resources |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	self write: '{"temperature":0.2}' to: global / 'settings.json'.
	self write: '{"temperature":0.9,"maxIterations":7}' to: project / 'settings.json'.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	resources := loader loadForWorkspace: workspace.
	self assert: (resources settings at: 'temperature') equals: 0.2.
	self assert: (resources settings project at: 'temperature') equals: 0.9.
	self deny: resources settings projectLayerEnabled.
	self assert: (resources diagnostics anySatisfy: [ :each | each code = #untrustedProjectSettingsIgnored ])
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testTrustedProjectSettingsOverrideGlobalAndExplicitOverridesWin [
	| fixture global root project workspace loader resources |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	self write: '{"temperature":0.2,"maxIterations":10}' to: global / 'settings.json'.
	self write: '{"temperature":0.9,"maxIterations":20}' to: project / 'settings.json'.
	workspace := PharoCAWorkspace rootedAt: root.
	workspace trust.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	resources := loader loadForWorkspace: workspace overrides: ({ 'temperature' -> 0.5 } asDictionary).
	self assert: (resources settings at: 'temperature') equals: 0.5.
	self assert: (resources settings at: 'maxIterations') equals: 20.
	self assert: (resources settings sourceForKey: 'maxIterations') equals: #project
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testDiscoversGlobalAndProjectInstructionsSkillsAndTemplatesDeterministically [
	| fixture global root project workspace resources loader instructionNames skill template |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	self write: 'GLOBAL SYSTEM' to: global / 'system.md'.
	self write: 'GLOBAL RULE A' to: global / 'instructions' / 'a.md'.
	self write: '# Shared global', String lf, 'Global skill body' to: global / 'skills' / 'shared.md'.
	self write: 'Global template' to: global / 'templates' / 'review.md'.
	self write: 'ROOT AGENT RULES' to: root / 'AGENTS.md'.
	self write: 'PROJECT SYSTEM' to: project / 'system.md'.
	self write: 'PROJECT RULE B' to: project / 'instructions' / 'b.md'.
	self write: '# Shared project', String lf, 'Project skill body' to: project / 'skills' / 'shared.md'.
	self write: 'Project template' to: project / 'templates' / 'review.md'.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	resources := loader loadForWorkspace: workspace.
	instructionNames := resources instructions collect: [ :each | each name ].
	self assert: (instructionNames includes: 'global-system').
	self assert: (instructionNames includes: 'global:a').
	self assert: (instructionNames includes: 'AGENTS.md').
	self assert: (instructionNames includes: 'project-system').
	self assert: (instructionNames includes: 'project:b').
	skill := resources skills detect: [ :each | each name = 'shared' ].
	self assert: (skill instructions includesSubstring: 'Project skill body').
	self assert: skill scope equals: #project.
	self assert: skill sourcePath equals: (project / 'skills' / 'shared.md') fullName.
	self assert: ((resources instructions detect: [ :each | each name = 'AGENTS.md' ]) sourcePath) equals: (root / 'AGENTS.md') fullName.
	template := resources templates detect: [ :each | each name = 'review' ].
	self assert: template content equals: 'Project template'.
	self assert: (resources diagnostics anySatisfy: [ :each | each code = #skillOverridden ]).
	self assert: (resources diagnostics anySatisfy: [ :each | each code = #templateOverridden ])
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testUntrustedProjectExtensionIsNotInstantiatedButGlobalExtensionIs [
	| fixture global root project workspace resources loader |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	self write: '{"extensions":["PharoCATestExtension"]}' to: global / 'extensions.json'.
	self write: '{"extensions":["PharoCATestExtension"]}' to: project / 'extensions.json'.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	resources := loader loadForWorkspace: workspace.
	self assert: resources extensions size equals: 1.
	self assert: (resources diagnostics anySatisfy: [ :each | each code = #untrustedProjectExtensionsIgnored ]).
	workspace trust.
	resources := loader loadForWorkspace: workspace.
	self assert: resources extensions size equals: 2
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testMalformedResourcesProduceDiagnosticsInsteadOfAbortingDiscovery [
	| fixture global root project workspace resources loader codes |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	self write: '{broken' to: global / 'settings.json'.
	self write: '{"extensions":["NoSuchExtensionClass",123]}' to: global / 'extensions.json'.
	self write: 'still loaded' to: root / 'AGENTS.md'.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	resources := loader loadForWorkspace: workspace.
	codes := resources diagnostics collect: [ :each | each code ].
	self assert: (codes includes: #invalidSettings).
	self assert: (codes includes: #extensionClassNotFound).
	self assert: (codes includes: #invalidExtensionName).
	self assert: resources instructions size equals: 1
]

{ #category : 'tests' }
PharoCAResourceLoaderTest >> testResourceSnapshotIsJSONSafeAndDoesNotContainSkillBodies [
	| fixture global root workspace resources json |
	fixture := self fixture.
	global := fixture second.
	root := fixture third.
	self write: '# Skill', String lf, 'SECRETISH_BODY_NOT_CATALOG' to: global / 'skills' / 'demo.md'.
	workspace := PharoCAWorkspace rootedAt: root.
	resources := (PharoCAResourceLoader new globalRoot: global; yourself) loadForWorkspace: workspace.
	json := STONJSON toString: resources asDictionary.
	self deny: (json includesSubstring: 'SECRETISH_BODY_NOT_CATALOG').
	self assert: (STONJSON fromString: json) isDictionary
]
