Class { #name : 'PharoCAToolSearchSelectorsTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolSearchSelectorsTest >> testFindsImplementedSelectorsInClassScope [
 | r names | r:=PharoCAToolSearchSelectors execute:{'query'->'ProbeValue'.'className'->'PharoCATestSearchFixture'} asDictionary context:PharoCAToolExecutionContext unlimited. names:=(r at:'selectors') collect:[:e|e at:'selector'].
 self assert: (names includes: 'readProbeValue').
 self assert: (names includes: 'writeProbeValue:') ]
{ #category : 'tests' }
PharoCAToolSearchSelectorsTest >> testExactCaseAndCursorScope [
 | r first cursor | r:=PharoCAToolSearchSelectors execute:{'query'->'readprobevalue'.'match'->'exact'.'className'->'PharoCATestSearchFixture'} asDictionary context:PharoCAToolExecutionContext unlimited. self assert:((r at:'page') at:'total') equals:1.
 first:=PharoCAToolSearchSelectors execute:{'query'->'test'.'limit'->1} asDictionary context:PharoCAToolExecutionContext unlimited. cursor:=(first at:'page') at:'nextCursor'.
 self should:[PharoCAToolSearchSelectors execute:{'query'->'read'.'limit'->1.'cursor'->cursor} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error ]
