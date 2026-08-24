Class {
	#name : 'PharoCAToolTonelPackageTest',
	#superclass : 'TestCase',
	#instVars : [ 'context' ],
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolTonelPackageTest >> packageName [ ^ 'PharoCATonelImportFixture' ]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> className [ ^ 'PharoCATonelImportFixture' ]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> sourceAnswering: anInteger [
	^ String streamContents: [ :s |
		s nextPutAll: 'Class {'; cr.
		s tab; nextPutAll: '#name : ''', self className, ''','; cr.
		s tab; nextPutAll: '#superclass : ''Object'','; cr.
		s tab; nextPutAll: '#category : ''', self packageName, ''','; cr.
		s tab; nextPutAll: '#package : ''', self packageName, ''''; cr.
		s nextPutAll: '}'; cr; cr.
		s nextPutAll: '{ #category : ''testing'' }'; cr.
		s nextPutAll: self className, ' >> answer ['; cr.
		s tab; nextPutAll: '^ ', anInteger asString; cr.
		s nextPutAll: ']'; cr ]
]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> filesAnswering: anInteger [
	^ { {
		'name' -> (self className, '.class.st').
		'source' -> (self sourceAnswering: anInteger)
	} asDictionary }
]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> previewAnswering: anInteger [
	^ PharoCAToolTonelImportPreview
		execute: { 'packageName' -> self packageName. 'files' -> (self filesAnswering: anInteger) } asDictionary
		context: context
]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> applyPreview: preview [
	^ PharoCAToolTonelImportApply
		execute: { 'importHandle' -> (preview at: 'importHandle') } asDictionary
		context: context
]

{ #category : 'private' }
PharoCAToolTonelPackageTest >> installAnswering: anInteger [
	^ self applyPreview: (self previewAnswering: anInteger)
]

{ #category : 'running' }
PharoCAToolTonelPackageTest >> setUp [
	super setUp.
	context := PharoCAToolExecutionContext unlimited.
	context
		runtimeHandleRegistry: PharoCARuntimeHandleRegistry new;
		environment: PharoCAEnvironment new
]

{ #category : 'running' }
PharoCAToolTonelPackageTest >> tearDown [
	Smalltalk globals at: self className asSymbol ifPresent: [ :aClass | [ aClass removeFromSystem ] on: Error do: [ :error | ] ].
	PackageOrganizer default packageNamed: self packageName ifPresent: [ :package |
		[ PackageOrganizer default removePackage: package ] on: Error do: [ :error | ] ].
	super tearDown
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testValidatePackageAcceptsNativePayloadAndRejectsPackageMismatch [
	| valid mismatch malformed |
	valid := PharoCAToolTonelValidatePackage execute: {
		'packageName' -> self packageName.
		'files' -> (self filesAnswering: 42)
	} asDictionary.
	self assert: (valid at: 'valid').
	self assert: (valid at: 'classCount') equals: 1.
	self assert: (valid at: 'definitionCount') equals: 2.
	mismatch := PharoCAToolTonelValidatePackage execute: {
		'packageName' -> 'AnotherPackage'.
		'files' -> (self filesAnswering: 42)
	} asDictionary.
	self deny: (mismatch at: 'valid').
	malformed := PharoCAToolTonelValidatePackage execute: {
		'packageName' -> self packageName.
		'files' -> { { 'name' -> 'Broken.class.st'. 'source' -> 'not tonel' } asDictionary }
	} asDictionary.
	self deny: (malformed at: 'valid')
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testImportPreviewApplyIsOneShotAndJournaled [
	| preview applied cls entries |
	preview := self previewAnswering: 42.
	self assert: (preview at: 'status') equals: 'preview'.
	self assert: (preview at: 'changeCount') > 0.
	self assert: ((preview at: 'importHandle') beginsWith: 'tonel-import-').
	self deny: (Smalltalk globals includesKey: self className asSymbol).
	applied := self applyPreview: preview.
	self assert: (applied at: 'status') equals: 'applied'.
	cls := Smalltalk globals at: self className asSymbol.
	self assert: cls new answer equals: 42.
	entries := context environment changeJournal entries.
	self assert: entries size equals: 1.
	self assert: entries first kind equals: #tonelImportApplied.
	self assert: entries first target equals: self packageName.
	self should: [ self applyPreview: preview ] raise: Error
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testImportApplyRejectsStaleLivePackage [
	| preview cls stale |
	self installAnswering: 42.
	preview := self previewAnswering: 43.
	cls := Smalltalk globals at: self className asSymbol.
	cls compile: 'unrelated ^ 99' classified: 'testing'.
	stale := self applyPreview: preview.
	self assert: (stale at: 'status') equals: 'stale'.
	self assert: cls new answer equals: 42.
	self assert: (cls new perform: #unrelated) equals: 99
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testImportCanModifyExistingPackageMethod [
	| preview applied cls |
	self installAnswering: 42.
	preview := self previewAnswering: 43.
	self assert: ((preview at: 'counts') at: 'modification') > 0.
	applied := self applyPreview: preview.
	self assert: (applied at: 'status') equals: 'applied'.
	cls := Smalltalk globals at: self className asSymbol.
	self assert: cls new answer equals: 43
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testExportClassAndPackageAreBoundedAndRoundTripValidation [
	| classExport listed names classFile packageFile valid |
	self installAnswering: 42.
	classExport := PharoCAToolTonelExportClass execute: { 'className' -> self className. 'maxCharacters' -> 80 } asDictionary.
	self assert: (classExport at: 'fileName') equals: self className, '.class.st'.
	self assert: ((classExport at: 'range') at: 'returnedCharacters') equals: 80.
	listed := PharoCAToolTonelExportPackage execute: { 'packageName' -> self packageName. 'limit' -> 20 } asDictionary.
	names := (listed at: 'files') collect: [ :each | each at: 'name' ].
	self assert: (names includes: self className, '.class.st').
	self assert: (names includes: 'package.st').
	classFile := PharoCAToolTonelExportPackage execute: {
		'packageName' -> self packageName.
		'fileName' -> (self className, '.class.st').
		'maxCharacters' -> 16000
	} asDictionary.
	packageFile := PharoCAToolTonelExportPackage execute: {
		'packageName' -> self packageName.
		'fileName' -> 'package.st'.
		'maxCharacters' -> 16000
	} asDictionary.
	valid := PharoCAToolTonelValidatePackage execute: {
		'packageName' -> self packageName.
		'files' -> {
			{ 'name' -> (self className, '.class.st'). 'source' -> (classFile at: 'text') } asDictionary.
			{ 'name' -> 'package.st'. 'source' -> (packageFile at: 'text') } asDictionary }
	} asDictionary.
	self assert: (valid at: 'valid')
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testPackageExportCursorIsBoundToCurrentPackageState [
	| first cursor cls |
	self installAnswering: 42.
	first := PharoCAToolTonelExportPackage execute: { 'packageName' -> self packageName. 'limit' -> 1 } asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	cls := Smalltalk globals at: self className asSymbol.
	cls compile: 'another ^ 7' classified: 'testing'.
	self should: [
		PharoCAToolTonelExportPackage execute: {
			'packageName' -> self packageName.
			'limit' -> 1.
			'cursor' -> cursor
		} asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testValidationAndPreviewCancellationAreExplicit [
	| cancelled |
	cancelled := PharoCAToolExecutionContext unlimited.
	cancelled cancellationToken cancel.
	self should: [
		PharoCAToolTonelValidatePackage execute: {
			'packageName' -> self packageName.
			'files' -> (self filesAnswering: 42)
		} asDictionary context: cancelled
	] raise: PharoCAToolExecutionCancelled.
	self should: [
		PharoCAToolTonelImportPreview execute: {
			'packageName' -> self packageName.
			'files' -> (self filesAnswering: 42)
		} asDictionary context: cancelled
	] raise: PharoCAToolExecutionCancelled
]


{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testValidationAcceptsMetadataOnlyEmptyPackage [
	| packageSource result |
	packageSource := 'Package ', (STON toString: { #name -> 'PharoCAEmptyTonelFixture' } asDictionary).
	result := PharoCAToolTonelValidatePackage execute: {
		'packageName' -> 'PharoCAEmptyTonelFixture'.
		'files' -> { { 'name' -> 'package.st'. 'source' -> packageSource } asDictionary }
	} asDictionary.
	self assert: (result at: 'valid').
	self assert: (result at: 'definitionCount') equals: 0.
	self assert: (result at: 'classCount') equals: 0
]

{ #category : 'tests' }
PharoCAToolTonelPackageTest >> testRegistryRejectsTopLevelInvalidSchemas [
	| registry missing wrongFiles |
	registry := PharoCAToolRegistry default useProfileNamed: 'coding'; yourself.
	missing := registry executeNamed: 'tonel_validate_package' arguments: Dictionary new.
	self deny: (missing at: 'ok').
	self assert: ((missing at: 'error') at: 'type') equals: 'invalid_arguments'.
	wrongFiles := registry executeNamed: 'tonel_validate_package' arguments: {
		'packageName' -> self packageName.
		'files' -> 'not-an-array'
	} asDictionary.
	self deny: (wrongFiles at: 'ok').
	self assert: ((wrongFiles at: 'error') at: 'type') equals: 'invalid_arguments'
]
