"Finds installed occurrences of one exact pragma keyword using Pragma's cache-backed live-image query."
Class { #name : 'PharoCAToolFindPragmas', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolFindPragmas class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolFindPragmas class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolFindPragmas class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolFindPragmas class >> toolName [ ^ #find_pragmas ]
{ #category : 'definition' }
PharoCAToolFindPragmas class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'find_pragmas' description:'Finds installed occurrences of one exact pragma keyword, including arguments rendered compactly. Optional package/tag/class filters; cursor-paginated.' parameters:{
 'type'->'object'. 'properties'->{
 'pragma'->{ 'type'->'string' } asDictionary. 'package'->{ 'type'->'string' } asDictionary. 'tag'->{ 'type'->'string' } asDictionary. 'className'->{ 'type'->'string' } asDictionary.
 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary.
 'required'->#('pragma') } asDictionary ]
{ #category : 'execution' }
PharoCAToolFindPragmas class >> execute: args [
 | pragmaName packageName tagName className occurrences items page scope |
 pragmaName := args at:'pragma'. pragmaName isEmpty ifTrue:[Error signal:'Pragma name must not be empty'].
 packageName:=args at:'package' ifAbsent:[nil]. tagName:=args at:'tag' ifAbsent:[nil]. className:=args at:'className' ifAbsent:[nil].
 PharoCAImageNavigation validatePackage:packageName tag:tagName className:className.
 occurrences := Pragma allNamed:pragmaName asSymbol.
 occurrences := occurrences select:[:p | PharoCAImageNavigation class:(PharoCAImageNavigation baseClassOfMethod:p method) matchesPackage:packageName tag:tagName className:className ].
 items := occurrences collect:[:p | |d| d:=PharoCAImageNavigation methodSummary:p method. d at:'arguments' put:(p arguments collect:[:arg| |s| s:=arg printString. s size>200 ifTrue:[s:=s copyFrom:1 to:200]. s] ) asArray. d ].
 items := (items asSortedCollection:[:a :b| (a at:'className')=(b at:'className') ifTrue:[(a at:'selector')<=(b at:'selector')] ifFalse:[(a at:'className')<=(b at:'className')]]) asArray.
 scope := 'find_pragmas|',pragmaName,'|',(packageName ifNil:['']),'|',(tagName ifNil:['']),'|',(className ifNil:['']).
 page := PharoCAToolPagination pageItems:items arguments:args scope:scope.
 ^ {'pragma'->pragmaName. 'occurrences'->(page at:'items'). 'page'->(page at:'page')} asDictionary ]
