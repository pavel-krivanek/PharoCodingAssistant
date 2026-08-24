Class { #name : 'PharoCAToolProcessDebug', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessDebug class >> toolName [ ^ #process_debug ]
{ #category : 'definition' } PharoCAToolProcessDebug class >> capability [ ^ #debugging ]
{ #category : 'execution' } PharoCAToolProcessDebug class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolProcessDebug class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_debug' description:'Attaches Sindarin to a non-protected Pharo process; equivalent to debug_attach_process.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessDebug class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolProcessDebug class >> execute: args context: context [ ^ PharoCAToolDebugAttachProcess execute:args context:context ]
