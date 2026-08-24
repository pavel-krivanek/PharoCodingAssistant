Class { #name : 'PharoCAToolDebugStack', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugStack class >> toolName [ ^ #debug_stack ]
{ #category : 'execution' } PharoCAToolDebugStack class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolDebugStack class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_stack' description:'Returns a cursor-paginated stack for a live Sindarin debugger. frameIndex values can be passed to debug_frame/debug_evaluate.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary.'limit'->{'type'->'integer'.'minimum'->1.'maximum'->200} asDictionary.'cursor'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugStack class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugStack class >> execute: args context: context [ | h d contexts summaries page |
 h:=args at:'debugHandle'. d:=self debuggerAt:h context:context. contexts:=self stackContextsFor:d.
 summaries:=contexts withIndexCollect:[:each :index| self frameSummaryFor:each index:index].
 page:=PharoCAToolPagination pageItems:summaries arguments:args scope:'debug_stack|',h.
 ^ {'debugHandle'->h.'frames'->(page at:'items').'page'->(page at:'page')} asDictionary ]
