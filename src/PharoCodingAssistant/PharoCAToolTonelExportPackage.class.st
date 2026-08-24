"Exports a live package through native TonelWriter into a private temporary directory, returning bounded metadata or one paginated file."
Class {
	#name : 'PharoCAToolTonelExportPackage',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolTonelExportPackage class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolTonelExportPackage class >> toolName [ ^ #tonel_export_package ]

{ #category : 'definition' }
PharoCAToolTonelExportPackage class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_export_package'
		description: 'Exports a live package with Pharo''s native TonelWriter. Without fileName it lists paginated exported file metadata; with fileName it returns that file with character pagination. Temporary export files are always deleted.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'packageName' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'fileName' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('packageName')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelExportPackage class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolTonelExportPackage class >> execute: args context: context [
	| packageName package root packageDir children metadata state fileName target source hash page |
	packageName := args at: 'packageName'.
	(self packageExistsNamed: packageName) ifFalse: [ Error signal: 'Package not found: ', packageName ].
	package := MCPackage named: packageName.
	root := FileLocator temp / ('pharoca-tonel-export-', UUID new asString).
	[ root ensureCreateDirectory.
		context checkActive.
		(TonelWriter on: root) writeSnapshot: package snapshot.
		packageDir := root / packageName.
		children := (packageDir children select: [ :each | each isFile ]) asSortedCollection: [ :a :b | a basename <= b basename ].
		metadata := OrderedCollection new.
		children doWithIndex: [ :child :index |
			| contents |
			(index \\ 25 = 0) ifTrue: [ context checkActive ].
			contents := child contents.
			metadata add: {
				'name' -> child basename.
				'characters' -> contents size.
				'sha256' -> (self sourceHash: contents)
			} asDictionary ].
		state := (SHA256 hashMessage: (STONJSON toString: metadata asArray)) hex.
		fileName := args at: 'fileName' ifAbsent: [ nil ].
		fileName ifNil: [
			page := PharoCAToolPagination
				pageItems: metadata
				arguments: args
				scope: 'tonel_export_package|', packageName, '|', state.
			^ {
				'packageName' -> packageName.
				'packageSignature' -> state.
				'files' -> (page at: 'items').
				'page' -> (page at: 'page')
			} asDictionary ].
		target := children detect: [ :each | each basename = fileName ] ifNone: [ Error signal: 'Exported Tonel file not found: ', fileName ].
		source := target contents.
		hash := self sourceHash: source.
		page := PharoCAToolPagination
			pageText: source
			arguments: args
			scope: 'tonel_export_package_file|', packageName, '|', state, '|', fileName, '|', hash.
		^ {
			'packageName' -> packageName.
			'packageSignature' -> state.
			'fileName' -> fileName.
			'sourceHash' -> hash.
			'text' -> (page at: 'text').
			'range' -> (page at: 'range')
		} asDictionary
	] ensure: [ root exists ifTrue: [ root ensureDeleteAll ] ]
]
