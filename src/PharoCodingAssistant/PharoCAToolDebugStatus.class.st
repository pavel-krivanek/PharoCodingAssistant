Class { #name : 'PharoCAToolDebugStatus', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugStatus class >> toolName [ ^ #debug_status ]
{ #category : 'execution' } PharoCAToolDebugStatus class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolDebugStatus class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_status' description:'Returns the current state and source location of a Sindarin debugger handle.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugStatus class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolDebugStatus class >> execute: args context: context [ | h d | h:=args at:'debugHandle'. d:=self debuggerAt:h context:context. ^ self statusFor:d handle:h context:context ]
