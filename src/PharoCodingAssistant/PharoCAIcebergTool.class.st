"Shared native Iceberg helpers used by the assistant's Iceberg tool pack. Lookup is explicit and ambiguous duplicate repository names are rejected."
Class {
	#name : 'PharoCAIcebergTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'testing' }
PharoCAIcebergTool class >> isAbstract [ ^ self = PharoCAIcebergTool ]

{ #category : 'definition' }
PharoCAIcebergTool class >> toolPack [ ^ #iceberg ]

{ #category : 'definition' }
PharoCAIcebergTool class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAIcebergTool class >> executionMode [ ^ #parallelSafe ]

{ #category : 'private' }
PharoCAIcebergTool class >> locationStringForRepository: repository [
	| location |
	location := repository location.
	location ifNil: [ ^ nil ].
	^ [ location fullName ] on: Error do: [ :error | location printString ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> repositoryNamed: aString [
	| matches |
	matches := IceRepository repositories select: [ :repository | repository name = aString ].
	matches isEmpty ifTrue: [ Error signal: 'Iceberg repository not found: ', aString ].
	matches size > 1 ifTrue: [
		Error signal: 'Iceberg repository name is ambiguous: ', aString,
			'. Registered matches: ',
			((matches collect: [ :repository | (self locationStringForRepository: repository) ifNil: [ '<no location>' ] ]) joinUsing: ', ') ].
	^ matches first
]

{ #category : 'private' }
PharoCAIcebergTool class >> repositorySummary: repository [
	| location valid |
	location := repository location.
	valid := location notNil and: [
		location exists and: [
			(location / '.git') exists or: [
				(location / 'HEAD') exists and: [ (location / 'config') exists ] ] ] ].
	^ {
		'name' -> repository name.
		'repositoryClass' -> repository class name.
		'location' -> (self locationStringForRepository: repository).
		'valid' -> valid
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> requireValidRepository: repository [
	| location valid |
	location := repository location.
	valid := location notNil and: [
		location exists and: [
			(location / '.git') exists or: [
				(location / 'HEAD') exists and: [ (location / 'config') exists ] ] ] ].
	valid ifFalse: [ Error signal: 'Iceberg repository is missing or invalid: ', repository name ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> changeTypeFor: change [
	((change respondsTo: #isAddition) and: [ change isAddition ]) ifTrue: [ ^ 'addition' ].
	((change respondsTo: #isRemoval) and: [ change isRemoval ]) ifTrue: [ ^ 'removal' ].
	((change respondsTo: #isModification) and: [ change isModification ]) ifTrue: [ ^ 'modification' ].
	((change respondsTo: #isNoModification) and: [ change isNoModification ]) ifTrue: [ ^ 'unchanged' ].
	^ change class name
]

{ #category : 'private' }
PharoCAIcebergTool class >> definitionSummaryFor: definition [
	| result |
	definition ifNil: [ ^ nil ].
	(definition isKindOf: MCDefinition) ifFalse: [ ^ nil ].
	result := OrderedDictionary new.
	result at: 'definitionClass' put: definition class name.
	(definition respondsTo: #name) ifTrue: [
		definition name ifNotNil: [ :name | result at: 'name' put: name asString ] ].
	(definition respondsTo: #className) ifTrue: [
		definition className ifNotNil: [ :name | result at: 'className' put: name asString ] ].
	(definition respondsTo: #selector) ifTrue: [
		definition selector ifNotNil: [ :selector | result at: 'selector' put: selector asString ] ].
	(definition respondsTo: #packageName) ifTrue: [
		definition packageName ifNotNil: [ :name | result at: 'package' put: name asString ] ].
	(definition respondsTo: #protocol) ifTrue: [
		definition protocol ifNotNil: [ :protocol | result at: 'protocol' put: protocol asString ] ].
	^ result asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> changeSummaryFor: change path: path includeDefinitions: includeDefinitions [
	| result |
	result := OrderedDictionary new.
	result
		at: 'path' put: path;
		at: 'change' put: (self changeTypeFor: change).
	includeDefinitions ifTrue: [
		| before after |
		before := (change respondsTo: #leftContents)
			ifTrue: [ self definitionSummaryFor: change leftContents ]
			ifFalse: [ nil ].
		after := (change respondsTo: #rightContents)
			ifTrue: [ self definitionSummaryFor: change rightContents ]
			ifFalse: [ nil ].
		before ifNotNil: [ result at: 'before' put: before ].
		after ifNotNil: [ result at: 'after' put: after ] ].
	^ result asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> collectChangedNodesFrom: node parentPath: parentPath includeDefinitions: includeDefinitions into: results context: context [
	| key path change |
	node children doWithIndex: [ :child :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		key := child key asString.
		path := parentPath isEmpty ifTrue: [ key ] ifFalse: [ parentPath, '/', key ].
		change := child value.
		((change respondsTo: #hasChanges) and: [ change hasChanges ]) ifTrue: [
			results add: (self changeSummaryFor: change path: path includeDefinitions: includeDefinitions) ].
		self
			collectChangedNodesFrom: child
			parentPath: path
			includeDefinitions: includeDefinitions
			into: results
			context: context ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> changesForRepository: repository includeDefinitions: includeDefinitions context: context [
	| diff results |
	context checkActive.
	diff := self nativeDo: [ repository workingCopyDiff ].
	results := OrderedCollection new.
	self
		collectChangedNodesFrom: diff tree
		parentPath: ''
		includeDefinitions: includeDefinitions
		into: results
		context: context.
	^ (results asSortedCollection: [ :a :b | (a at: 'path') <= (b at: 'path') ]) asArray
]

{ #category : 'private' }
PharoCAIcebergTool class >> commitSummaryFor: commit [
	| ancestors |
	ancestors := [ commit ancestors ] on: Error do: [ :error | #() ].
	^ {
		'id' -> commit id asString.
		'shortId' -> commit shortId asString.
		'comment' -> commit comment trimBoth.
		'author' -> commit author asString.
		'datetime' -> commit datetime asString.
		'parentIds' -> ((ancestors collect: [ :each | each id asString ]) asArray)
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> branchSummaryFor: branch [
	^ {
		'name' -> branch name asString.
		'fullName' -> branch fullname asString.
		'local' -> branch isLocal.
		'head' -> branch isHead.
		'description' -> branch description asString
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> remoteSummaryFor: remote [
	^ {
		'name' -> remote name asString.
		'url' -> remote url asString.
		'host' -> remote host asString
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> packageSummaryFor: package [
	^ {
		'name' -> package name asString.
		'loaded' -> package isLoaded.
		'dirty' -> package isDirty
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> remoteNamed: remoteName inRepository: repository [
	^ self nativeDo: [ repository remoteNamed: remoteName ifAbsent: [ Error signal: 'Iceberg remote not found: ', remoteName ] ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> packageNamed: packageName inRepository: repository [
	^ repository workingCopy packageNamed: packageName ifAbsent: [ Error signal: 'Iceberg package not found: ', packageName ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> headIdForRepository: repository [
	| head |
	head := repository headCommit.
	head isNoCommit ifTrue: [ ^ nil ].
	^ head id asString
]

{ #category : 'private' }
PharoCAIcebergTool class >> mutationStateForRepository: repository context: context [
	| branchResult headResult statusResult |
	"Mutation journaling must not add incidental libgit FFI calls around the actual operation.
	Git metadata comes from the repository working tree through the bounded process runner;
	the Iceberg working-copy package count remains image-local."
	branchResult := self runGitArguments: #('rev-parse' '--abbrev-ref' 'HEAD') inRepository: repository context: context.
	headResult := self runGitArguments: #('rev-parse' 'HEAD') inRepository: repository context: context.
	statusResult := self runGitArguments: #('status' '--porcelain') inRepository: repository context: context.
	^ {
		'branch' -> (branchResult at: 'output') trimBoth.
		'head' -> (headResult at: 'output') trimBoth.
		'gitWorkingTreeModified' -> (statusResult at: 'output') trimBoth isNotEmpty.
		'packageCount' -> repository workingCopy packages size
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> ensureRepositoryNameAvailable: aString [
	(IceRepository repositories anySatisfy: [ :repository | repository name = aString ]) ifTrue: [
		Error signal: 'Iceberg repository name is already registered: ', aString ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> nativeDo: aBlock [
	"Keep local Iceberg calls direct.  In particular, do not manufacture stack overflows in an attempt to obtain FFI headroom: Pharo 14/libgit transport callouts can crash the VM when entered near a stack-page boundary.  Network transport is isolated through #runGitArguments:workingDirectory:context: instead."
	^ aBlock value
]

{ #category : 'private' }
PharoCAIcebergTool class >> gitCommandRunnerFor: context [
	^ context workspaceCommandRunner ifNil: [ PharoCAWorkspaceCommandRunner new ]
]

{ #category : 'private' }
PharoCAIcebergTool class >> runGitArguments: arguments workingDirectory: directory context: context [
	| runner result |
	context checkActive.
	runner := self gitCommandRunnerFor: context.
	runner supported ifFalse: [
		Error signal: 'Git transport is not supported on this platform by the configured command runner' ].
	result := runner
		runExecutable: 'git'
		arguments: arguments
		workingDirectory: directory
		timeoutSeconds: 120
		maximumCaptureCharacters: 65536.
	context checkActive.
	(result at: 'timedOut') ifTrue: [ Error signal: 'Git transport timed out' ].
	(result at: 'exitCode') = 0 ifFalse: [
		Error signal: 'Git command failed (exit ', (result at: 'exitCode') asString, '): ', (result at: 'output') trimBoth ].
	^ result
]

{ #category : 'private' }
PharoCAIcebergTool class >> runGitArguments: arguments inRepository: repository context: context [
	| location |
	location := repository location.
	location ifNil: [ Error signal: 'Iceberg repository has no local working-tree location: ', repository name ].
	^ self runGitArguments: arguments workingDirectory: location context: context
]

{ #category : 'private' }
PharoCAIcebergTool class >> nativeWorkerDo: aBlock [
	| semaphore result failure |
	semaphore := Semaphore new.
	[
		[ result := aBlock value ]
			on: Error
			do: [ :error | failure := error ].
		semaphore signal
	] fork.
	semaphore wait.
	failure ifNotNil: [ failure signal ].
	^ result
]

{ #category : 'private' }
PharoCAIcebergTool class >> sourceRootForRepository: repository [
	| location projectFile metadata sourceDirectory sourceRoot |
	location := repository location.
	location ifNil: [ Error signal: 'Iceberg repository has no local working-tree location: ', repository name ].
	projectFile := location / '.project'.
	sourceDirectory := ''.
	projectFile exists ifTrue: [
		metadata := STON fromString: projectFile contents.
		metadata isDictionary ifTrue: [
			sourceDirectory := metadata
				at: #srcDirectory
				ifAbsent: [ metadata at: 'srcDirectory' ifAbsent: [ '' ] ] ] ].
	sourceDirectory := sourceDirectory asString.
	((sourceDirectory findTokens: '/\\') includes: '..') ifTrue: [
		Error signal: 'Iceberg source directory must stay within the repository: ', sourceDirectory ].
	sourceRoot := sourceDirectory isEmpty
		ifTrue: [ location ]
		ifFalse: [ location / sourceDirectory ].
	^ sourceRoot
]

{ #category : 'private' }
PharoCAIcebergTool class >> packageNamesChangedFrom: oldHead to: newHead inRepository: repository context: context [
	| result sourceRoot location sourcePrefix names |
	oldHead = newHead ifTrue: [ ^ #() ].
	result := self
		runGitArguments: { 'diff'. '--name-only'. oldHead. newHead }
		inRepository: repository
		context: context.
	location := repository location fullName.
	sourceRoot := (self sourceRootForRepository: repository) fullName.
	sourcePrefix := sourceRoot = location
		ifTrue: [ '' ]
		ifFalse: [ (sourceRoot allButFirst: location size) trimBoth: [ :char | char = $/ or: [ char = $\\ ] ] ].
	names := Set new.
	(result at: 'output') lines do: [ :line |
		| relative tokens |
		relative := line trimBoth.
		relative isEmpty ifFalse: [
			sourcePrefix isEmpty
				ifFalse: [
					((relative = sourcePrefix) or: [ relative beginsWith: sourcePrefix, '/' ])
						ifTrue: [ relative := relative allButFirst: sourcePrefix size. relative := relative trimLeft: [ :char | char = $/ ] ]
						ifFalse: [ relative := '' ] ].
			relative isEmpty ifFalse: [
				tokens := relative findTokens: '/'.
				tokens ifNotEmpty: [ names add: tokens first ] ] ] ].
	^ names asArray sorted
]

{ #category : 'private' }
PharoCAIcebergTool class >> loadTonelPackageNamed: packageName fromRepository: repository context: context [
	| directory payloads payload loader |
	directory := (self sourceRootForRepository: repository) / packageName.
	(directory exists and: [ (directory / 'package.st') exists ]) ifFalse: [
		^ self unloadPackageNamedFromImageIfPresent: packageName ].
	payloads := OrderedCollection new.
	(directory children select: [ :each | each isFile and: [ each extension = 'st' ] ]) do: [ :file |
		context checkActive.
		payloads add: { 'name' -> file basename. 'source' -> file contents } asDictionary ].
	payload := PharoCATonelTool
		packagePayloadForName: packageName
		files: payloads
		context: context.
	loader := MCPackageLoader new.
	loader updatePackage: (MCPackage named: packageName) withSnapshot: (payload at: 'snapshot'); load.
	^ true
]

{ #category : 'private' }
PharoCAIcebergTool class >> unloadPackageNamedFromImageIfPresent: packageName [
	| package loader |
	package := PackageOrganizer default packageNamed: packageName ifAbsent: [ ^ false ].
	loader := MCPackageLoader new.
	loader updatePackage: (MCPackage named: packageName) withSnapshot: MCSnapshot empty; load.
	PackageOrganizer default packageNamed: packageName ifPresent: [ :live | PackageOrganizer default removePackage: live ].
	^ true
]

{ #category : 'private' }
PharoCAIcebergTool class >> synchronizeImagePackagesFrom: oldHead to: newHead repository: repository context: context [
	| packageNames |
	packageNames := self packageNamesChangedFrom: oldHead to: newHead inRepository: repository context: context.
	packageNames doWithIndex: [ :packageName :index |
		(index \\ 10 = 0) ifTrue: [ context checkActive ].
		self loadTonelPackageNamed: packageName fromRepository: repository context: context ].
	^ packageNames
]

{ #category : 'private' }
PharoCAIcebergTool class >> synchronizeManagedPackagesToRepository: repository context: context [
	| sourceRoot packageNames |
	sourceRoot := self sourceRootForRepository: repository.
	sourceRoot ensureCreateDirectory.
	packageNames := repository workingCopy packages collect: [ :each | each name asString ].
	packageNames := packageNames select: [ :name | (PackageOrganizer default packageNamed: name ifAbsent: [ nil ]) notNil ].
	packageNames := packageNames asSet asArray sorted.
	packageNames doWithIndex: [ :packageName :index |
		| packageDirectory |
		(index \\ 10 = 0) ifTrue: [ context checkActive ].
		packageDirectory := sourceRoot / packageName.
		packageDirectory exists ifTrue: [ packageDirectory ensureDeleteAll ].
		(TonelWriter on: sourceRoot) writeSnapshot: (MCPackage named: packageName) snapshot ].
	^ packageNames
]

{ #category : 'private' }
PharoCAIcebergTool class >> gitCommitSummaryForRevision: revision inRepository: repository context: context [
	| id shortId author datetime parents comment parentTokens |
	id := ((self runGitArguments: { 'rev-parse'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	shortId := ((self runGitArguments: { 'rev-parse'. '--short'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	author := ((self runGitArguments: { 'log'. '-1'. '--format=%an <%ae>'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	datetime := ((self runGitArguments: { 'log'. '-1'. '--format=%aI'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	parents := ((self runGitArguments: { 'rev-list'. '--parents'. '-n'. '1'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	parentTokens := parents findTokens: Character space.
	parentTokens := parentTokens size > 1 ifTrue: [ parentTokens allButFirst asArray ] ifFalse: [ #() ].
	comment := ((self runGitArguments: { 'log'. '-1'. '--format=%B'. revision } inRepository: repository context: context) at: 'output') trimBoth.
	^ {
		'id' -> id.
		'shortId' -> shortId.
		'comment' -> comment.
		'author' -> author.
		'datetime' -> datetime.
		'parentIds' -> parentTokens
	} asDictionary
]

{ #category : 'private' }
PharoCAIcebergTool class >> gitStatusPorcelainForRepository: repository context: context [
	^ ((self runGitArguments: #('status' '--porcelain') inRepository: repository context: context) at: 'output') trimBoth
]

{ #category : 'private' }
PharoCAIcebergTool class >> refreshWorkingCopyReferenceToHeadForRepository: repository [
	"Do not ask Iceberg/libgit to resolve HEAD here.  On the supplied Pharo 14 VM even a shallow git_repository_head call can segfault when entered with limited FFI stack headroom.  Git mutations are therefore authoritative on disk and the assistant keeps only Iceberg's image-side package dirty cache aligned.  Read-only Git metadata is obtained through the bounded git process runner."
	| workingCopy |
	workingCopy := repository workingCopy.
	workingCopy packages do: [ :package | package beDirty: false ].
	^ workingCopy
]


{ #category : 'private' }
PharoCAIcebergTool class >> repositoryRelativePathForFileReference: fileReference inRepository: repository [
	| root path relative |
	root := repository location fullName.
	path := fileReference fullName.
	(path beginsWith: root) ifFalse: [ Error signal: 'Path is outside Iceberg repository: ', path ].
	relative := path allButFirst: root size.
	relative := relative trimLeft: [ :char | char = $/ or: [ char = $\ ] ].
	^ relative copyReplaceAll: '\' with: '/'
]

{ #category : 'private' }
PharoCAIcebergTool class >> restorePackageNamed: packageName fromHeadInRepository: repository context: context [
	| packageDirectory relative treeResult |
	packageDirectory := (self sourceRootForRepository: repository) / packageName.
	relative := self repositoryRelativePathForFileReference: packageDirectory inRepository: repository.
	packageDirectory exists ifTrue: [ packageDirectory ensureDeleteAll ].
	treeResult := self runGitArguments: { 'ls-tree'. '--name-only'. 'HEAD'. '--'. relative } inRepository: repository context: context.
	(treeResult at: 'output') trimBoth isNotEmpty ifTrue: [
		self runGitArguments: { 'checkout'. 'HEAD'. '--'. relative } inRepository: repository context: context ].
	self loadTonelPackageNamed: packageName fromRepository: repository context: context.
	(repository workingCopy packageNamed: packageName ifAbsent: [ nil ]) ifNotNil: [ :package | package beDirty: false ].
	^ true
]
