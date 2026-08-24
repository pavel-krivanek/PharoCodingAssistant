Class { #name : 'PharoCAToolDebugContinue', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugContinue class >> toolName [ ^ #debug_continue ]
{ #category : 'execution' } PharoCAToolDebugContinue class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugContinue class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_continue' description:'Continues a Sindarin execution cooperatively until it finishes or reaches an about-to-signal exception, checking cancellation/timeouts between steps.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('debugHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugContinue class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugContinue class >> execute: args context: context [ | h d steps |
 h:=args at:'debugHandle'. d:=self debuggerAt:h context:context. steps:=0.
 [ d isExecutionFinished or:[d isAboutToSignalException] ] whileFalse:[ context checkActive. d step. steps:=steps+1. steps\\100=0 ifTrue:[context reportProgress:{'steps'->steps} asDictionary] ].
 ^ (self statusFor:d handle:h context:context) at:'steps' put:steps; yourself ]
