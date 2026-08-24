"Finds reads/writes/accesses of an instance slot using Pharo's structural compiled-method queries."
Class { #name : 'PharoCAToolFindSlotAccesses', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolFindSlotAccesses class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolFindSlotAccesses class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolFindSlotAccesses class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolFindSlotAccesses class >> toolName [ ^ #find_slot_accesses ]
{ #category : 'definition' }
PharoCAToolFindSlotAccesses class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'find_slot_accesses' description:'Finds methods reading, writing, or accessing a named instance slot. includeSubclasses uses the real Behavior allMethods*Slot: structural queries. Cursor-paginated.' parameters:{
 'type'->'object'. 'properties'->{
 'className'->{ 'type'->'string' } asDictionary. 'slotName'->{ 'type'->'string' } asDictionary.
 'access'->{ 'type'->'string'. 'enum'->#('read' 'write' 'all') } asDictionary.
 'includeSubclasses'->{ 'type'->'boolean' } asDictionary.
 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary.
 'required'->#('className' 'slotName') } asDictionary ]
{ #category : 'execution' }
PharoCAToolFindSlotAccesses class >> execute: args [
 | cls slot access includeSubclasses methods summaries page scope |
 cls := PharoCAImageNavigation classNamed:(args at:'className').
 slot := cls allSlots detect:[:each| each name asString = (args at:'slotName')] ifNone:[ Error signal:'Slot not found: ',(args at:'className'),'>>',(args at:'slotName') ].
 access := args at:'access' ifAbsent:['all']. includeSubclasses := args at:'includeSubclasses' ifAbsent:[false].
 methods := access='read'
  ifTrue:[ includeSubclasses ifTrue:[cls allMethodsReadingSlot:slot] ifFalse:[cls methodsReadingSlot:slot] ]
  ifFalse:[ access='write'
   ifTrue:[ includeSubclasses ifTrue:[cls allMethodsWritingSlot:slot] ifFalse:[cls methodsWritingSlot:slot] ]
   ifFalse:[ includeSubclasses ifTrue:[cls allMethodsAccessingSlot:slot] ifFalse:[cls methodsAccessingSlot:slot] ] ].
 summaries := PharoCAImageNavigation sortedMethodSummariesFor:methods.
 scope := 'find_slot_accesses|',cls name,'|',slot name asString,'|',access,'|',includeSubclasses asString.
 page := PharoCAToolPagination pageItems:summaries arguments:args scope:scope.
 ^ {'className'->cls name. 'slotName'->slot name asString. 'access'->access. 'includeSubclasses'->includeSubclasses. 'methods'->(page at:'items'). 'page'->(page at:'page')} asDictionary ]
