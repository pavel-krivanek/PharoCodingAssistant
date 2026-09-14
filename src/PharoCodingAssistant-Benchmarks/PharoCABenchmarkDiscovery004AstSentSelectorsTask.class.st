Class {
	#name : 'PharoCABenchmarkDiscovery004AstSentSelectorsTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Discovery',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Discovery'
}

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> id [
	^ 'discovery-004-ast-sent-selectors'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> title [
	^ 'Discover and use the Pharo AST API'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> prompt [
	^ 'Create class PCABenchmarkASTQuery in package PCABenchmark-Workspace. Implement instance method selectorsSentByMethodSource:. The argument is a complete Smalltalk method source String. Parse it using the parser/AST facilities already present in this plain Pharo image and answer a sorted Array of the unique selector Symbols sent anywhere in the method body. Do not use regexes, substring matching, or manual source tokenization. Verify it with unary, binary, keyword, nested, and cascade sends.'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> category [
	^ 'discovery'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> tags [
	^ #('discovery' 'compiler' 'ast' 'parser')
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery004AstSentSelectorsTask >> maxIterations [
	^ 32
]
