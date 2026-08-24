Class { #name : 'PharoCAToolProcessSuspend', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessSuspend class >> toolName [ ^ #process_suspend ]
{ #category : 'definition' } PharoCAToolProcessSuspend class >> capability [ ^ #process ]
{ #category : 'execution' } PharoCAToolProcessSuspend class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolProcessSuspend class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_suspend' description:'Suspends a non-protected Pharo process. Critical infrastructure and the active tool process are rejected.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessSuspend class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolProcessSuspend class >> execute: args context: context [ | p changed | p:=self processAt:(args at:'processHandle') context:context. self requireControllable:p context:context. changed:=p isSuspended not. changed ifTrue:[p suspend]. ^ {'process'->(self summaryFor:p context:context).'changed'->changed} asDictionary ]
