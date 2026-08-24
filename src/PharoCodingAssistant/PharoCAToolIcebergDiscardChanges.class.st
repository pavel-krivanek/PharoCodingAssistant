Class { #name : 'PharoCAToolIcebergDiscardChanges', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergDiscardChanges class >> toolName [ ^ #iceberg_discard_changes ]
{ #category : 'definition' } PharoCAToolIcebergDiscardChanges class >> capability [ ^ #destructive ]
{ #category : 'execution' } PharoCAToolIcebergDiscardChanges class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergDiscardChanges class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_discard_changes' description:'DESTRUCTIVE: discards dirty live Iceberg package changes, restoring each dirty package from the checked-out HEAD without invoking Iceberg/libgit diff calculation.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergDiscardChanges class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergDiscardChanges class >> execute: args context: context [
 | repository dirtyPackages before after record |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 dirtyPackages:=repository workingCopy packages select:[:package | package isDirty].
 dirtyPackages isEmpty ifTrue:[^ {'repository'->repository name.'discarded'->false.'changeCount'->0} asDictionary].
 before:=self mutationStateForRepository:repository context:context.
 dirtyPackages doWithIndex:[:package :index |
  (index \\ 10 = 0) ifTrue:[context checkActive].
  self restorePackageNamed:package name asString fromHeadInRepository:repository context:context].
 self refreshWorkingCopyReferenceToHeadForRepository:repository.
 context checkActive. after:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergChangesDiscarded target:repository name before:before after:after metadata:{'discardedChangeCount'->dirtyPackages size.'packages'->(dirtyPackages collect:[:each|each name asString]) asArray.'transport'->'tonel-head-restore'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'discarded'->true.'changeCount'->dirtyPackages size.'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
