Class { #name : 'PharoCAToolGetClassSummaryTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolGetClassSummaryTest >> testReturnsLiveStructuralMetadata [
 | r | r:=PharoCAToolGetClassSummary execute:{'className'->'PharoCATestSearchFixture'} asDictionary.
 self assert: (r at: 'package') equals: 'PharoCodingAssistant-Tests'.
 self assert: (r at: 'tag') equals: 'Fixtures'.
 self assert: (r at: 'superclass') equals: 'Object'.
 self assert: ((r at: 'localSlots') includes: 'probeValue').
 self assert: ((r at: 'allSlots') includes: 'probeValue').
 self assert: (r at: 'instanceMethodCount') equals: 7 ]
{ #category : 'tests' }
PharoCAToolGetClassSummaryTest >> testUnknownClassAndSchemaErrorsAreExplicit [
 self should:[PharoCAToolGetClassSummary execute:{'className'->'PCA049Missing'} asDictionary] raise:Error.
 self deny:((PharoCAToolRegistry default executeNamed:'get_class_summary' arguments:Dictionary new) at:'ok') ]
