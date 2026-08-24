"Finds installed methods that reference one Smalltalk global binding such as a class or shared global."
Class {
	#name : 'PharoCAToolFindReferences', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo'
}
{ #category : 'definition' } PharoCAToolFindReferences class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolFindReferences class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolFindReferences class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolFindReferences class >> toolName [ ^ #find_references ]
{ #category : 'definition' }
PharoCAToolFindReferences class >> llmDefinition [
 ^ PharoCALLMToolDefinition name: 'find_references' description: 'Finds methods that reference an installed Smalltalk global binding (class or shared global). Optional package/tag/class filters; cursor-paginated.' parameters: {
 'type'->'object'. 'properties'->{
 'globalName'->{ 'type'->'string' } asDictionary.
 'package'->{ 'type'->'string' } asDictionary. 'tag'->{ 'type'->'string' } asDictionary. 'className'->{ 'type'->'string' } asDictionary.
 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary.
 'required'->#('globalName') } asDictionary ]
{ #category : 'execution' }
PharoCAToolFindReferences class >> execute: args [
 | name binding packageName tagName className methods summaries page scope |
 name := args at:'globalName'.
 binding := Smalltalk globals bindingOf: name asSymbol.
 binding ifNil:[ Error signal:'Global not found: ', name ].
 packageName := args at:'package' ifAbsent:[nil]. tagName := args at:'tag' ifAbsent:[nil]. className := args at:'className' ifAbsent:[nil].
 PharoCAImageNavigation validatePackage: packageName tag: tagName className: className.
 methods := SystemNavigation default allReferencesToBinding: binding.
 methods := methods select:[:m | PharoCAImageNavigation class:(PharoCAImageNavigation baseClassOfMethod:m) matchesPackage:packageName tag:tagName className:className ].
 summaries := PharoCAImageNavigation sortedMethodSummariesFor: methods.
 scope := 'find_references|',name,'|',(packageName ifNil:['']),'|',(tagName ifNil:['']),'|',(className ifNil:['']).
 page := PharoCAToolPagination pageItems:summaries arguments:args scope:scope.
 ^ {'globalName'->name. 'references'->(page at:'items'). 'page'->(page at:'page')} asDictionary ]
