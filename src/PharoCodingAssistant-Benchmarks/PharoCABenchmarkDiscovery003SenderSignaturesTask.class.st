Class {
	#name : 'PharoCABenchmarkDiscovery003SenderSignaturesTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Discovery',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Discovery'
}

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> id [
	^ 'discovery-003-sender-signatures'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> title [
	^ 'Discover senders through image navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> prompt [
	^ 'Create class PCABenchmarkSenderQuery in package PCABenchmark-Workspace. Implement instance method senderSignaturesOf:. Its argument is a selector Symbol. Use Pharo image/navigation APIs to find compiled methods that send that selector. Answer a sorted Array of unique Strings formatted exactly as ClassName>>selector. Do not implement this by scanning source Strings. Verify it with selectors used by the benchmark fixture call chains.'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> category [
	^ 'discovery'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> tags [
	^ #('discovery' 'navigation' 'senders')
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery003SenderSignaturesTask >> maxIterations [
	^ 30
]
