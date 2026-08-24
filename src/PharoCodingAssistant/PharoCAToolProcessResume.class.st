Class { #name : 'PharoCAToolProcessResume', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessResume class >> toolName [ ^ #process_resume ]
{ #category : 'definition' } PharoCAToolProcessResume class >> capability [ ^ #process ]
{ #category : 'execution' } PharoCAToolProcessResume class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolProcessResume class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_resume' description:'Resumes a suspended non-protected Pharo process.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessResume class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolProcessResume class >> execute: args context: context [ | p changed | p:=self processAt:(args at:'processHandle') context:context. self requireControllable:p context:context. changed:=p isSuspended. changed ifTrue:[p resume]. ^ {'process'->(self summaryFor:p context:context).'changed'->changed} asDictionary ]
