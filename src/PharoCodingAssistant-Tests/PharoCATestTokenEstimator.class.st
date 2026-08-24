Class {
	#name : 'PharoCATestTokenEstimator',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'estimating' }
PharoCATestTokenEstimator >> estimateMessages: messages [
	^ messages size * 10
]

{ #category : 'estimating' }
PharoCATestTokenEstimator >> estimateObject: anObject [
	^ 7
]
