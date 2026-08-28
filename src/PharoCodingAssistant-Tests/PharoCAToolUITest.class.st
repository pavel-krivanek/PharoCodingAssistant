Class {
	#name : 'PharoCAToolUITest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolUITest >> registry [ ^ PharoCAToolRegistry default useProfileNamed: 'full'; yourself ]

{ #category : 'tests' }
PharoCAToolUITest >> testUIPackIsLazyAndDiscoverable [
	| registry session names before after |
	registry := self registry.
	session := PharoCASession new.
	before := registry llmDefinitionsForSession: session.
	self deny: (before anySatisfy: [ :definition | definition name = 'ui_screenshot' ]).
	registry activatePackNamed: 'ui' forSession: session.
	after := registry llmDefinitionsForSession: session.
	names := after collect: [ :definition | definition name ].
	self assert: (names includes: 'ui_list_windows').
	self assert: (names includes: 'ui_screenshot')
]

{ #category : 'tests' }
PharoCAToolUITest >> testListWindowsReturnsHandleAndMetadataForRealSystemWindow [
	| registry window result rows row object |
	registry := self registry.
	window := SystemWindow new.
	window setLabel: 'PCA054 Window'; bounds: ((10 @ 10) extent: 100 @ 60); openInWorld.
	[
		result := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		self assert: (result at: 'ok').
		rows := (result at: 'result') at: 'windows'.
		row := rows detect: [ :each | (each at: 'title') = 'PCA054 Window' ].
		self assert: ((row at: 'bounds') at: 'width') > 0.
		object := (registry objectHandleRegistryForSession: nil) objectAt: (row at: 'handle').
		self assert: object identicalTo: window
	] ensure: [ window delete ]
]

{ #category : 'tests' }
PharoCAToolUITest >> testMorphScreenshotCreatesPNGArtifactWithoutBinaryTextPayload [
	| registry morph handle result descriptor artifact serialized |
	registry := self registry.
	morph := Morph new color: Color red; extent: 24 @ 16; yourself.
	handle := (registry objectHandleRegistryForSession: nil) add: morph.
	result := registry executeNamed: 'ui_screenshot' arguments: { 'target' -> 'morph'. 'handle' -> handle } asDictionary.
	self assert: (result at: 'ok').
	descriptor := ((result at: 'result') at: 'artifact').
	self assert: (descriptor at: 'mimeType') equals: 'image/png'.
	self assert: (descriptor at: 'url') equals: '/artifacts/', (descriptor at: 'artifactId').
	artifact := registry environment artifactStore artifactAt: (descriptor at: 'artifactId').
	self assert: artifact bytes first equals: 137.
	self assert: (artifact bytes copyFrom: 2 to: 4) equals: #[80 78 71].
	serialized := STONJSON toString: result.
	self assert: serialized size < 3000.
	self deny: (serialized includesSubstring: 'base64')
]

{ #category : 'tests' }
PharoCAToolUITest >> testRectangleScreenshotUsesRequestedDimensions [
	| result artifact |
	result := self registry executeNamed: 'ui_screenshot' arguments: {
		'target' -> 'rectangle'. 'x' -> 0. 'y' -> 0. 'width' -> 10. 'height' -> 8 } asDictionary.
	self assert: (result at: 'ok').
	artifact := (result at: 'result') at: 'artifact'.
	self assert: ((artifact at: 'metadata') at: 'width') equals: 10.
	self assert: ((artifact at: 'metadata') at: 'height') equals: 8
]

{ #category : 'tests' }
PharoCAToolUITest >> testWindowTargetRejectsNonWindowMorph [
	| registry morph handle result |
	registry := self registry.
	morph := Morph new extent: 10 @ 10.
	handle := (registry objectHandleRegistryForSession: nil) add: morph.
	result := registry executeNamed: 'ui_screenshot' arguments: { 'target' -> 'window'. 'handle' -> handle } asDictionary.
	self deny: (result at: 'ok')
]

{ #category : 'tests' }
PharoCAToolUITest >> testRectangleOutsideWorldIsRejected [
	| bounds result |
	bounds := PharoCAUICapture worldBounds.
	result := self registry executeNamed: 'ui_screenshot' arguments: {
		'target' -> 'rectangle'. 'x' -> bounds right. 'y' -> bounds bottom. 'width' -> 10. 'height' -> 10 } asDictionary.
	self deny: (result at: 'ok')
]

{ #category : 'tests' }
PharoCAToolUITest >> testScreenshotHonorsCancellationBeforeCapture [
	| registry token context result |
	registry := self registry.
	token := PharoCACancellationToken new cancel.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: 1000 progressDo: [ :ignored | ].
	result := registry executeNamed: 'ui_screenshot' arguments: { 'target' -> 'world' } asDictionary context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_cancelled'
]

{ #category : 'tests' }
PharoCAToolUITest >> testWorldScreenshotCreatesImageArtifact [
	| registry result artifact |
	registry := self registry.
	result := registry executeNamed: 'ui_screenshot' arguments: { 'target' -> 'world' } asDictionary.
	self assert: (result at: 'ok').
	artifact := (result at: 'result') at: 'artifact'.
	self assert: (artifact at: 'mimeType') equals: 'image/png'.
	self assert: ((artifact at: 'metadata') at: 'target') equals: 'world'.
	self assert: ((artifact at: 'metadata') at: 'width') > 0.
	self assert: ((artifact at: 'metadata') at: 'height') > 0
]

{ #category : 'tests' }
PharoCAToolUITest >> testWindowScreenshotUsesHandleReturnedByWindowList [
	| registry window listed row result artifact |
	registry := self registry.
	window := SystemWindow new.
	window setLabel: 'PCA054 Capture Window'; bounds: ((12 @ 12) extent: 90 @ 50); openInWorld.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA054 Capture Window' ]).
		result := registry executeNamed: 'ui_screenshot' arguments: { 'target' -> 'window'. 'handle' -> (row at: 'handle') } asDictionary.
		self assert: (result at: 'ok').
		artifact := (result at: 'result') at: 'artifact'.
		self assert: ((artifact at: 'metadata') at: 'target') equals: 'window'.
		self assert: (artifact at: 'sizeBytes') > 8
	] ensure: [ window delete ]
]

{ #category : 'tests' }
PharoCAToolUITest >> testWindowListPaginationReturnsContinuation [
	| registry first second page cursor |
	registry := self registry.
	first := SystemWindow new setLabel: 'PCA054 Page A'; bounds: ((5 @ 5) extent: 60 @ 30); openInWorld; yourself.
	second := SystemWindow new setLabel: 'PCA054 Page B'; bounds: ((70 @ 5) extent: 60 @ 30); openInWorld; yourself.
	[
		page := registry executeNamed: 'ui_list_windows' arguments: { 'limit' -> 1 } asDictionary.
		self assert: (page at: 'ok').
		cursor := ((page at: 'result') at: 'page') at: 'nextCursor'.
		self deny: cursor isNil.
		page := registry executeNamed: 'ui_list_windows' arguments: { 'limit' -> 1. 'cursor' -> cursor } asDictionary.
		self assert: (page at: 'ok').
		self assert: (((page at: 'result') at: 'windows') size) equals: 1
	] ensure: [ first delete. second delete ]
]

{ #category : 'tests' }
PharoCAToolUITest >> testHeadlessCaptureExecutesUIBlockDirectly [
	| active observed |
	active := Processor activeProcess.
	observed := PharoCAUICapture onUIProcess: [ Processor activeProcess ].
	self assert: observed identicalTo: active
]
