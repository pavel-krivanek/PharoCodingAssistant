Class { #name : 'PharoCAToolFindReferencesTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolFindReferencesTest >> testFindsGlobalBindingReferenceAndFilters [
 | r hit | r:=PharoCAToolFindReferences execute:{'globalName'->'PharoCATestSearchFixture'.'className'->'PharoCATestSearchFixture'} asDictionary. hit:=(r at:'references') detect:[:e|(e at:'selector')='referenceFixtureClass'].
 self assert: (hit at: 'side') equals: 'instance'.
 self assert: (hit at: 'tag') equals: 'Fixtures' ]
{ #category : 'tests' }
PharoCAToolFindReferencesTest >> testUnknownGlobalAndCursorScope [
 | first cursor | self should:[PharoCAToolFindReferences execute:{'globalName'->'PCA049MissingGlobal'} asDictionary] raise:Error.
 first:=PharoCAToolFindReferences execute:{'globalName'->'Object'.'limit'->1} asDictionary. cursor:=(first at:'page') at:'nextCursor'. cursor ifNotNil:[self should:[PharoCAToolFindReferences execute:{'globalName'->'String'.'limit'->1.'cursor'->cursor} asDictionary] raise:Error] ]
