Class {
	#name : 'PharoCABenchmarkNavigation007CacheInvalidationTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> id [
	^ 'navigation-007-cache-invalidation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> title [
	^ 'Diagnose a stateful stale-cache defect'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> prompt [
	^ 'A stateful benchmark fixture understands #displayNameFor: and #renameUser:to:. On a fresh instance, evaluating displayNameFor: #u1 answers ''Ada''. After renameUser: #u1 to: ''Grace'', displayNameFor: #u1 incorrectly still answers ''Ada''. Locate the fixture from these selectors, inspect the repository/cache collaborators, and repair the update path so cached values are invalidated using the cache''s public protocol. Preserve caching for reads and do not bypass or replace the cache.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> difficulty [
	^ 5
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> tags [
	^ #('navigation' 'debugging' 'state' 'cache' 'multi-class')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation007CacheInvalidationTask >> maxIterations [
	^ 36
]
