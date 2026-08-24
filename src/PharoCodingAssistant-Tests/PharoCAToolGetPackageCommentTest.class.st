Class {
	#name : 'PharoCAToolGetPackageCommentTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAToolGetPackageCommentTest >> testReturnsExistingPackageAndStringComment [
	| result |
	result := PharoCAToolGetPackageComment execute: {
		'packageName' -> 'PharoCodingAssistant-Tests'
	} asDictionary.
	self assert: (result at: 'packageName') equals: 'PharoCodingAssistant-Tests'.
	self assert: (result at: 'comment') isString
]

{ #category : 'tests' }
PharoCAToolGetPackageCommentTest >> testMissingPackageReturnsError [
	self
		assertErrorResult: (PharoCAToolGetPackageComment execute: {
			'packageName' -> 'PharoCADefinitelyMissingPackage'
		} asDictionary)
		contains: 'Package not found'
]
