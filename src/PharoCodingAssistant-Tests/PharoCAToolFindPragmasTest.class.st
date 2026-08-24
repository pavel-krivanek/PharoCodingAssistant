Class { #name : 'PharoCAToolFindPragmasTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolFindPragmasTest >> testFindsExactPragmaAndArguments [
 | r hit | r:=PharoCAToolFindPragmas execute:{'pragma'->'pca049Marker:'.'className'->'PharoCATestSearchFixture'} asDictionary. self assert:((r at:'page') at:'total') equals:1. hit:=(r at:'occurrences') first.
 self assert: (hit at: 'selector') equals: 'pragmaMarker:'.
 self assert: (hit at: 'arguments') equals: #('''alpha''') ]
{ #category : 'tests' }
PharoCAToolFindPragmasTest >> testUnknownPragmaIsEmptyAndCursorScoped [
 | r | r:=PharoCAToolFindPragmas execute:{'pragma'->'pca049DefinitelyMissing'} asDictionary. self assert:((r at:'page') at:'total') equals:0.
 self should:[PharoCAToolFindPragmas execute:{'pragma'->''} asDictionary] raise:Error ]
