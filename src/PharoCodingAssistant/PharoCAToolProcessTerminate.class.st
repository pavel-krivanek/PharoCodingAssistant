Class { #name : 'PharoCAToolProcessTerminate', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessTerminate class >> toolName [ ^ #process_terminate ]
{ #category : 'definition' } PharoCAToolProcessTerminate class >> capability [ ^ #destructive ]
{ #category : 'execution' } PharoCAToolProcessTerminate class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' } PharoCAToolProcessTerminate class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_terminate' description:'Terminates a non-protected Pharo process. This is destructive runtime control.' parameters:{'type'->'object'.'properties'->{'processHandle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('processHandle')} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessTerminate class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolProcessTerminate class >> execute: args context: context [ | p name | p:=self processAt:(args at:'processHandle') context:context. self requireControllable:p context:context. name:=p name. p terminate. ^ {'processHandle'->(args at:'processHandle').'name'->name.'terminated'->true} asDictionary ]
