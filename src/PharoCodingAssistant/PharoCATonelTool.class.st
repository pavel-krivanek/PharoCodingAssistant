"Shared native Tonel helpers. Concrete tools use the Tonel parser/writer installed in the supported Pharo image rather than reimplementing the format."
Class {
	#name : 'PharoCATonelTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'testing' }
PharoCATonelTool class >> isAbstract [
	^ self = PharoCATonelTool
]

{ #category : 'definition' }
PharoCATonelTool class >> toolPack [
	^ #tonel
]

{ #category : 'definition' }
PharoCATonelTool class >> capability [
	^ #inspection
]

{ #category : 'execution' }
PharoCATonelTool class >> executionMode [
	^ #parallelSafe
]

{ #category : 'private' }
PharoCATonelTool class >> sourceHash: aString [
	^ (SHA256 hashMessage: aString) hex
]

{ #category : 'private' }
PharoCATonelTool class >> summaryForDefinition: definition [
	| result |
	result := OrderedDictionary new.
	result at: 'definitionClass' put: definition class name.
	(definition respondsTo: #isClassDefinition) ifTrue: [
		definition isClassDefinition ifTrue: [ result at: 'kind' put: 'class' ] ].
	(definition respondsTo: #isMethodDefinition) ifTrue: [
		definition isMethodDefinition ifTrue: [ result at: 'kind' put: 'method' ] ].
	(result includesKey: 'kind') ifFalse: [ result at: 'kind' put: 'definition' ].
	(definition respondsTo: #name) ifTrue: [ result at: 'name' put: definition name asString ].
	(definition respondsTo: #className) ifTrue: [ result at: 'className' put: definition className asString ].
	(definition respondsTo: #superclassName) ifTrue: [
		definition superclassName ifNotNil: [ :name | result at: 'superclassName' put: name asString ] ].
	(definition respondsTo: #packageName) ifTrue: [
		definition packageName ifNotNil: [ :name | result at: 'package' put: name asString ] ].
	(definition respondsTo: #tagName) ifTrue: [
		definition tagName ifNotNil: [ :name | result at: 'tag' put: name asString ] ].
	(definition respondsTo: #selector) ifTrue: [ result at: 'selector' put: definition selector asString ].
	(definition respondsTo: #protocol) ifTrue: [
		definition protocol ifNotNil: [ :protocol | result at: 'protocol' put: protocol asString ] ].
	(definition respondsTo: #classIsMeta) ifTrue: [
		result at: 'side' put: (definition classIsMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]) ].
	(definition respondsTo: #isExtensionMethod) ifTrue: [ result at: 'extension' put: definition isExtensionMethod ].
	^ result asDictionary
]

{ #category : 'private' }
PharoCATonelTool class >> normalizedFilesFrom: filePayloads [
	| normalized names total |
	(filePayloads isCollection and: [ filePayloads isString not ]) ifFalse: [ Error signal: 'files must be an array' ].
	filePayloads isEmpty ifTrue: [ Error signal: 'files must not be empty' ].
	filePayloads size > 500 ifTrue: [ Error signal: 'files may contain at most 500 entries' ].
	normalized := OrderedCollection new.
	names := Set new.
	total := 0.
	filePayloads do: [ :payload |
		| name source |
		payload isDictionary ifFalse: [ Error signal: 'Each files entry must be an object' ].
		name := payload at: 'name' ifAbsent: [ Error signal: 'Each files entry requires name' ].
		source := payload at: 'source' ifAbsent: [ Error signal: 'Each files entry requires source' ].
		name isString ifFalse: [ Error signal: 'Tonel file name must be a string' ].
		source isString ifFalse: [ Error signal: 'Tonel file source must be a string' ].
		name isEmpty ifTrue: [ Error signal: 'Tonel file name must not be empty' ].
		(name includesAny: '/\\') ifTrue: [ Error signal: 'Tonel file name must be a basename, not a path: ', name ].
		(name endsWith: '.st') ifFalse: [ Error signal: 'Tonel file name must end with .st: ', name ].
		source size > 200000 ifTrue: [ Error signal: 'Tonel file exceeds 200000 characters: ', name ].
		(names includes: name) ifTrue: [ Error signal: 'Duplicate Tonel file name: ', name ].
		names add: name.
		total := total + source size.
		total > 2000000 ifTrue: [ Error signal: 'Tonel payload exceeds 2000000 characters' ].
		normalized add: { 'name' -> name. 'source' -> source } asDictionary ].
	^ ((normalized asSortedCollection: [ :a :b | (a at: 'name') <= (b at: 'name') ]) asArray)
]

{ #category : 'private' }
PharoCATonelTool class >> validatePackageMetadataSource: source packageName: packageName [
	| prefix metadata |
	prefix := 'Package '.
	(source beginsWith: prefix) ifFalse: [ Error signal: 'package.st must begin with Package ' ].
	metadata := STON fromString: (source copyFrom: prefix size + 1 to: source size).
	metadata isDictionary ifFalse: [ Error signal: 'package.st metadata must be a dictionary' ].
	(metadata at: #name ifAbsent: [ metadata at: 'name' ifAbsent: [ nil ] ]) asString = packageName
		ifFalse: [ Error signal: 'package.st package name does not match ', packageName ]
]

{ #category : 'private' }
PharoCATonelTool class >> definitionKeyFor: definition [
	((definition respondsTo: #isMethodDefinition) and: [ definition isMethodDefinition ]) ifTrue: [
		^ 'method|', definition className asString, '|',
			((definition respondsTo: #classIsMeta) ifTrue: [ definition classIsMeta asString ] ifFalse: [ 'false' ]), '|',
			definition selector asString ].
	((definition respondsTo: #isClassDefinition) and: [ definition isClassDefinition ]) ifTrue: [
		^ 'class|', definition className asString ].
	^ definition class name, '|', definition printString
]

{ #category : 'private' }
PharoCATonelTool class >> packagePayloadForName: packageName files: filePayloads context: context [
	| files definitions keys classNames tags totalCharacters organization snapshot hasPackageMetadata |
	packageName isString ifFalse: [ Error signal: 'packageName must be a string' ].
	packageName isEmpty ifTrue: [ Error signal: 'packageName must not be empty' ].
	files := self normalizedFilesFrom: filePayloads.
	definitions := OrderedCollection new.
	keys := Set new.
	classNames := Set new.
	tags := Set new.
	totalCharacters := 0.
	hasPackageMetadata := false.
	files doWithIndex: [ :payload :index |
		| name source parsed |
		(index \\ 25 = 0) ifTrue: [ context checkActive ].
		name := payload at: 'name'.
		source := payload at: 'source'.
		totalCharacters := totalCharacters + source size.
		name = 'package.st'
			ifTrue: [
				hasPackageMetadata := true.
				self validatePackageMetadataSource: source packageName: packageName ]
			ifFalse: [
				parsed := TonelParser parseString: source.
				parsed isEmpty ifTrue: [ Error signal: 'Tonel file contains no definitions: ', name ].
				parsed do: [ :definition |
					| key |
					key := self definitionKeyFor: definition.
					(keys includes: key) ifTrue: [ Error signal: 'Duplicate Tonel definition: ', key ].
					keys add: key.
					definitions add: definition.
					((definition respondsTo: #isClassDefinition) and: [ definition isClassDefinition ]) ifTrue: [
						definition packageName asString = packageName ifFalse: [
							Error signal: 'Class ', definition className asString, ' belongs to package ', definition packageName asString, ', not ', packageName ].
						classNames add: definition className asString.
						definition tagName ifNotNil: [ :tag | tags add: tag ] ] ] ] ].
	definitions isEmpty ifTrue: [
		hasPackageMetadata ifFalse: [ Error signal: 'Tonel package payload contains no definitions' ] ].
	definitions do: [ :definition |
		((definition respondsTo: #isMethodDefinition) and: [ definition isMethodDefinition ]) ifTrue: [
			definition isExtensionMethod
				ifTrue: [
					((definition protocol asString asLowercase) beginsWith: ('*', packageName asLowercase)) ifFalse: [
						Error signal: 'Extension method ', definition className asString, '>>', definition selector asString,
							' protocol does not belong to package ', packageName ] ]
				ifFalse: [
					(classNames includes: definition className asString) ifFalse: [
						Error signal: 'Non-extension method ', definition className asString, '>>', definition selector asString,
							' has no class definition in the package payload' ] ] ] ].
	organization := MCOrganizationDefinition packageName: packageName asSymbol tagNames: tags asArray.
	snapshot := MCSnapshot fromDefinitions: definitions, { organization }.
	^ {
		'packageName' -> packageName.
		'files' -> files.
		'definitions' -> definitions asArray.
		'snapshot' -> snapshot.
		'fileCount' -> files size.
		'definitionCount' -> definitions size.
		'classCount' -> classNames size.
		'extensionMethodCount' -> (definitions count: [ :each | (each respondsTo: #isMethodDefinition) and: [ each isMethodDefinition and: [ each isExtensionMethod ] ] ]).
		'totalCharacters' -> totalCharacters
	} asDictionary
]

{ #category : 'private' }
PharoCATonelTool class >> snapshotSignature: snapshot [
	| records text |
	records := snapshot definitions collect: [ :definition |
		| source |
		source := [ definition source ] on: Error do: [ :error | definition printString ].
		(self definitionKeyFor: definition), String lf, source asString ].
	records := records asSortedCollection.
	text := String streamContents: [ :stream | records do: [ :each | stream nextPutAll: each; nextPut: Character lf ] ].
	^ (SHA256 hashMessage: text) hex
]

{ #category : 'private' }
PharoCATonelTool class >> currentSnapshotForPackageName: packageName [
	^ [ (MCPackage named: packageName) snapshot ]
		on: Error
		do: [ :error | MCSnapshot empty ]
]

{ #category : 'private' }
PharoCATonelTool class >> packageExistsNamed: packageName [
	^ (PackageOrganizer default packageNamed: packageName ifAbsent: [ nil ]) notNil
]

{ #category : 'private' }
PharoCATonelTool class >> summaryForPatchOperation: operation [
	| result definition before after |
	result := OrderedDictionary new.
	result at: 'change' put: (
		((operation respondsTo: #isAddition) and: [ operation isAddition ])
			ifTrue: [ 'addition' ]
			ifFalse: [ ((operation respondsTo: #isRemoval) and: [ operation isRemoval ])
				ifTrue: [ 'removal' ]
				ifFalse: [ 'modification' ] ]).
	definition := operation definition.
	result at: 'definition' put: (self summaryForDefinition: definition).
	(operation respondsTo: #baseDefinition) ifTrue: [
		before := operation baseDefinition.
		before ifNotNil: [ result at: 'before' put: (self summaryForDefinition: before) ] ].
	(operation respondsTo: #targetDefinition) ifTrue: [
		after := operation targetDefinition.
		after ifNotNil: [ result at: 'after' put: (self summaryForDefinition: after) ] ].
	^ result asDictionary
]

{ #category : 'private' }
PharoCATonelTool class >> patchPlanFromCurrentPackageNamed: packageName toSnapshot: targetSnapshot context: context [
	| current patch plan |
	current := self currentSnapshotForPackageName: packageName.
	patch := targetSnapshot patchRelativeToBase: current.
	plan := OrderedCollection new.
	patch operations doWithIndex: [ :operation :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		plan add: (self summaryForPatchOperation: operation) ].
	^ plan asArray
]

{ #category : 'private' }
PharoCATonelTool class >> planSignature: plan currentSignature: currentSignature targetSignature: targetSignature [
	^ (SHA256 hashMessage: currentSignature, '|', targetSignature, '|', (STONJSON toString: plan)) hex
]
