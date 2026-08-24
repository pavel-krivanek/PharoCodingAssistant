Class { #name : 'PharoCAToolProcessList', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessList class >> toolName [ ^ #process_list ]
{ #category : 'definition' } PharoCAToolProcessList class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolProcessList class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolProcessList class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_list' description:'Lists live Pharo processes with stable session-scoped handles, state, priority and protected-process classification.' parameters:{'type'->'object'.'properties'->{'nameContains'->{'type'->'string'} asDictionary.'limit'->{'type'->'integer'.'minimum'->1.'maximum'->200} asDictionary.'cursor'->{'type'->'string'} asDictionary} asDictionary.'required'->#()} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessList class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolProcessList class >> execute: args context: context [ | filter processes summaries page |
 filter:=(args at:'nameContains' ifAbsent:['']) asLowercase. processes:=Process allProcesses asArray.
 filter isEmpty ifFalse:[processes:=processes select:[:p|([p name ifNil:['']] on:Error do:[:e|'']) asLowercase includesSubstring:filter]].
 processes:=processes asSortedCollection:[:a :b| |an bn| an:=[a name ifNil:['']] on:Error do:[:e|'']. bn:=[b name ifNil:['']] on:Error do:[:e|'']. an=bn ifTrue:[a identityHash<=b identityHash] ifFalse:[an<=bn]].
 summaries:=processes collect:[:p|self summaryFor:p context:context]. page:=PharoCAToolPagination pageItems:summaries arguments:args scope:'process_list|',filter.
 ^ {'processes'->(page at:'items').'page'->(page at:'page')} asDictionary ]
