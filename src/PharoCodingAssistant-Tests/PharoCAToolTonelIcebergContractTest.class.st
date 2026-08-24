Class { #name : 'PharoCAToolTonelIcebergContractTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Contracts', #package : 'PharoCodingAssistant-Tests', #tag : 'Contracts' }

{ #category : 'tests' }
PharoCAToolTonelIcebergContractTest >> testNewReadOnlyToolsHaveExpectedPackCapabilityAndMode [
	#(PharoCAToolTonelParse PharoCAToolTonelValidatePackage PharoCAToolTonelSerializeClass PharoCAToolTonelExportClass PharoCAToolTonelExportPackage) do: [ :name |
		| tool |
		tool := Smalltalk globals at: name.
		self assert: tool toolPack equals: #tonel.
		self assert: tool capability equals: #inspection.
		self assert: tool executionMode equals: #parallelSafe ].
	#(PharoCAToolIcebergListRepositories PharoCAToolIcebergRepositoryInfo PharoCAToolIcebergStatus PharoCAToolIcebergDiff PharoCAToolIcebergLog PharoCAToolIcebergCommitInfo PharoCAToolIcebergBranches PharoCAToolIcebergRemotes PharoCAToolIcebergPackages) do: [ :name |
		| tool |
		tool := Smalltalk globals at: name.
		self assert: tool toolPack equals: #iceberg.
		self assert: tool capability equals: #inspection.
		self assert: tool executionMode equals: #parallelSafe ]
]

{ #category : 'tests' }
PharoCAToolTonelIcebergContractTest >> testTonelAndIcebergPacksAreLazyAndSessionScoped [
	| registry first second firstNames secondNames |
	registry := PharoCAToolRegistry default.
	first := PharoCASession new.
	second := PharoCASession new.
	firstNames := (registry definitionsForSession: first) collect: [ :each | (each at: 'function') at: 'name' ].
	self deny: (firstNames includes: 'tonel_parse').
	self deny: (firstNames includes: 'iceberg_status').
	registry activatePackNamed: 'tonel' forSession: first.
	registry activatePackNamed: 'iceberg' forSession: first.
	firstNames := (registry definitionsForSession: first) collect: [ :each | (each at: 'function') at: 'name' ].
	secondNames := (registry definitionsForSession: second) collect: [ :each | (each at: 'function') at: 'name' ].
	self assert: (firstNames includes: 'tonel_parse').
	self assert: (firstNames includes: 'iceberg_status').
	self deny: (secondNames includes: 'tonel_parse').
	self deny: (secondNames includes: 'iceberg_status')
]

{ #category : 'tests' }
PharoCAToolTonelIcebergContractTest >> testCatalogCanDiscoverInactiveNewPacks [
	| registry session tonel iceberg |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	tonel := registry searchCatalog: 'tonel' pack: 'tonel' arguments: Dictionary new session: session.
	iceberg := registry searchCatalog: 'iceberg_status' pack: 'iceberg' arguments: Dictionary new session: session.
	self assert: ((tonel at: 'tools') anySatisfy: [ :each | (each at: 'name') = 'tonel_parse' and: [ (each at: 'active') not ] ]).
	self assert: ((iceberg at: 'tools') anySatisfy: [ :each | (each at: 'name') = 'iceberg_status' and: [ (each at: 'active') not ] ])
]

{ #category : 'tests' }
PharoCAToolTonelIcebergContractTest >> testTonelMutationToolsHaveCodingCapabilityAndMutationModes [
	self assert: PharoCAToolTonelImportPreview toolPack equals: #tonel.
	self assert: PharoCAToolTonelImportPreview capability equals: #coding.
	self assert: PharoCAToolTonelImportPreview executionMode equals: #sequential.
	self assert: PharoCAToolTonelImportApply toolPack equals: #tonel.
	self assert: PharoCAToolTonelImportApply capability equals: #coding.
	self assert: PharoCAToolTonelImportApply executionMode equals: #exclusiveMutation
]


{ #category : 'tests' }
PharoCAToolTonelIcebergContractTest >> testIcebergMutationToolsHaveExpectedCapabilitiesAndModes [
	#(PharoCAToolIcebergCommit PharoCAToolIcebergFetch PharoCAToolIcebergPull PharoCAToolIcebergPush PharoCAToolIcebergCreateBranch PharoCAToolIcebergSwitch PharoCAToolIcebergAddRemote PharoCAToolIcebergRemoveRemote PharoCAToolIcebergLoadPackage PharoCAToolIcebergUnloadPackage PharoCAToolIcebergClone PharoCAToolIcebergAddLocalRepository) do: [ :name |
		| tool |
		tool := Smalltalk globals at: name.
		self assert: tool toolPack equals: #iceberg.
		self assert: tool capability equals: #coding.
		self assert: tool executionMode equals: #exclusiveMutation ].
	self assert: PharoCAToolIcebergDiscardChanges toolPack equals: #iceberg.
	self assert: PharoCAToolIcebergDiscardChanges capability equals: #destructive.
	self assert: PharoCAToolIcebergDiscardChanges executionMode equals: #exclusiveMutation
]
