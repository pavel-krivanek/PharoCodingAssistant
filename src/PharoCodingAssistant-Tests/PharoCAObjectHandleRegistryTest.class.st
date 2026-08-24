Class { #name : 'PharoCAObjectHandleRegistryTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'tests' }
PharoCAObjectHandleRegistryTest >> testAddLookupAndRelease [
	| registry object handle |
	registry := PharoCAObjectHandleRegistry new.
	object := OrderedCollection with: 1.
	handle := registry add: object.
	self assert: handle equals: 'obj-1'.
	self assert: (registry objectAt: handle) identicalTo: object.
	self assert: registry size equals: 1.
	self assert: (registry release: handle).
	self deny: (registry release: handle).
	self should: [ registry objectAt: handle ] raise: Error
]

{ #category : 'tests' }
PharoCAObjectHandleRegistryTest >> testTTLExpiresAndActiveLookupExtendsLifetime [
	| registry now handle |
	now := 1000.
	registry := PharoCAObjectHandleRegistry new.
	registry ttlMilliseconds: 100; clockBlock: [ now ].
	handle := registry add: Object new.
	now := 1050.
	registry objectAt: handle.
	now := 1120.
	self assert: registry size equals: 1.
	now := 1160.
	self assert: registry size equals: 0.
	self should: [ registry objectAt: handle ] raise: Error
]

{ #category : 'tests' }
PharoCAObjectHandleRegistryTest >> testTTLValidation [
	self should: [ PharoCAObjectHandleRegistry new ttlMilliseconds: 0 ] raise: Error
]

{ #category : 'tests' }
PharoCAObjectHandleRegistryTest >> testRegistryScopesHandlesBySession [
	| tools first second firstRegistry secondRegistry handle |
	tools := PharoCAToolRegistry default.
	first := PharoCASession new.
	second := PharoCASession new.
	firstRegistry := tools objectHandleRegistryForSession: first.
	secondRegistry := tools objectHandleRegistryForSession: second.
	self deny: firstRegistry identicalTo: secondRegistry.
	handle := firstRegistry add: Object new.
	self should: [ secondRegistry objectAt: handle ] raise: Error
]

{ #category : 'tests' }
PharoCAObjectHandleRegistryTest >> testClearingSessionStateReleasesHandlesAndTestRuns [
	| tools session objects tests handle |
	tools := PharoCAToolRegistry default.
	session := PharoCASession new.
	objects := tools objectHandleRegistryForSession: session.
	tests := tools testRunStoreForSession: session.
	handle := objects add: Object new.
	tests addSpec: Dictionary new result: PharoCATestResult new.
	tools clearPackStateForSession: session.
	self should: [ objects objectAt: handle ] raise: Error.
	self assert: tests size equals: 1.
	self deny: (tools testRunStoreForSession: session) identicalTo: tests
]
