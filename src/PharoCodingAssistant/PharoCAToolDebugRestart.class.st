Class { #name : 'PharoCAToolDebugRestart', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugRestart class >> toolName [ ^ #debug_restart ]
{ #category : 'execution' } PharoCAToolDebugRestart class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolDebugRestart class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_restart' description:'Restarts a debugger created by debug_start from the beginning. Attached external processes cannot be restarted this way.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugRestart class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugRestart class >> execute: args context: context [ | h d metadata |
 h:=args at:'debugHandle'. d:=self debuggerAt:h context:context. metadata:=self metadataAt:h context:context. (metadata at:'owned') ifFalse:[Error signal:'Only debug_start sessions can be restarted'].
 context checkActive. d restart. context checkActive. ^ self statusFor:d handle:h context:context ]
