Class { #name : 'PharoCAToolDebugStart', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugStart class >> toolName [ ^ #debug_start ]
{ #category : 'execution' } PharoCAToolDebugStart class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugStart class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'debug_start' description:'Starts a new Sindarin debugger on a Pharo expression block and stops before its first executable expression. Returns a strong session-scoped debug handle.' parameters:{
 'type'->'object'. 'properties'->{ 'code'->{ 'type'->'string'. 'minLength'->1. 'maxLength'->50000 } asDictionary } asDictionary. 'required'->#('code') } asDictionary ]
{ #category : 'execution' } PharoCAToolDebugStart class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugStart class >> execute: args context: context [
 | code block debugger handle |
 code:=args at:'code'. context checkActive.
 block:=OpalEvaluator new evaluate:'[ ',code,' ]'.
 context checkActive. debugger:=SindarinDebugger debug:block. context checkActive.
 handle:=self registerDebugger:debugger owned:true originallySuspended:false context:context.
 ^ self statusFor:debugger handle:handle context:context ]
