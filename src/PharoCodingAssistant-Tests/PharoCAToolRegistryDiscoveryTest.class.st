Class {
	#name : #PharoCAToolRegistryDiscoveryTest,
	#superclass : #TestCase,
	#category : #'PharoCodingAssistant-Tests-Tools',
	#package : #'PharoCodingAssistant-Tests',
	#tag : #'Tools'
}

{ #category : #private }
PharoCAToolRegistryDiscoveryTest >> newProbeNamed: className toolName: toolName pack: pack strategy: strategy abstract: abstract [
	| probe |
	probe := (PharoCATool << className
		slots: {};
		package: 'PharoCodingAssistant-Tests') install.

	probe class compile: 'isAbstract ^ ', abstract printString classified: 'testing'.
	probe class compile: 'toolName ^ #', toolName classified: 'definition'.
	probe class compile: 'toolPack ^ #', pack classified: 'definition'.
	probe class compile: 'loadingStrategy ^ #', strategy classified: 'definition'.
	^ probe
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testConcreteSubclassIsDiscoveredWithoutRegistrationList [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolDynamicDiscoveryProbe
		toolName: 'dynamic_discovery_probe'
		pack: 'dynamicProbe'
		strategy: 'lazy'
		abstract: false.
	[
		self assert: (PharoCAToolRegistry discoveredToolClasses includes: probe).
		self assert: (PharoCAToolRegistry discoveredToolPacks includes: #dynamicProbe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testAbstractSubclassIsIgnored [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolAbstractDiscoveryProbe
		toolName: 'abstract_discovery_probe'
		pack: 'dynamicProbe'
		strategy: 'lazy'
		abstract: true.
	[
		self deny: (PharoCAToolRegistry discoveredToolClasses includes: probe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testEagerStrategyActivatesPackByDefault [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolEagerDiscoveryProbe
		toolName: 'eager_discovery_probe'
		pack: 'eagerProbe'
		strategy: 'eager'
		abstract: false.
	[
		self assert: (PharoCAToolRegistry defaultActiveToolPacks includes: #eagerProbe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testLazyStrategyDoesNotActivatePackByDefault [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolLazyDiscoveryProbe
		toolName: 'lazy_discovery_probe'
		pack: 'lazyProbe'
		strategy: 'lazy'
		abstract: false.
	[
		self assert: (PharoCAToolRegistry discoveredToolPacks includes: #lazyProbe).
		self deny: (PharoCAToolRegistry defaultActiveToolPacks includes: #lazyProbe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testDisabledStrategyOmitsTool [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolDisabledDiscoveryProbe
		toolName: 'disabled_discovery_probe'
		pack: 'disabledProbe'
		strategy: 'disabled'
		abstract: false.
	[
		self deny: (PharoCAToolRegistry discoveredToolClasses includes: probe).
		self deny: (PharoCAToolRegistry discoveredToolPacks includes: #disabledProbe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testInvalidLoadingStrategyIsRejected [
	| probe |
	probe := self
		newProbeNamed: #PharoCAToolInvalidStrategyProbe
		toolName: 'invalid_strategy_probe'
		pack: 'invalidStrategyProbe'
		strategy: 'notARealStrategy'
		abstract: false.
	[
		self should: [ PharoCAToolRegistry discoveredToolClasses ] raise: Error
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testDuplicateToolNamesAreRejected [
	| first second |
	first := self
		newProbeNamed: #PharoCAToolDuplicateDiscoveryProbeA
		toolName: 'duplicate_discovery_probe'
		pack: 'duplicateProbe'
		strategy: 'lazy'
		abstract: false.
	second := self
		newProbeNamed: #PharoCAToolDuplicateDiscoveryProbeB
		toolName: 'duplicate_discovery_probe'
		pack: 'duplicateProbe'
		strategy: 'lazy'
		abstract: false.
	[
		self should: [ PharoCAToolRegistry discoveredToolClasses ] raise: Error
	] ensure: [
		first removeFromSystem.
		second removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testMixedStrategiesInsideOnePackAreRejected [
	| eager lazy |
	eager := self
		newProbeNamed: #PharoCAToolMixedStrategyProbeA
		toolName: 'mixed_strategy_probe_a'
		pack: 'mixedStrategyProbe'
		strategy: 'eager'
		abstract: false.
	lazy := self
		newProbeNamed: #PharoCAToolMixedStrategyProbeB
		toolName: 'mixed_strategy_probe_b'
		pack: 'mixedStrategyProbe'
		strategy: 'lazy'
		abstract: false.
	[
		self should: [ PharoCAToolRegistry discoveredToolClasses ] raise: Error
	] ensure: [
		eager removeFromSystem.
		lazy removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testExistingRegistryDiscoversToolLoadedLater [
	| registry probe |
	registry := PharoCAToolRegistry default.
	probe := self
		newProbeNamed: #PharoCAToolLateDiscoveryProbe
		toolName: 'late_discovery_probe'
		pack: 'lateDiscoveryProbe'
		strategy: 'eager'
		abstract: false.
	[
		self deny: (registry tools includes: probe).
		registry synchronizeDefaultTools.
		self assert: (registry tools includes: probe).
		self assert: (PharoCAToolRegistry defaultActivePackNames includes: #lateDiscoveryProbe)
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testExistingSessionReceivesNewEagerPack [
	| registry session probe |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	registry activePackNamesForSession: session.
	probe := self
		newProbeNamed: #PharoCAToolLateEagerSessionProbe
		toolName: 'late_eager_session_probe'
		pack: 'lateEagerSessionProbe'
		strategy: 'eager'
		abstract: false.
	[
		self deny: ((registry activePackNamesForSession: session) includes: 'lateEagerSessionProbe').
		registry synchronizeDefaultTools.
		self assert: ((registry activePackNamesForSession: session) includes: 'lateEagerSessionProbe')
	] ensure: [ probe removeFromSystem ]
]

{ #category : #tests }
PharoCAToolRegistryDiscoveryTest >> testSynchronizePreservesExplicitlyDisabledEagerPack [
	| registry session |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	self assert: ((registry activePackNamesForSession: session) includes: 'core').
	registry deactivatePackNamed: 'core' forSession: session.
	registry synchronizeDefaultTools.
	self deny: ((registry activePackNamesForSession: session) includes: 'core')
]
