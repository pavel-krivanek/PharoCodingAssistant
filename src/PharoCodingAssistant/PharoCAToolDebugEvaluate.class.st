Class { #name : 'PharoCAToolDebugEvaluate', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugEvaluate class >> toolName [ ^ #debug_evaluate ]
{ #category : 'execution' } PharoCAToolDebugEvaluate class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugEvaluate class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_evaluate' description:'Evaluates a Pharo expression in a selected debugger frame using OpalEvaluator and returns a normal transient object handle.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary.'frameIndex'->{'type'->'integer'.'minimum'->1.'maximum'->10000} asDictionary.'code'->{'type'->'string'.'minLength'->1.'maxLength'->50000} asDictionary} asDictionary.'required'->#('debugHandle' 'frameIndex' 'code')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugEvaluate class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugEvaluate class >> execute: args context: context [ | d frame object handle |
 d:=self debuggerAt:(args at:'debugHandle') context:context. frame:=self contextAtFrameIndex:(args at:'frameIndex') debugger:d. context checkActive.
 object:=OpalEvaluator new context:frame; evaluate:(args at:'code'). context checkActive. handle:=context requireObjectHandleRegistry add:object.
 ^ {'handle'->handle.'className'->object class name asString.'preview'->(PharoCAObjectPresenter previewOf:object)} asDictionary ]
