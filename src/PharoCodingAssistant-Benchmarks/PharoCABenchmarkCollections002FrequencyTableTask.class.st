Class {
	#name : 'PharoCABenchmarkCollections002FrequencyTableTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> id [
	^ 'collections-002-frequency-table'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> title [
	^ 'Build a frequency table'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> prompt [
	^ 'Create class PCABenchmarkFrequencyTable in package PCABenchmark-Workspace. Implement instance method countsOf: that answers a Dictionary mapping every distinct input element to its occurrence count. The empty input must answer an empty Dictionary. Verify it on #(a b a c a b), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> tags [
	^ #('collections' 'dictionary' 'counting')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections002FrequencyTableTask >> maxIterations [
	^ 12
]
