Class { #name : 'PharoCAToolIcebergLoadPackage', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergLoadPackage class >> toolName [ ^ #iceberg_load_package ]
{ #category : 'definition' } PharoCAToolIcebergLoadPackage class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergLoadPackage class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergLoadPackage class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_load_package' description:'Loads one package managed by a registered Iceberg repository from its checked-out Tonel tree into the live image.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'packageName'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository' 'packageName')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergLoadPackage class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergLoadPackage class >> execute: args context: context [
 | repository package beforeLoaded record |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. package:=self packageNamed:(args at:'packageName') inRepository:repository. context checkActive.
 beforeLoaded:=package isLoaded. beforeLoaded ifTrue:[^ {'repository'->repository name.'package'->(self packageSummaryFor:package).'changed'->false} asDictionary].
 self loadTonelPackageNamed:(args at:'packageName') fromRepository:repository context:context.
 package beDirty:false. context checkActive.
 record:=context recordChangeKind:#icebergPackageLoaded target:(args at:'packageName') before:{'loaded'->false} asDictionary after:{'loaded'->package isLoaded} asDictionary metadata:{'repository'->repository name.'transport'->'tonel'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'package'->(self packageSummaryFor:package).'changed'->true.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
