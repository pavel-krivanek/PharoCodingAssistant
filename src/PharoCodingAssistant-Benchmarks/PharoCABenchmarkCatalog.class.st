"Public benchmark catalog. Concrete task specifications live in one PharoCABenchmarkTask subclass per task. Expected answers and hidden evaluators deliberately do not live in this repository."
Class {
	#name : 'PharoCABenchmarkCatalog',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Core',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Core'
}

{ #category : 'tasks' }
PharoCABenchmarkCatalog class >> allTasks [
	^ (PharoCABenchmarkTask subclasses collect: [ :taskClass | taskClass new ])
		sorted: [ :left :right | left id < right id ]
]

{ #category : 'tasks' }
PharoCABenchmarkCatalog class >> tasksWithIdPrefix: aString [
	^ self allTasks select: [ :task | task id beginsWith: aString ]
]

{ #category : 'tasks' }
PharoCABenchmarkCatalog class >> taskNamed: anId [
	^ self allTasks
		detect: [ :task | task id = anId asString ]
		ifNone: [ Error signal: 'Unknown benchmark task: ', anId asString ]
]

{ #category : 'versioning' }
PharoCABenchmarkCatalog class >> taskSetVersion [
	^ '004'
]

{ #category : 'tasks - basic' }
PharoCABenchmarkCatalog class >> basicTasks [ ^ self tasksWithIdPrefix: 'basic-' ]
{ #category : 'tasks - collections' }
PharoCABenchmarkCatalog class >> collectionTasks [ ^ self tasksWithIdPrefix: 'collections-' ]
{ #category : 'tasks - libraries' }
PharoCABenchmarkCatalog class >> libraryTasks [ ^ self tasksWithIdPrefix: 'library-' ]
{ #category : 'tasks - testing' }
PharoCABenchmarkCatalog class >> testingTasks [ ^ self tasksWithIdPrefix: 'testing-' ]
{ #category : 'tasks - exceptions' }
PharoCABenchmarkCatalog class >> exceptionTasks [ ^ self tasksWithIdPrefix: 'exceptions-' ]
{ #category : 'tasks - concurrency' }
PharoCABenchmarkCatalog class >> concurrencyTasks [ ^ self tasksWithIdPrefix: 'concurrency-' ]
{ #category : 'tasks - announcements' }
PharoCABenchmarkCatalog class >> announcementTasks [ ^ self tasksWithIdPrefix: 'announcements-' ]
{ #category : 'tasks - reflection' }
PharoCABenchmarkCatalog class >> reflectionTasks [ ^ self tasksWithIdPrefix: 'reflection-' ]
{ #category : 'tasks - discovery' }
PharoCABenchmarkCatalog class >> discoveryTasks [ ^ self tasksWithIdPrefix: 'discovery-' ]
{ #category : 'tasks - unknown api' }
PharoCABenchmarkCatalog class >> unknownApiTasks [ ^ self tasksWithIdPrefix: 'unknown-' ]
{ #category : 'tasks - refactoring' }
PharoCABenchmarkCatalog class >> refactoringTasks [ ^ self tasksWithIdPrefix: 'refactoring-' ]
{ #category : 'tasks - spec2' }
PharoCABenchmarkCatalog class >> spec2Tasks [ ^ self tasksWithIdPrefix: 'spec2-' ]
{ #category : 'tasks - navigation' }
PharoCABenchmarkCatalog class >> navigationTasks [ ^ self tasksWithIdPrefix: 'navigation-' ]
