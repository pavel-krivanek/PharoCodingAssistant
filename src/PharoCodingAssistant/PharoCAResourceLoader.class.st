"Discovers global/project coding-harness resources. Global resources are trusted; project settings/extensions are applied only for trusted workspaces."
Class {
	#name : 'PharoCAResourceLoader',
	#superclass : 'Object',
	#instVars : [ 'globalRoot', 'defaultSettings' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAResourceLoader class >> default [
	^ self new globalRoot: (FileLocator home asFileReference / '.pharo-ca'); yourself
]

{ #category : 'initialization' }
PharoCAResourceLoader >> initialize [
	super initialize.
	defaultSettings := {
		'maxIterations' -> 50.
		'timeout' -> 3600.
		'temperature' -> 0.0.
		'toolTimeoutMilliseconds' -> 60000.
		'context.safetyMarginTokens' -> 256.
		'context.compactionEnabled' -> true.
		'context.summarizationEnabled' -> false.
		'context.overflowRecoveryAttempts' -> 1.
		'context.overflowSafetyMarginIncrementTokens' -> 1024.
		'skill.discoveryCharacterBudget' -> 4000.
		'systemPrompt' -> PharoCAConfiguration new systemPrompt.
		'context.reservedOutputTokens' -> nil
	} asDictionary
]

{ #category : 'accessing' }
PharoCAResourceLoader >> globalRoot [ ^ globalRoot ]
{ #category : 'accessing' }
PharoCAResourceLoader >> globalRoot: aFileReferenceOrNil [ globalRoot := aFileReferenceOrNil ifNotNil: [ aFileReferenceOrNil asFileReference ] ]
{ #category : 'accessing' }
PharoCAResourceLoader >> defaultSettings [ ^ defaultSettings copy ]
{ #category : 'accessing' }
PharoCAResourceLoader >> defaultSettings: aDictionary [ defaultSettings := aDictionary copy ]

{ #category : 'loading' }
PharoCAResourceLoader >> loadForWorkspace: aWorkspace [
	^ self loadForWorkspace: aWorkspace overrides: Dictionary new
]

{ #category : 'loading' }
PharoCAResourceLoader >> loadForWorkspace: aWorkspace overrides: overrideDictionary [
	| resources settings globalSettings projectSettings projectRoot |
	resources := PharoCAWorkspaceResources new workspace: aWorkspace; yourself.
	settings := PharoCASettings new
		defaults: defaultSettings;
		overrides: overrideDictionary;
		projectLayerEnabled: aWorkspace trusted;
		yourself.
	globalSettings := Dictionary new.
	globalRoot ifNotNil: [
		globalSettings := self loadSettingsAt: globalRoot / 'settings.json' scope: #global into: resources.
		self discoverResourcesAt: globalRoot scope: #global trusted: true into: resources ].
	settings global: globalSettings.
	projectRoot := aWorkspace projectResourceRoot.
	projectSettings := self loadSettingsAt: projectRoot / 'settings.json' scope: #project into: resources.
	settings project: projectSettings.
	(aWorkspace trusted not and: [ projectSettings notEmpty ]) ifTrue: [
		resources addDiagnostic: (PharoCAResourceDiagnostic
			severity: #warning
			code: #untrustedProjectSettingsIgnored
			message: 'Project settings were discovered but are inactive until this workspace is trusted'
			path: projectRoot / 'settings.json'
			scope: #project) ].
	self discoverAgentsFileFor: aWorkspace into: resources.
	self discoverResourcesAt: projectRoot scope: #project trusted: aWorkspace trusted into: resources.
	resources settings: settings.
	^ resources
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> loadSettingsAt: file scope: scope into: resources [
	| object |
	file exists ifFalse: [ ^ Dictionary new ].
	object := [ PharoCASettingsPersistence new settingsDictionaryFromString: file contents ]
		on: Error
		do: [ :error |
			resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidSettings message: error description path: file scope: scope).
			^ Dictionary new ].
	object isDictionary ifFalse: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidSettingsRoot message: 'Settings JSON root must be an object' path: file scope: scope).
		^ Dictionary new ].
	^ object
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverAgentsFileFor: workspace into: resources [
	| file source |
	file := workspace agentsFile.
	file exists ifFalse: [ ^ self ].
	source := (PharoCAInstructionSource projectNamed: 'AGENTS.md' content: file contents)
		priority: 150;
		sourcePath: file fullName;
		yourself.
	resources addInstruction: source
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverResourcesAt: root scope: scope trusted: trusted into: resources [
	root exists ifFalse: [ ^ self ].
	root isDirectory ifFalse: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #warning code: #resourceRootNotDirectory message: 'Resource root is not a directory' path: root scope: scope).
		^ self ].
	self discoverSystemAt: root scope: scope into: resources.
	self discoverInstructionFilesAt: root / 'instructions' scope: scope into: resources.
	self discoverSkillFilesAt: root / 'skills' scope: scope into: resources.
	self discoverTemplateFilesAt: root / 'templates' scope: scope into: resources.
	self discoverExtensionsAt: root / 'extensions.json' scope: scope trusted: trusted into: resources
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverSystemAt: root scope: scope into: resources [
	| file sourceName source |
	file := root / 'system.md'.
	file exists ifFalse: [ ^ self ].
	sourceName := scope asString, '-system'.
	source := (PharoCAInstructionSource named: sourceName content: file contents)
		kind: scope;
		priority: (scope = #global ifTrue: [ 50 ] ifFalse: [ 140 ]);
		sourcePath: file fullName;
		yourself.
	resources addInstruction: source
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverInstructionFilesAt: directory scope: scope into: resources [
	(directory exists and: [ directory isDirectory ]) ifFalse: [ ^ self ].
	(self markdownChildrenOf: directory) do: [ :file |
		| source |
		source := (PharoCAInstructionSource named: scope asString, ':', file basenameWithoutExtension content: file contents)
			kind: scope;
			priority: (scope = #global ifTrue: [ 100 ] ifFalse: [ 200 ]);
			sourcePath: file fullName;
			yourself.
		resources addInstruction: source ]
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverSkillFilesAt: directory scope: scope into: resources [
	(directory exists and: [ directory isDirectory ]) ifFalse: [ ^ self ].
	(self markdownChildrenOf: directory) do: [ :file |
		| content description skill |
		content := file contents.
		description := self descriptionFromMarkdown: content fallback: file basenameWithoutExtension.
		skill := (PharoCASkill
			named: file basenameWithoutExtension
			description: description
			instructions: content)
			scope: scope;
			sourcePath: file fullName;
			yourself.
		resources addSkill: skill scope: scope ]
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverTemplateFilesAt: directory scope: scope into: resources [
	(directory exists and: [ directory isDirectory ]) ifFalse: [ ^ self ].
	(self markdownChildrenOf: directory) do: [ :file |
		| template |
		template := (PharoCAPromptTemplate named: file basenameWithoutExtension content: file contents)
			scope: scope;
			sourcePath: file fullName;
			yourself.
		resources addTemplate: template scope: scope ]
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> discoverExtensionsAt: file scope: scope trusted: trusted into: resources [
	| object names |
	file exists ifFalse: [ ^ self ].
	(scope = #project and: [ trusted not ]) ifTrue: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #warning code: #untrustedProjectExtensionsIgnored message: 'Project extensions were not instantiated because the workspace is untrusted' path: file scope: scope).
		^ self ].
	object := [ STONJSON fromString: file contents ]
		on: Error
		do: [ :error |
			resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidExtensionsManifest message: error description path: file scope: scope).
			^ self ].
	names := object isArray
		ifTrue: [ object ]
		ifFalse: [ object isDictionary ifTrue: [ object at: 'extensions' ifAbsent: [ #() ] ] ifFalse: [ #() ] ].
	names isArray ifFalse: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidExtensionsManifest message: 'extensions must be an array of class names' path: file scope: scope).
		^ self ].
	names do: [ :className | self instantiateExtensionNamed: className scope: scope path: file into: resources ]
]

{ #category : 'private-loading' }
PharoCAResourceLoader >> instantiateExtensionNamed: className scope: scope path: file into: resources [
	| class extension |
	className isString ifFalse: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidExtensionName message: 'Extension class name must be a string' path: file scope: scope).
		^ self ].
	class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
	class ifNil: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #extensionClassNotFound message: 'Extension class not found: ', className path: file scope: scope).
		^ self ].
	(class = PharoCAExtension or: [ class allSuperclasses includes: PharoCAExtension ]) ifFalse: [
		resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #invalidExtensionClass message: className, ' is not a PharoCAExtension subclass' path: file scope: scope).
		^ self ].
	extension := [ class new ]
		on: Error
		do: [ :error |
			resources addDiagnostic: (PharoCAResourceDiagnostic severity: #error code: #extensionInstantiationFailed message: error description path: file scope: scope).
			^ self ].
	resources addExtension: extension
]

{ #category : 'private' }
PharoCAResourceLoader >> markdownChildrenOf: directory [
	^ ((directory children select: [ :each | each isFile and: [ each extension asLowercase = 'md' ] ])
		asSortedCollection: [ :a :b | a basename <= b basename ]) asArray
]

{ #category : 'private' }
PharoCAResourceLoader >> descriptionFromMarkdown: content fallback: fallback [
	| lines line |
	lines := content lines collect: [ :each | each trimBoth ].
	line := lines detect: [ :each | each notEmpty ] ifNone: [ ^ fallback ].
	(line beginsWith: '#') ifTrue: [
		line := line allButFirst trimBoth.
		line isEmpty ifTrue: [ ^ fallback ] ].
	^ line size > 240 ifTrue: [ (line copyFrom: 1 to: 240), '...' ] ifFalse: [ line ]
]
