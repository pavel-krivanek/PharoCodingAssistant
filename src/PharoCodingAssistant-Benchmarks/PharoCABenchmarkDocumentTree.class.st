"Benchmark-local tree API. Clients should discover #nodeNamed: and then navigate node children through public protocol."
Class {
	#name : 'PharoCABenchmarkDocumentTree',
	#superclass : 'Object',
	#instVars : [ 'nodes' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkDocumentTree >> initialize [
	super initialize.
	nodes := Dictionary new
]

{ #category : 'building' }
PharoCABenchmarkDocumentTree >> addRoot: aKey weight: aNumber [
	| node |
	node := PharoCABenchmarkDocumentNode key: aKey weight: aNumber.
	nodes at: aKey put: node.
	^ node
]

{ #category : 'building' }
PharoCABenchmarkDocumentTree >> add: aKey under: aParentKey weight: aNumber [
	| node parent |
	parent := nodes at: aParentKey.
	node := PharoCABenchmarkDocumentNode key: aKey weight: aNumber.
	nodes at: aKey put: node.
	parent attachChild: node.
	^ node
]

{ #category : 'querying' }
PharoCABenchmarkDocumentTree >> nodeNamed: aKey [
	^ nodes at: aKey ifAbsent: [ nil ]
]
