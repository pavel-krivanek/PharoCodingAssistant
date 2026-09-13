"Node returned by the benchmark-local document-tree API."
Class {
	#name : 'PharoCABenchmarkDocumentNode',
	#superclass : 'Object',
	#instVars : [ 'documentKey', 'weight', 'children' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkDocumentNode class >> key: aKey weight: aNumber [
	^ self new documentKey: aKey; weight: aNumber; initializeChildren; yourself
]

{ #category : 'building' }
PharoCABenchmarkDocumentNode >> attachChild: aNode [
	children add: aNode.
	^ aNode
]

{ #category : 'accessing' }
PharoCABenchmarkDocumentNode >> children [ ^ children copy ]

{ #category : 'accessing' }
PharoCABenchmarkDocumentNode >> documentKey [ ^ documentKey ]

{ #category : 'private' }
PharoCABenchmarkDocumentNode >> documentKey: aKey [ documentKey := aKey ]

{ #category : 'private' }
PharoCABenchmarkDocumentNode >> initializeChildren [ children := OrderedCollection new ]

{ #category : 'accessing' }
PharoCABenchmarkDocumentNode >> weight [ ^ weight ]

{ #category : 'private' }
PharoCABenchmarkDocumentNode >> weight: aNumber [ weight := aNumber ]
