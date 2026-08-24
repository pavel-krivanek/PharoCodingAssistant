Class { #name : 'PharoCAToolSearchASTTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolSearchASTTest >> testUsesNativePatternSearchInClassScope [
 | r hit | r:=PharoCAToolSearchAST execute:{'pattern'->'`@receiver pragmaMarker: `@arg'.'className'->'PharoCATestSearchFixture'} asDictionary context:PharoCAToolExecutionContext unlimited.
 hit := (r at: 'matches') detect: [ :e | (e at: 'selector') = 'astMarker:' ].
 self assert: ((hit at: 'match') includesSubstring: 'pragmaMarker:').
 self assert: (hit at: 'nodeType') equals: 'OCMessageNode' ]
{ #category : 'tests' }
PharoCAToolSearchASTTest >> testBadPatternEmptyPatternCursorAndCancellation [
 | first cursor context | self should:[PharoCAToolSearchAST execute:{'pattern'->''} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error.
 self should:[PharoCAToolSearchAST execute:{'pattern'->'('.'className'->'PharoCATestSearchFixture'} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error.
 first:=PharoCAToolSearchAST execute:{'pattern'->'`@receiver pragmaMarker: `@arg'.'className'->'PharoCATestSearchFixture'.'limit'->1} asDictionary context:PharoCAToolExecutionContext unlimited. cursor:=(first at:'page') at:'nextCursor'. cursor ifNotNil:[self should:[PharoCAToolSearchAST execute:{'pattern'->'`@receiver + `@arg'.'className'->'PharoCATestSearchFixture'.'limit'->1.'cursor'->cursor} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error].
 context:=PharoCAToolExecutionContext unlimited. context cancellationToken cancel. self should:[PharoCAToolSearchAST execute:{'pattern'->'`@receiver + `@arg'} asDictionary context:context] raise:PharoCAToolExecutionCancelled ]
