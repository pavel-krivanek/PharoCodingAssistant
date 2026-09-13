"Public fixture used by unknown-API benchmark tasks. The API is intentionally local to this benchmark so a model cannot rely on memorized library knowledge."
Class {
	#name : 'PharoCABenchmarkTelemetry',
	#superclass : 'Object',
	#instVars : [ 'series' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkTelemetry >> initialize [
	super initialize.
	series := Dictionary new
]

{ #category : 'recording' }
PharoCABenchmarkTelemetry >> capture: aNumber on: aChannel [
	(series at: aChannel ifAbsentPut: [ OrderedCollection new ]) add: aNumber.
	^ aNumber
]

{ #category : 'querying' }
PharoCABenchmarkTelemetry >> samplesOn: aChannel [
	^ (series at: aChannel ifAbsent: [ #() ]) copy
]

{ #category : 'querying' }
PharoCABenchmarkTelemetry >> availableChannels [
	^ series keys asArray
]
