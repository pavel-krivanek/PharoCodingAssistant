Class { #name : 'PharoCAToolDebugResume', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugResume class >> toolName [ ^ #debug_resume ]
{ #category : 'execution' } PharoCAToolDebugResume class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolDebugResume class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_resume' description:'Resumes the debugged process and closes/releases the debugger handle.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugResume class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugResume class >> execute: args context: context [ | h d registry |
 h:=args at:'debugHandle'. registry:=context requireRuntimeHandleRegistry. d:=self debuggerAt:h context:context. d isExecutionFinished ifFalse:[d resume]. registry forget:h. ^ {'debugHandle'->h.'released'->true.'action'->'resumed'} asDictionary ]
