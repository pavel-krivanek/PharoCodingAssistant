Class {
	#name : 'PharoCAToolObjectSummary',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' } PharoCAToolObjectSummary class >> toolName [ ^ #object_summary ]
{ #category : 'definition' } PharoCAToolObjectSummary class >> toolPack [ ^ #execution ]
{ #category : 'definition' } PharoCAToolObjectSummary class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolObjectSummary class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolObjectSummary class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'object_summary' description:'Returns a side-effect-conscious structural summary for a live object handle without sending arbitrary domain messages.' parameters:{'type'->'object'.'properties'->{'handle'->{'type'->'string'} asDictionary} asDictionary.'required'->#('handle')} asDictionary ]
{ #category : 'execution' } PharoCAToolObjectSummary class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolObjectSummary class >> execute: args context: context [ | object cls | object:=context requireObjectHandleRegistry objectAt:(args at:'handle'). cls:=object class. ^ {'className'->cls name asString. 'preview'->(PharoCAObjectPresenter previewOf:object). 'isImmediate'->cls isImmediateClass. 'slotCount'->cls allSlots size} asDictionary ]
