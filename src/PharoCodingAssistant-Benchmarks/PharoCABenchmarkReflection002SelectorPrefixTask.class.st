Class {
	#name : 'PharoCABenchmarkReflection002SelectorPrefixTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Reflection',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Reflection'
}

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> id [
	^ 'reflection-002-selector-prefix'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> title [
	^ 'Inspect selectors of a class'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> prompt [
	^ 'Create class PCABenchmarkSelectorQuery in package PCABenchmark-Workspace. Implement instance method selectorsBeginningWith:of:. The first argument is a String prefix and the second a class. Answer a sorted Array of selector Symbols defined directly by that class whose textual selector begins with the prefix. Do not include inherited selectors. Verify it against a class in the benchmark package, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> category [
	^ 'reflection'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> tags [
	^ #('reflection' 'selectors' 'browsing')
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkReflection002SelectorPrefixTask >> maxIterations [
	^ 16
]
