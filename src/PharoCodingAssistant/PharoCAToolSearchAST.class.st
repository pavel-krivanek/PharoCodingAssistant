"Searches installed method ASTs with Pharo's native OCParseTreeSearcher pattern language."
Class { #name : 'PharoCAToolSearchAST', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolSearchAST class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolSearchAST class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolSearchAST class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolSearchAST class >> toolName [ ^ #search_ast ]
{ #category : 'definition' }
PharoCAToolSearchAST class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'search_ast' description:'Searches live installed methods with Pharo OCParseTreeSearcher native pattern syntax (for example `@receiver at: `@arg). Optional package/tag/class filters strongly narrow scope. Returns matched node source/ranges, captured pattern bindings, and method metadata; cursor-paginated.' parameters:{
 'type'->'object'. 'properties'->{
 'pattern'->{ 'type'->'string' } asDictionary. 'package'->{ 'type'->'string' } asDictionary. 'tag'->{ 'type'->'string' } asDictionary. 'className'->{ 'type'->'string' } asDictionary.
 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary.
 'required'->#('pattern') } asDictionary ]
{ #category : 'private' }
PharoCAToolSearchAST class >> bindingNodeSummary: value source: source [
 | item |
 (value respondsTo:#start) ifFalse:[^ {'className'->value class name asString. 'preview'->(PharoCAObjectPresenter previewOf:value)} asDictionary].
 item:={'type'->value class name asString. 'start'->([value start] on:Error do:[:error|nil]). 'stop'->([value stop] on:Error do:[:error|nil]). 'source'->(PharoCAToolGetMethodAST snippetOf:value source:source)} asDictionary.
 ^ item
]

{ #category : 'private' }
PharoCAToolSearchAST class >> bindingValueSummary: value source: source [
 (value isCollection and:[value isString not and:[(value respondsTo:#start) not]]) ifTrue:[
  ^ ((value first:(value size min:20)) collect:[:each|self bindingNodeSummary:each source:source]) asArray ].
 ^ self bindingNodeSummary:value source:source
]

{ #category : 'private' }
PharoCAToolSearchAST class >> bindingsFrom: searcher source: source [
 | bindings |
 bindings:=Dictionary new.
 searcher context keysAndValuesDo:[:key :value| |name|
  name:=(key respondsTo:#name) ifTrue:[key name asString] ifFalse:[key printString].
  bindings at:name put:(self bindingValueSummary:value source:source)].
 ^ bindings
]

{ #category : 'execution' }
PharoCAToolSearchAST class >> execute: args context: context [
 | pattern packageName tagName className methods matches searcher currentMethod currentSource skipped page scope |
 pattern:=args at:'pattern'. pattern isEmpty ifTrue:[Error signal:'AST pattern must not be empty'].
 packageName:=args at:'package' ifAbsent:[nil]. tagName:=args at:'tag' ifAbsent:[nil]. className:=args at:'className' ifAbsent:[nil].
 methods:=PharoCAImageNavigation methodsForPackage:packageName tag:tagName className:className context:context.
 matches:=OrderedCollection new. skipped:=0. currentMethod:=nil. currentSource:=''. searcher:=ASTParseTreeSearcher new.
 searcher matches:pattern do:[:node :answer | |item summary text|
  summary:=PharoCAImageNavigation methodSummary:currentMethod. item:=summary copy.
  text:=PharoCAToolGetMethodAST snippetOf:node source:currentSource.
  item at:'nodeType' put:node class name; at:'start' put:node start; at:'stop' put:node stop; at:'match' put:text.
  item at:'bindings' put:(self bindingsFrom:searcher source:currentSource).
  answer add:item. answer ].
 methods doWithIndex:[:method :index|
  (index \\ 100=0) ifTrue:[context checkActive].
  (searcher canMatchMethod:method) ifTrue:[
   currentMethod:=method.
   [ currentSource:=method sourceCode. searcher executeTree:method sourceNode initialAnswer:matches ] on:Error do:[:error| skipped:=skipped+1 ] ] ].
 matches:=(matches asSortedCollection:[:a :b| (a at:'className')=(b at:'className') ifTrue:[(a at:'selector')=(b at:'selector') ifTrue:[(a at:'start') <= (b at:'start')] ifFalse:[(a at:'selector') <= (b at:'selector')]] ifFalse:[(a at:'className') <= (b at:'className')]]) asArray.
 scope:='search_ast|',pattern,'|',(packageName ifNil:['']),'|',(tagName ifNil:['']),'|',(className ifNil:['']).
 page:=PharoCAToolPagination pageItems:matches arguments:args scope:scope.
 ^ {'pattern'->pattern. 'matches'->(page at:'items'). 'skippedMethods'->skipped. 'page'->(page at:'page')} asDictionary ]
