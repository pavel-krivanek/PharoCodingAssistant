Class { #name : 'PharoCAToolProcessStack', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessStack class >> toolName [ ^ #process_stack ]
{ #category : 'definition' } PharoCAToolProcessStack class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolProcessStack class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolProcessStack class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_stack' description:'Returns a cursor-paginated stack snapshot for a Pharo process handle without suspending or resuming it.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary.'limit'->{'type'->'integer'.'minimum'->1.'maximum'->200} asDictionary.'cursor'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessStack class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolProcessStack class >> execute: args context: context [ | h process contexts summaries page |
 h:=args at:'processHandle'. process:=self processAt:h context:context. contexts:=self stackContextsFor:process limit:1000.
 summaries:=contexts withIndexCollect:[:frame :index|self frameSummaryFor:frame index:index]. page:=PharoCAToolPagination pageItems:summaries arguments:args scope:'process_stack|',h.
 ^ {'processHandle'->h.'frames'->(page at:'items').'page'->(page at:'page')} asDictionary ]
