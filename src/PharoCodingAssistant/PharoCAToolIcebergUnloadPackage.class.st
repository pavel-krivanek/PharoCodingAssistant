Class { #name : 'PharoCAToolIcebergUnloadPackage', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergUnloadPackage class >> toolName [ ^ #iceberg_unload_package ]
{ #category : 'definition' } PharoCAToolIcebergUnloadPackage class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergUnloadPackage class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergUnloadPackage class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_unload_package' description:'Unloads one clean Iceberg-managed package from the live image. Dirty packages are refused so edits cannot be silently discarded.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'packageName'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository' 'packageName')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergUnloadPackage class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergUnloadPackage class >> execute: args context: context [
 | repository package record |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. package:=self packageNamed:(args at:'packageName') inRepository:repository. context checkActive.
 package isLoaded ifFalse:[^ {'repository'->repository name.'package'->(self packageSummaryFor:package).'changed'->false} asDictionary].
 package isDirty ifTrue:[Error signal:'Refusing to unload a dirty Iceberg package; commit or explicitly discard its changes first'].
 self unloadPackageNamedFromImageIfPresent:(args at:'packageName'). context checkActive.
 record:=context recordChangeKind:#icebergPackageUnloaded target:(args at:'packageName') before:{'loaded'->true} asDictionary after:{'loaded'->false} asDictionary metadata:{'repository'->repository name.'transport'->'monticello-loader'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'packageName'->(args at:'packageName').'loaded'->false.'changed'->true.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
