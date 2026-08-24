Class { #name : 'PharoCAToolDebugTerminate', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugTerminate class >> toolName [ ^ #debug_terminate ]
{ #category : 'execution' } PharoCAToolDebugTerminate class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolDebugTerminate class >> capability [ ^ #destructive ]
{ #category : 'definition' } PharoCAToolDebugTerminate class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_terminate' description:'Terminates the process controlled by a debugger and releases the debugger handle. This is destructive runtime control.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugTerminate class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugTerminate class >> execute: args context: context [ | h d registry |
 h:=args at:'debugHandle'. registry:=context requireRuntimeHandleRegistry. d:=self debuggerAt:h context:context. d isExecutionFinished ifFalse:[d terminate]. registry forget:h. ^ {'debugHandle'->h.'released'->true.'action'->'terminated'} asDictionary ]
