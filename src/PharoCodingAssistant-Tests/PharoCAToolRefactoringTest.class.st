Class {
	#name : 'PharoCAToolRefactoringTest',
	#superclass : 'TestCase',
	#instVars : [ 'registry', 'environment' ],
	#category : 'PharoCodingAssistant-Tests-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'testing' }
PharoCAToolRefactoringTest class >> defaultTimeLimit [
	^ 60 seconds
]

{ #category : 'running' }
PharoCAToolRefactoringTest >> setUp [
	super setUp.
	environment := PharoCAEnvironment named: 'refactoring-test-', UUID new asString.
	registry := (PharoCAToolRegistry defaultInEnvironment: environment)
		useProfileNamed: 'full';
		yourself
]

{ #category : 'running' }
PharoCAToolRefactoringTest >> tearDown [
	| doomed packageNames |
	doomed := Smalltalk globals values select: [ :each |
		(each isClass or: [ each isTrait ]) and: [ each name beginsWith: 'PCARefTest' ] ].
	doomed asArray do: [ :each | [ each removeFromSystem ] on: Error do: [ :error | ] ].
	packageNames := PackageOrganizer default packageNames select: [ :each | each asString beginsWith: 'PCA-Ref-Test' ].
	packageNames asArray do: [ :name |
		[ | pkg | pkg := PackageOrganizer default packageNamed: name ifAbsent: [ nil ]. pkg ifNotNil: [ PackageOrganizer default removePackage: pkg ] ] on: Error do: [ :error | ] ].
	super tearDown
]

{ #category : 'helpers' }
PharoCAToolRefactoringTest >> newClassNamed: name superclass: superclass slots: slots package: packageName [
	| class |
	class := (superclass << name asSymbol)
		slots: slots;
		package: packageName;
		install.
	^ class
]

{ #category : 'helpers' }
PharoCAToolRefactoringTest >> previewTool: toolName arguments: arguments [
	| envelope result |
	envelope := registry executeNamed: toolName arguments: arguments.
	self assert: (envelope at: 'ok') description: envelope printString.
	result := envelope at: 'result'.
	self assert: ((result at: 'status') = 'preview') description: result printString.
	self assert: ((result at: 'refactorHandle') beginsWith: 'refactor-') description: result printString.
	self assert: ((result at: 'changeCount') > 0) description: result printString.
	^ result
]

{ #category : 'helpers' }
PharoCAToolRefactoringTest >> applyPreview: preview [
	| envelope result |
	envelope := registry executeNamed: 'refactor_apply' arguments: { 'refactorHandle' -> (preview at: 'refactorHandle') } asDictionary.
	self assert: (envelope at: 'ok').
	result := envelope at: 'result'.
	self assert: (result at: 'status') equals: 'applied'.
	self assert: (result at: 'changeId') notNil.
	^ result
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenameClassPreviewAndApply [
	| preview user renamedClass |
	self newClassNamed: 'PCARefTestRenameClassOld' superclass: Object slots: #() package: 'PCA-Ref-Test-RenameClass'.
	user := self newClassNamed: 'PCARefTestRenameClassUser' superclass: Object slots: #() package: 'PCA-Ref-Test-RenameClass'.
	user compile: 'pcaRefMakeRenamed ^ PCARefTestRenameClassOld new'.
	preview := self previewTool: 'refactor_rename_class' arguments: {
		'className' -> 'PCARefTestRenameClassOld'. 'newName' -> 'PCARefTestRenameClassNew' } asDictionary.
	self assert: (Smalltalk includesKey: ('PCARefTest', 'RenameClassOld') asSymbol).
	self deny: (Smalltalk includesKey: ('PCARefTest', 'RenameClassNew') asSymbol).
	self applyPreview: preview.
	self deny: (Smalltalk includesKey: ('PCARefTest', 'RenameClassOld') asSymbol).
	self assert: (Smalltalk includesKey: ('PCARefTest', 'RenameClassNew') asSymbol).
	renamedClass := Smalltalk globals at: ('PCARefTest', 'RenameClassNew') asSymbol.
	self assert: ((user >> ('pcaRefMake', 'Renamed') asSymbol) sourceCode includesSubstring: 'PCARefTestRenameClassNew').
	self assert: ((user new perform: ('pcaRefMake', 'Renamed') asSymbol) class = renamedClass)
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenameMethodPreviewAndApply [
	| class caller preview oldSelector newSelector callerSelector |
	class := self newClassNamed: 'PCARefTestRenameMethod' superclass: Object slots: #() package: 'PCA-Ref-Test-RenameMethod'.
	oldSelector := 'pcaRefRenameMethodOld:' asSymbol.
	newSelector := 'pcaRefRenameMethodNew:' asSymbol.
	class compile: oldSelector asString, ' a ^ a + 1'.
	caller := self newClassNamed: 'PCARefTestRenameMethodCaller' superclass: Object slots: #() package: 'PCA-Ref-Test-RenameMethod'.
	callerSelector := 'pcaRefCallRenameMethod:' asSymbol.
	caller compile: callerSelector asString, ' anObject ^ anObject ', oldSelector asString, ' 3'.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> newSelector asString } asDictionary.
	self assert: (class includesSelector: oldSelector).
	self applyPreview: preview.
	self deny: (class includesSelector: oldSelector).
	self assert: (class includesSelector: newSelector).
	self assert: ((caller >> callerSelector) sourceCode includesSubstring: newSelector asString).
	self assert: (caller new perform: callerSelector with: class new) equals: 4
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenameInstanceVariablePreviewAndApply [
	| class preview |
	class := self newClassNamed: 'PCARefTestRenameIvar' superclass: Object slots: #(oldSlot) package: 'PCA-Ref-Test-RenameIvar'.
	class compile: 'value ^ oldSlot'.
	preview := self previewTool: 'refactor_rename_instance_variable' arguments: {
		'className' -> class name. 'oldName' -> 'oldSlot'. 'newName' -> 'newSlot' } asDictionary.
	self applyPreview: preview.
	self assert: ((class slots collect: #name) includes: #newSlot).
	self deny: ((class slots collect: #name) includes: #oldSlot).
	self assert: ((class >> #value) sourceCode includesSubstring: 'newSlot')
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenameLocalPreviewAndApply [
	| class preview source selector |
	class := self newClassNamed: 'PCARefTestRenameLocal' superclass: Object slots: #() package: 'PCA-Ref-Test-RenameLocal'.
	selector := 'pcaRefRenameLocal:' asSymbol.
	class compile: selector asString, ' a | temp | temp := a + 1. ^ temp'.
	preview := self previewTool: 'refactor_rename_local' arguments: {
		'className' -> class name. 'selector' -> selector asString. 'oldName' -> 'temp'. 'newName' -> 'sum' } asDictionary.
	self applyPreview: preview.
	source := (class >> selector) sourceCode.
	self assert: (source includesSubstring: 'sum').
	self deny: (source includesSubstring: 'temp').
	self assert: (class new perform: selector with: 4) equals: 5
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenamePackagePreviewAndApply [
	| class preview |
	class := self newClassNamed: 'PCARefTestRenamePackage' superclass: Object slots: #() package: 'PCA-Ref-Test-PackageOld'.
	preview := self previewTool: 'refactor_rename_package' arguments: {
		'packageName' -> 'PCA-Ref-Test-PackageOld'. 'newName' -> 'PCA-Ref-Test-PackageNew' } asDictionary.
	self applyPreview: preview.
	self assert: class package name equals: 'PCA-Ref-Test-PackageNew'.
	self assert: (PackageOrganizer default packageNamed: 'PCA-Ref-Test-PackageNew' ifAbsent: [ nil ]) notNil
]

{ #category : 'tests - extraction' }
PharoCAToolRefactoringTest >> testExtractTemporaryPreviewAndApply [
	| class source start preview updated selector |
	class := self newClassNamed: 'PCARefTestExtractTemp' superclass: Object slots: #() package: 'PCA-Ref-Test-ExtractTemp'.
	selector := 'pcaRefExtractTemporary' asSymbol.
	class compile: selector asString, ' ^ (1 + 2) * 3'.
	source := (class >> selector) sourceCode.
	start := source findString: '1 + 2'.
	preview := self previewTool: 'refactor_extract_temporary' arguments: {
		'className' -> class name. 'selector' -> selector asString. 'start' -> start. 'end' -> (start + 4). 'variableName' -> 'sum' } asDictionary.
	self applyPreview: preview.
	updated := (class >> selector) sourceCode.
	self assert: (updated includesSubstring: 'sum').
	self assert: (updated includesSubstring: 'sum := 1 + 2').
	self assert: (class new perform: selector) equals: 9
]

{ #category : 'tests - extraction' }
PharoCAToolRefactoringTest >> testExtractMethodPreviewAndApply [
	| class source start preview sourceSelector extractedSelector |
	class := self newClassNamed: 'PCARefTestExtractMethod' superclass: Object slots: #() package: 'PCA-Ref-Test-ExtractMethod'.
	sourceSelector := 'pcaRefExtractMethodSource' asSymbol.
	extractedSelector := 'pcaRefExtractedHelper' asSymbol.
	class compile: sourceSelector asString, ' ^ (1 + 2) * 3'.
	source := (class >> sourceSelector) sourceCode.
	start := source findString: '1 + 2'.
	preview := self previewTool: 'refactor_extract_method' arguments: {
		'className' -> class name. 'selector' -> sourceSelector asString. 'start' -> start. 'end' -> (start + 4). 'newSelector' -> extractedSelector asString } asDictionary.
	self applyPreview: preview.
	self assert: (class includesSelector: extractedSelector).
	self assert: ((class >> sourceSelector) sourceCode includesSubstring: 'self ', extractedSelector asString).
	self assert: (class new perform: sourceSelector) equals: 9
]

{ #category : 'tests - inline' }
PharoCAToolRefactoringTest >> testInlineMethodPreviewAndApply [
	| class source start preview updated helperSelector callerSelector |
	class := self newClassNamed: 'PCARefTestInlineMethod' superclass: Object slots: #() package: 'PCA-Ref-Test-Inline'.
	helperSelector := 'pcaRefInlineHelper' asSymbol.
	callerSelector := 'pcaRefInlineCaller' asSymbol.
	class compile: helperSelector asString, ' ^ 40 + 2'.
	class compile: callerSelector asString, ' ^ self ', helperSelector asString.
	source := (class >> callerSelector) sourceCode.
	start := source findString: 'self ', helperSelector asString.
	preview := self previewTool: 'refactor_inline_method' arguments: {
		'className' -> class name. 'selector' -> callerSelector asString. 'start' -> start. 'end' -> (start + 4 + helperSelector asString size) } asDictionary.
	self applyPreview: preview.
	updated := (class >> callerSelector) sourceCode.
	self deny: (updated includesSubstring: 'self ', helperSelector asString).
	self assert: (updated includesSubstring: '40 + 2').
	self assert: (class new perform: callerSelector) equals: 42
]

{ #category : 'tests - moving' }
PharoCAToolRefactoringTest >> testMoveMethodPreviewAndApply [
	| source target preview selector |
	source := self newClassNamed: 'PCARefTestMoveSource' superclass: Object slots: #() package: 'PCA-Ref-Test-Move'.
	target := self newClassNamed: 'PCARefTestMoveTarget' superclass: Object slots: #() package: 'PCA-Ref-Test-Move'.
	selector := 'pcaRefMoveMe' asSymbol.
	source compile: selector asString, ' ^ 7'.
	preview := self previewTool: 'refactor_move_method' arguments: {
		'className' -> source name. 'selector' -> selector asString. 'targetClassName' -> target name } asDictionary.
	self applyPreview: preview.
	self deny: (source includesSelector: selector).
	self assert: (target includesSelector: selector).
	self assert: (target new perform: selector) equals: 7
]

{ #category : 'tests - moving' }
PharoCAToolRefactoringTest >> testPullUpMethodPreviewAndApply [
	| base child preview selector |
	base := self newClassNamed: 'PCARefTestPullBase' superclass: Object slots: #() package: 'PCA-Ref-Test-Pull'.
	child := self newClassNamed: 'PCARefTestPullChild' superclass: base slots: #() package: 'PCA-Ref-Test-Pull'.
	selector := 'pcaRefPulled' asSymbol.
	child compile: selector asString, ' ^ 8'.
	preview := self previewTool: 'refactor_pull_up_method' arguments: {
		'className' -> child name. 'selector' -> selector asString } asDictionary.
	self applyPreview: preview.
	self assert: (base includesSelector: selector).
	self deny: (child includesSelector: selector).
	self assert: (child new perform: selector) equals: 8
]

{ #category : 'tests - moving' }
PharoCAToolRefactoringTest >> testPushDownMethodPreviewAndApply [
	| base child preview selector |
	base := self newClassNamed: 'PCARefTestPushBase' superclass: Object slots: #() package: 'PCA-Ref-Test-Push'.
	child := self newClassNamed: 'PCARefTestPushChild' superclass: base slots: #() package: 'PCA-Ref-Test-Push'.
	selector := 'pcaRefPushed' asSymbol.
	base compile: selector asString, ' ^ 9'.
	preview := self previewTool: 'refactor_push_down_method' arguments: {
		'className' -> base name. 'selector' -> selector asString. 'targetClassNames' -> { child name } } asDictionary.
	self applyPreview: preview.
	self deny: (base includesSelector: selector).
	self assert: (child includesSelector: selector).
	self assert: (child new perform: selector) equals: 9
]

{ #category : 'tests - parameters' }
PharoCAToolRefactoringTest >> testAddParameterPreviewAndApply [
	| class caller preview oldSelector newSelector callerSelector |
	class := self newClassNamed: 'PCARefTestAddParam' superclass: Object slots: #() package: 'PCA-Ref-Test-AddParam'.
	oldSelector := 'pcaRefAddOne:' asSymbol.
	newSelector := 'pcaRefAddOne:extra:' asSymbol.
	class compile: oldSelector asString, ' a ^ a'.
	caller := self newClassNamed: 'PCARefTestAddParamCaller' superclass: Object slots: #() package: 'PCA-Ref-Test-AddParam'.
	callerSelector := 'pcaRefCallAddParameter:' asSymbol.
	caller compile: callerSelector asString, ' anObject ^ anObject ', oldSelector asString, ' 5'.
	preview := self previewTool: 'refactor_add_parameter' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> newSelector asString.
		'newArgumentName' -> 'extra'. 'defaultExpression' -> 'nil' } asDictionary.
	self applyPreview: preview.
	self deny: (class includesSelector: oldSelector).
	self assert: (class includesSelector: newSelector).
	self assert: ((caller >> callerSelector) sourceCode includesSubstring: 'pcaRefAddOne: 5 extra: nil').
	self assert: (caller new perform: callerSelector with: class new) equals: 5
]

{ #category : 'tests - parameters' }
PharoCAToolRefactoringTest >> testRemoveParameterPreviewAndApply [
	| class caller preview oldSelector newSelector callerSelector |
	class := self newClassNamed: 'PCARefTestRemoveParam' superclass: Object slots: #() package: 'PCA-Ref-Test-RemoveParam'.
	oldSelector := 'pcaRefRemoveOne:unused:' asSymbol.
	newSelector := 'pcaRefRemoveOne:' asSymbol.
	class compile: 'pcaRefRemoveOne: a unused: ignored ^ a'.
	caller := self newClassNamed: 'PCARefTestRemoveParamCaller' superclass: Object slots: #() package: 'PCA-Ref-Test-RemoveParam'.
	callerSelector := 'pcaRefCallRemoveParameter:' asSymbol.
	caller compile: callerSelector asString, ' anObject ^ anObject pcaRefRemoveOne: 5 unused: 9'.
	preview := self previewTool: 'refactor_remove_parameter' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'argumentName' -> 'ignored' } asDictionary.
	self applyPreview: preview.
	self deny: (class includesSelector: oldSelector).
	self assert: (class includesSelector: newSelector).
	self assert: ((caller >> callerSelector) sourceCode includesSubstring: newSelector asString).
	self assert: (caller new perform: callerSelector with: class new) equals: 5
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testPreviewDoesNotMutateImageAndCanBeDiscarded [
	| class preview handle discard |
	class := self newClassNamed: 'PCARefTestDiscard' superclass: Object slots: #() package: 'PCA-Ref-Test-Discard'.
	preview := self previewTool: 'refactor_rename_class' arguments: {
		'className' -> class name. 'newName' -> 'PCARefTestDiscardNew' } asDictionary.
	handle := preview at: 'refactorHandle'.
	self assert: (Smalltalk includesKey: class name asSymbol).
	self deny: (Smalltalk includesKey: #PCARefTestDiscardNew).
	discard := registry executeNamed: 'refactor_discard' arguments: { 'refactorHandle' -> handle } asDictionary.
	self assert: (discard at: 'ok').
	self assert: ((discard at: 'result') at: 'discarded').
	self deny: ((registry executeNamed: 'refactor_preview_details' arguments: { 'refactorHandle' -> handle } asDictionary) at: 'ok')
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testPreviewDetailsArePaginatedAndCursorScoped [
	| class preview first bad oldSelector newSelector |
	class := self newClassNamed: 'PCARefTestDetails' superclass: Object slots: #() package: 'PCA-Ref-Test-Details'.
	oldSelector := 'pcaRefDetailsOld:' asSymbol.
	newSelector := 'pcaRefDetailsNew:' asSymbol.
	class compile: oldSelector asString, ' a ^ a'.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> newSelector asString } asDictionary.
	first := registry executeNamed: 'refactor_preview_details' arguments: {
		'refactorHandle' -> (preview at: 'refactorHandle'). 'limit' -> 1 } asDictionary.
	self assert: (first at: 'ok').
	self assert: (((first at: 'result') at: 'changes') size) equals: 1.
	(((first at: 'result') at: 'page') at: 'nextCursor') ifNotNil: [ :cursor |
		bad := registry executeNamed: 'refactor_preview_details' arguments: {
			'refactorHandle' -> 'refactor-does-not-exist'. 'cursor' -> cursor } asDictionary.
		self deny: (bad at: 'ok') ]
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testStalePreviewIsRejectedWithoutMutation [
	| class preview stale oldSelector newSelector |
	class := self newClassNamed: 'PCARefTestStale' superclass: Object slots: #() package: 'PCA-Ref-Test-Stale'.
	oldSelector := 'pcaRefStaleOld' asSymbol.
	newSelector := 'pcaRefStaleNew' asSymbol.
	class compile: oldSelector asString, ' ^ 1'.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> newSelector asString } asDictionary.
	"Change the exact method from which the preview was derived."
	class compile: oldSelector asString, ' ^ 2'.
	stale := registry executeNamed: 'refactor_apply' arguments: { 'refactorHandle' -> (preview at: 'refactorHandle') } asDictionary.
	self assert: (stale at: 'ok').
	self assert: ((stale at: 'result') at: 'status') equals: 'stale'.
	self assert: (class includesSelector: oldSelector).
	self deny: (class includesSelector: newSelector).
	self assert: ((class >> oldSelector) valueWithReceiver: class new arguments: #()) equals: 2
]

{ #category : 'tests - errors' }
PharoCAToolRefactoringTest >> testNativePreconditionFailureIsStructuredAndCreatesNoHandle [
	| class result oldSelector invalidSelector |
	class := self newClassNamed: 'PCARefTestPrecondition' superclass: Object slots: #() package: 'PCA-Ref-Test-Precondition'.
	oldSelector := 'pcaRefPreconditionOld' asSymbol.
	invalidSelector := 'pcaRefPreconditionNew:' asSymbol.
	class compile: oldSelector asString, ' ^ 1'.
	result := registry executeNamed: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> invalidSelector asString } asDictionary.
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'status') equals: 'precondition_failed'.
	self assert: (registry runtimeHandleRegistryForSession: nil) size equals: 0
]

{ #category : 'tests - journal' }
PharoCAToolRefactoringTest >> testApplyRecordsOneSemanticChangeJournalEntry [
	| class preview before after record oldSelector newSelector |
	class := self newClassNamed: 'PCARefTestJournal' superclass: Object slots: #() package: 'PCA-Ref-Test-Journal'.
	oldSelector := 'pcaRefJournalOld' asSymbol.
	newSelector := 'pcaRefJournalNew' asSymbol.
	class compile: oldSelector asString, ' ^ 1'.
	before := environment changeJournal size.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> oldSelector asString. 'newSelector' -> newSelector asString } asDictionary.
	self applyPreview: preview.
	after := environment changeJournal size.
	self assert: after equals: before + 1.
	record := environment changeJournal entries last.
	self assert: record kind equals: #refactoringApplied.
	self assert: (record metadata at: 'refactoringTool') equals: 'refactor_rename_method'
]


{ #category : 'tests - policy' }
PharoCAToolRefactoringTest >> testCancelledPreviewCreatesNoHandle [
	| class context result selector |
	class := self newClassNamed: 'PCARefTestCancelled' superclass: Object slots: #() package: 'PCA-Ref-Test-Cancelled'.
	selector := 'pcaRefCancelled' asSymbol.
	class compile: selector asString, ' ^ 1'.
	context := PharoCAToolExecutionContext unlimited.
	context cancellationToken cancel.
	result := registry
		executeNamed: 'refactor_rename_method'
		arguments: {
			'className' -> class name.
			'selector' -> selector asString.
			'newSelector' -> 'pcaRefCancelledRenamed' } asDictionary
		context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_cancelled'.
	self assert: (registry runtimeHandleRegistryForSession: nil) size equals: 0.
	self assert: (class includesSelector: selector)
]

{ #category : 'tests - policy' }
PharoCAToolRefactoringTest >> testReadOnlyProfileRejectsRefactoringWithoutMutation [
	| class readOnly result selector |
	class := self newClassNamed: 'PCARefTestReadOnly' superclass: Object slots: #() package: 'PCA-Ref-Test-ReadOnly'.
	selector := 'pcaRefReadOnly' asSymbol.
	class compile: selector asString, ' ^ 1'.
	readOnly := PharoCAToolRegistry default useProfileNamed: 'read-only'; yourself.
	result := readOnly executeNamed: 'refactor_rename_method' arguments: {
		'className' -> class name.
		'selector' -> selector asString.
		'newSelector' -> 'pcaRefReadOnlyRenamed' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_not_allowed'.
	self assert: (readOnly runtimeHandleRegistryForSession: nil) size equals: 0.
	self assert: (class includesSelector: selector).
	self deny: (class includesSelector: 'pcaRefReadOnlyRenamed' asSymbol)
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testAppliedPreviewHandleIsOneShot [
	| class preview handle second selector |
	class := self newClassNamed: 'PCARefTestOneShot' superclass: Object slots: #() package: 'PCA-Ref-Test-OneShot'.
	selector := 'pcaRefOneShotOld' asSymbol.
	class compile: selector asString, ' ^ 1'.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name.
		'selector' -> selector asString.
		'newSelector' -> 'pcaRefOneShotNew' } asDictionary.
	handle := preview at: 'refactorHandle'.
	self applyPreview: preview.
	second := registry executeNamed: 'refactor_apply' arguments: { 'refactorHandle' -> handle } asDictionary.
	self deny: (second at: 'ok').
	self deny: ((registry executeNamed: 'refactor_preview_details' arguments: { 'refactorHandle' -> handle } asDictionary) at: 'ok')
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testPreviewCursorIsScopedToItsHandle [
	| class firstPreview secondPreview firstPage cursor valid wrong |
	class := self newClassNamed: 'PCARefTestCursor' superclass: Object slots: #() package: 'PCA-Ref-Test-Cursor'.
	class compile: 'pcaRefCursorOld: a ^ a'.
	class compile: 'pcaRefCursorCaller ^ self pcaRefCursorOld: 1'.
	firstPreview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> 'pcaRefCursorOld:'. 'newSelector' -> 'pcaRefCursorNew:' } asDictionary.
	firstPage := registry executeNamed: 'refactor_preview_details' arguments: {
		'refactorHandle' -> (firstPreview at: 'refactorHandle'). 'limit' -> 1 } asDictionary.
	self assert: (firstPage at: 'ok').
	cursor := ((firstPage at: 'result') at: 'page') at: 'nextCursor'.
	self assert: cursor notNil.
	valid := registry executeNamed: 'refactor_preview_details' arguments: {
		'refactorHandle' -> (firstPreview at: 'refactorHandle'). 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self assert: (valid at: 'ok').
	secondPreview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> 'pcaRefCursorOld:'. 'newSelector' -> 'pcaRefCursorAlternative:' } asDictionary.
	wrong := registry executeNamed: 'refactor_preview_details' arguments: {
		'refactorHandle' -> (secondPreview at: 'refactorHandle'). 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (wrong at: 'ok')
]

{ #category : 'tests - rename' }
PharoCAToolRefactoringTest >> testRenameClassSideMethodPreviewAndApply [
	| class preview oldSelector newSelector |
	class := self newClassNamed: 'PCARefTestClassSideRename' superclass: Object slots: #() package: 'PCA-Ref-Test-ClassSide'.
	oldSelector := 'pcaRefClassSideOld' asSymbol.
	newSelector := 'pcaRefClassSideNew' asSymbol.
	class class compile: oldSelector asString, ' ^ 123'.
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name.
		'side' -> 'class'.
		'selector' -> oldSelector asString.
		'newSelector' -> newSelector asString } asDictionary.
	self applyPreview: preview.
	self deny: (class class includesSelector: oldSelector).
	self assert: (class class includesSelector: newSelector).
	self assert: (class perform: newSelector) equals: 123
]

{ #category : 'tests - journal' }
PharoCAToolRefactoringTest >> testJournaledRefactoringIsExplicitlyOpaqueForCheckpointRollback [
	| class preview checkpoint record plan selector |
	checkpoint := environment createCheckpointNamed: 'before refactoring'.
	class := self newClassNamed: 'PCARefTestRollbackOpaque' superclass: Object slots: #() package: 'PCA-Ref-Test-RollbackOpaque'.
	selector := 'pcaRefRollbackOld' asSymbol.
	class compile: selector asString, ' ^ 1'.
	"The fixture creation is deliberately outside the assistant journal; only the applied refactoring is journaled."
	preview := self previewTool: 'refactor_rename_method' arguments: {
		'className' -> class name. 'selector' -> selector asString. 'newSelector' -> 'pcaRefRollbackNew' } asDictionary.
	self applyPreview: preview.
	record := environment changeJournal entries last.
	self assert: (PharoCAChangeReview rollbackSafetyFor: record) equals: 'opaque'.
	plan := environment rollbackPlanToCheckpoint: checkpoint.
	self deny: (plan at: 'rollbackable').
	self assert: ((plan at: 'blockers') anySatisfy: [ :each | (each at: 'changeId') = record id ])
]

{ #category : 'tests - contracts' }
PharoCAToolRefactoringTest >> testEveryRefactoringToolHasExpectedPackCapabilityAndExecutionMode [
	| refactoringTools mutators |
	refactoringTools := registry tools select: [ :tool | tool toolPack = #refactoring ].
	self assert: refactoringTools size equals: 16.
	refactoringTools do: [ :tool |
		self assert: tool capability equals: #refactoring ].
	mutators := refactoringTools select: [ :tool |
		#(#refactor_apply) includes: tool toolName ].
	mutators do: [ :tool | self assert: tool executionMode equals: #exclusiveMutation ].
	(refactoringTools reject: [ :tool | mutators includes: tool ]) do: [ :tool |
		self assert: (#(#sequential #parallelSafe) includes: tool executionMode) ]
]

{ #category : 'tests - lifecycle' }
PharoCAToolRefactoringTest >> testPlanSignatureIgnoresVolatileHumanDescriptionButTracksStructuralContent [
	| first second changed firstSignature secondSignature changedSignature |
	first := { {
		'type' -> #ReAddMethodChange.
		'className' -> 'PCARefSignature'.
		'selector' -> 'example'.
		'source' -> 'example ^ 1'.
		'protocol' -> 'testing'.
		'description' -> '!PCARefSignature methodsFor: ''testing'' stamp: ''8/24/2026 20:10'''
	} asDictionary }.
	second := { {
		'type' -> #ReAddMethodChange.
		'className' -> 'PCARefSignature'.
		'selector' -> 'example'.
		'source' -> 'example ^ 1'.
		'protocol' -> 'testing'.
		'description' -> '!PCARefSignature methodsFor: ''testing'' stamp: ''8/24/2026 20:11'''
	} asDictionary }.
	changed := { {
		'type' -> #ReAddMethodChange.
		'className' -> 'PCARefSignature'.
		'selector' -> 'example'.
		'source' -> 'example ^ 2'.
		'protocol' -> 'testing'.
		'description' -> 'arbitrary human text'
	} asDictionary }.
	firstSignature := PharoCARefactoringTool signatureForPlan: first.
	secondSignature := PharoCARefactoringTool signatureForPlan: second.
	changedSignature := PharoCARefactoringTool signatureForPlan: changed.
	self assert: firstSignature equals: secondSignature.
	self deny: firstSignature equals: changedSignature
]
