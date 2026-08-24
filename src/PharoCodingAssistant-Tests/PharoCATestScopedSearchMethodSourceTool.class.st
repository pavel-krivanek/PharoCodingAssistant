"Test-only search tool that makes any accidental image-wide traversal fail immediately. Scoped-search tests invoke the inherited implementation directly."
Class {
	#name : 'PharoCATestScopedSearchMethodSourceTool',
	#superclass : 'PharoCAToolSearchMethodSource',
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'testing' }
PharoCATestScopedSearchMethodSourceTool class >> isAbstract [
	^ true
]

{ #category : 'private' }
PharoCATestScopedSearchMethodSourceTool class >> imageWideMethodsWithSourceString: query matchCase: matchCase context: context [
	self error: 'Scoped source search unexpectedly entered the image-wide traversal'
]
