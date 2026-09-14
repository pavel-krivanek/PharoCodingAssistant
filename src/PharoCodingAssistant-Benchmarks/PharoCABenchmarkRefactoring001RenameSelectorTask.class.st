Class {
	#name : 'PharoCABenchmarkRefactoring001RenameSelectorTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Refactoring',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Refactoring'
}

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> id [
	^ 'refactoring-001-rename-selector'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> title [
	^ 'Rename an API and update its callers'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> prompt [
	^ 'The benchmark fixture classes PharoCABenchmarkLegacyNameFormatter and PharoCABenchmarkBadgePrinter use a legacy selector #formatName:. Refactor the fixture so the formatter instead defines #displayNameFor:, update every benchmark-fixture caller to use the new selector, and remove the old #formatName: method. Preserve behavior exactly. Do not add compatibility forwarding from the old selector. Verify the formatter and badge printer after the refactoring, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> category [
	^ 'refactoring'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> tags [
	^ #('refactoring' 'rename' 'senders')
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring001RenameSelectorTask >> maxIterations [
	^ 22
]
