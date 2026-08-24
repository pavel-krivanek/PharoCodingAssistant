Class { #name : 'PharoCAToolGetMethodASTTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolGetMethodASTTest >> testReturnsFlatPreorderWithParentAndSourceRanges [
 | r nodes root message | r:=PharoCAToolGetMethodAST execute:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'} asDictionary. nodes:=r at:'nodes'. root:=nodes first.
 self assert: (root at: 'index') equals: 1.
 self assert: (root at: 'parentIndex') isNil.
 self assert: (root at: 'depth') equals: 0.
 message := nodes detect: [ :n | (n at: 'selector' ifAbsent: [ '' ]) = 'pragmaMarker:' ].
 self assert: (message at: 'start') > 0.
 self assert: ((message at: 'source') includesSubstring: 'pragmaMarker:') ]
{ #category : 'tests' }
PharoCAToolGetMethodASTTest >> testPaginationAndMissingMethod [
 | first cursor second | first:=PharoCAToolGetMethodAST execute:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'limit'->2} asDictionary. self assert:((first at:'page') at:'hasMore'). cursor:=(first at:'page') at:'nextCursor'. second:=PharoCAToolGetMethodAST execute:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'limit'->2.'cursor'->cursor} asDictionary. self assert:((second at:'nodes') first at:'index') equals:3.
 self should:[PharoCAToolGetMethodAST execute:{'className'->'PharoCATestSearchFixture'.'selector'->'missingPCA049'} asDictionary] raise:Error ]
