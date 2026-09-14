Class {
	#name : 'PharoCABenchmarkNavigation001CodebookTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> id [
	^ 'navigation-001-codebook'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> title [
	^ 'Locate and repair a fixture method'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> prompt [
	^ 'In the PharoCodingAssistant-Benchmarks package there is a fixture object that maps #alpha and #beta to numeric secret codes through an instance method named secretCodeFor:. Locate the implementing class in the live image. Extend the existing behavior so #gamma maps to 30 while preserving all existing mappings and unknown-key behavior. Do not create a replacement class; modify the existing fixture and verify the result.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> tags [
	^ #('navigation' 'browsing' 'repair')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation001CodebookTask >> maxIterations [
	^ 20
]
