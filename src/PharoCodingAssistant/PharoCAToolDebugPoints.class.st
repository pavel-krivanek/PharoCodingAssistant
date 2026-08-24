Class { #name : 'PharoCAToolDebugPoints', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugPoints class >> toolName [ ^ #debug_points ]
{ #category : 'execution' } PharoCAToolDebugPoints class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolDebugPoints class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_points' description:'Lists installed Pharo DebugPoints. Points created by this assistant session include removable point-N handles.' parameters:{'type'->'object'.'properties'->{'limit'->{'type'->'integer'.'minimum'->1.'maximum'->200} asDictionary.'cursor'->{'type'->'string'} asDictionary} asDictionary.'required'->#()} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugPoints class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugPoints class >> execute: args context: context [ | points summaries page |
 points:=DebugPoint all asArray asSortedCollection:[:a :b| a name asString<=b name asString]. summaries:=points collect:[:p|self summaryForDebugPoint:p context:context]. page:=PharoCAToolPagination pageItems:summaries arguments:args scope:'debug_points'. ^ {'points'->(page at:'items').'page'->(page at:'page')} asDictionary ]
