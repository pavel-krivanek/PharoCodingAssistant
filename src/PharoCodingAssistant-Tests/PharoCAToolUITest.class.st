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
	#('ui_window_info' 'ui_window_activate' 'ui_window_set_state' 'ui_window_set_bounds' 'ui_window_close' 'ui_screenshot') do: [ :name | self assert: (names includes: name) ]
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


{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowListReusesStableHandleAcrossCalls [
	| registry window first second firstRow secondRow |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Stable Handle'; bounds: ((20 @ 20) extent: 100 @ 60); openInWorld; yourself.
	[
		first := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		second := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		firstRow := (((first at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Stable Handle' ]).
		secondRow := (((second at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Stable Handle' ]).
		self assert: (firstRow at: 'handle') equals: (secondRow at: 'handle')
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowInfoUsesListedHandleAndReturnsModelMetadata [
	| registry window listed row result info |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Info Window'; bounds: ((22 @ 22) extent: 110 @ 70); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Info Window' ]).
		result := registry executeNamed: 'ui_window_info' arguments: { 'handle' -> (row at: 'handle') } asDictionary.
		self assert: (result at: 'ok').
		info := result at: 'result'.
		self assert: (info at: 'title') equals: 'PCA065 Info Window'.
		self assert: (info at: 'open').
		self assert: (info at: 'windowClass') equals: 'SystemWindow'
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowSetBoundsMovesAndResizesListedWindow [
	| registry window listed row result bounds |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Bounds Window'; bounds: ((25 @ 25) extent: 90 @ 50); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Bounds Window' ]).
		result := registry executeNamed: 'ui_window_set_bounds' arguments: {
			'handle' -> (row at: 'handle'). 'x' -> 35. 'y' -> 45. 'width' -> 130. 'height' -> 80 } asDictionary.
		self assert: (result at: 'ok').
		bounds := ((result at: 'result') at: 'bounds').
		self assert: (bounds at: 'x') equals: 35.
		self assert: (bounds at: 'y') equals: 45.
		self assert: (bounds at: 'width') equals: 130.
		self assert: (bounds at: 'height') equals: 80
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowCollapseAndExpandThroughStateTool [
	| registry window listed row handle result |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 State Window'; bounds: ((30 @ 30) extent: 100 @ 60); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 State Window' ]).
		handle := row at: 'handle'.
		result := registry executeNamed: 'ui_window_set_state' arguments: { 'handle' -> handle. 'state' -> 'collapsed' } asDictionary.
		self assert: (result at: 'ok').
		self assert: ((result at: 'result') at: 'collapsed').
		result := registry executeNamed: 'ui_window_set_state' arguments: { 'handle' -> handle. 'state' -> 'expanded' } asDictionary.
		self assert: (result at: 'ok').
		self deny: ((result at: 'result') at: 'collapsed')
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowActivateAcceptsListedWindow [
	| registry window listed row result |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Activate Window'; bounds: ((32 @ 32) extent: 100 @ 60); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Activate Window' ]).
		result := registry executeNamed: 'ui_window_activate' arguments: { 'handle' -> (row at: 'handle') } asDictionary.
		self assert: (result at: 'ok').
		self assert: ((result at: 'result') at: 'open')
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowCloseForceDeletesAndInvalidatesHandleForWindowTools [
	| registry window listed row handle result info |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Close Window'; bounds: ((34 @ 34) extent: 100 @ 60); openInWorld; yourself.
	listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
	row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Close Window' ]).
	handle := row at: 'handle'.
	result := registry executeNamed: 'ui_window_close' arguments: { 'handle' -> handle. 'force' -> true } asDictionary.
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'closed').
	info := registry executeNamed: 'ui_window_info' arguments: { 'handle' -> handle } asDictionary.
	self deny: (info at: 'ok')
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowToolsRejectNonWindowHandles [
	| registry morph handle result |
	registry := self registry.
	morph := Morph new extent: 10 @ 10.
	handle := (registry objectHandleRegistryForSession: nil) add: morph.
	result := registry executeNamed: 'ui_window_info' arguments: { 'handle' -> handle } asDictionary.
	self deny: (result at: 'ok')
]


{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowSetStateRejectsUnknownState [
	| registry window listed row result |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Invalid State'; bounds: ((36 @ 36) extent: 100 @ 60); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Invalid State' ]).
		result := registry executeNamed: 'ui_window_set_state' arguments: { 'handle' -> (row at: 'handle'). 'state' -> 'floating' } asDictionary.
		self deny: (result at: 'ok').
		self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'.
		self assert: (((result at: 'error') at: 'message') includesSubstring: 'collapsed')
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowSetBoundsRequiresAtLeastOneGeometryField [
	| registry window listed row result |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Missing Bounds'; bounds: ((38 @ 38) extent: 100 @ 60); openInWorld; yourself.
	[
		listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
		row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Missing Bounds' ]).
		result := registry executeNamed: 'ui_window_set_bounds' arguments: { 'handle' -> (row at: 'handle') } asDictionary.
		self deny: (result at: 'ok').
		self assert: (((result at: 'error') at: 'message') includesSubstring: 'requires at least one')
	] ensure: [ window delete ]
]

{ #category : 'tests-065' }
PharoCAToolUITest >> testWindowCloseWithoutForceClosesPlainSystemWindow [
	| registry window listed row result |
	registry := self registry.
	window := SystemWindow new setLabel: 'PCA065 Normal Close'; bounds: ((40 @ 40) extent: 100 @ 60); openInWorld; yourself.
	listed := registry executeNamed: 'ui_list_windows' arguments: Dictionary new.
	row := (((listed at: 'result') at: 'windows') detect: [ :each | (each at: 'title') = 'PCA065 Normal Close' ]).
	result := registry executeNamed: 'ui_window_close' arguments: { 'handle' -> (row at: 'handle') } asDictionary.
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'closed').
	self deny: ((result at: 'result') at: 'force')
]
