Class { #name : 'PharoCAToolDebugFrame', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugFrame class >> toolName [ ^ #debug_frame ]
{ #category : 'execution' } PharoCAToolDebugFrame class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolDebugFrame class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_frame' description:'Returns receiver/class/method/source and temporary-variable summaries for one debugger stack frame.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary.'frameIndex'->{'type'->'integer'.'minimum'->1.'maximum'->10000} asDictionary} asDictionary.'required'->#('debugHandle' 'frameIndex')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugFrame class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugFrame class >> execute: args context: context [ | h d frame index method source result receiverHandle |
 h:=args at:'debugHandle'. index:=args at:'frameIndex'. d:=self debuggerAt:h context:context. frame:=self contextAtFrameIndex:index debugger:d.
 method:=[frame method] on:Error do:[:e|nil]. source:=method ifNil:[''] ifNotNil:[[method sourceCode] on:Error do:[:e|'']].
 receiverHandle:=context requireObjectHandleRegistry add:frame receiver.
 result:=self frameSummaryFor:frame index:index.
 result at:'receiverHandle' put:receiverHandle; at:'temporaries' put:(self temporaryValuesFor:frame); at:'source' put:source.
 ^ result ]
