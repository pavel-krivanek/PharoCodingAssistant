Class { #name : 'PharoCAToolDebugAttachProcess', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugAttachProcess class >> toolName [ ^ #debug_attach_process ]
{ #category : 'execution' } PharoCAToolDebugAttachProcess class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugAttachProcess class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_attach_process' description:'Suspends a controllable Pharo process and attaches Sindarin to it. Returns a strong debug handle. Protected infrastructure processes are rejected.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugAttachProcess class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugAttachProcess class >> execute: args context: context [ | process originallySuspended session debugger handle attached |
 process:=context requireRuntimeHandleRegistry objectAt:(args at:'processHandle') kind:#process.
 PharoCAProcessTool requireControllable:process context:context. originallySuspended:=process isSuspended. attached:=false.
 [ originallySuspended ifFalse:[process suspend].
   session:=process newDebugSessionNamed:'PharoCodingAssistant debugger' startedAt:process suspendedContext.
   debugger:=SindarinDebugger attachTo:session. attached:=true.
   handle:=self registerDebugger:debugger owned:false originallySuspended:originallySuspended context:context.
   ^ self statusFor:debugger handle:handle context:context ] ensure:[
     (attached not and:[originallySuspended not and:[process isSuspended]]) ifTrue:[[process resume] on:Error do:[:e|]] ] ]
