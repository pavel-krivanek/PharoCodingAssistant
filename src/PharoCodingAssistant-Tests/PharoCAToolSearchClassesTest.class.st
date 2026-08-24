Class { #name : 'PharoCAToolSearchClassesTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolSearchClassesTest >> testSearchModesAndFilters [
 | r | r:=PharoCAToolSearchClasses execute:{'query'->'PharoCATestSearch'.'match'->'prefix'.'package'->'PharoCodingAssistant-Tests'.'tag'->'Fixtures'} asDictionary context:PharoCAToolExecutionContext unlimited.
 self assert:((r at:'classes') anySatisfy:[:e|(e at:'className')='PharoCATestSearchFixture']).
 r:=PharoCAToolSearchClasses execute:{'query'->'pharocatestsearchfixture'.'match'->'exact'} asDictionary context:PharoCAToolExecutionContext unlimited.
 self assert:((r at:'page') at:'total') equals:1 ]
{ #category : 'tests' }
PharoCAToolSearchClassesTest >> testPaginationCursorIsScopedAndCancellationWorks [
 | first cursor context | first:=PharoCAToolSearchClasses execute:{'query'->'Pharo'.'limit'->1} asDictionary context:PharoCAToolExecutionContext unlimited. cursor:=(first at:'page') at:'nextCursor'.
 self should:[PharoCAToolSearchClasses execute:{'query'->'Object'.'limit'->1.'cursor'->cursor} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error.
 context:=PharoCAToolExecutionContext unlimited. context cancellationToken cancel. self should:[PharoCAToolSearchClasses execute:{'query'->'a'} asDictionary context:context] raise:PharoCAToolExecutionCancelled ]
{ #category : 'tests' }
PharoCAToolSearchClassesTest >> testRejectsEmptyQueryAndUnknownPackageTag [
 self should:[PharoCAToolSearchClasses execute:{'query'->''} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error.
 self should:[PharoCAToolSearchClasses execute:{'query'->'X'.'package'->'NoSuchPCA049'} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error ]
