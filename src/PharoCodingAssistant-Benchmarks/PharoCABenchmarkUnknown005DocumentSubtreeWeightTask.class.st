Class {
	#name : 'PharoCABenchmarkUnknown005DocumentSubtreeWeightTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Unknown',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Unknown'
}

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> id [
	^ 'unknown-005-document-subtree-weight'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> title [
	^ 'Discover and recursively traverse an unfamiliar tree API'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> prompt [
	^ 'The benchmark fixtures contain a document-tree API whose tree can locate node objects and whose nodes expose their own public traversal protocol. Inspect those classes in the live image. Create class PCABenchmarkDocumentTreeAnalyzer in package PCABenchmark-Workspace with instance method subtreeWeightFor:in:. The first argument is a document key and the second the fixture tree. Answer the sum of that node''s numeric weight plus all descendant weights recursively. Answer nil when the requested document is absent. Do not access fixture instance variables or replace the fixture representation.'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> category [
	^ 'unknown-api'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> difficulty [
	^ 5
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> tags [
	^ #('unknown-api' 'navigation' 'multi-class' 'recursion')
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown005DocumentSubtreeWeightTask >> maxIterations [
	^ 36
]
