Class { #name : 'PharoCAToolDebugSetWatchpoint', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugSetWatchpoint class >> toolName [ ^ #debug_set_watchpoint ]
{ #category : 'execution' } PharoCAToolDebugSetWatchpoint class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugSetWatchpoint class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'debug_set_watchpoint' description:'Installs a Pharo WatchDebugPoint on reads/writes/all access to an instance slot, either class-wide or scoped to one objectHandle. Supports runtime conditions, one-shot behavior, hit counting, and bounded value history. The point is removed on session cleanup.' parameters:{'type'->'object'.'properties'->{
 'className'->{'type'->'string'} asDictionary.
 'objectHandle'->{'type'->'string'} asDictionary.
 'slotName'->{'type'->'string'} asDictionary.
 'access'->{'type'->'string'.'enum'->#('read' 'write' 'all')} asDictionary.
 'condition'->{'type'->'string'.'minLength'->1.'maxLength'->2000} asDictionary.
 'once'->{'type'->'boolean'} asDictionary.
 'countHits'->{'type'->'boolean'} asDictionary.
 'historyLimit'->{'type'->'integer'.'minimum'->0.'maximum'->1000} asDictionary
 } asDictionary.'required'->#('slotName' 'access')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugSetWatchpoint class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugSetWatchpoint class >> execute: args context: context [ | access slot point handle target result |
 access:=(args at:'access') asSymbol. slot:=(args at:'slotName') asSymbol.
 (args includesKey:'objectHandle') ifTrue:[ | object | object:=context requireObjectHandleRegistry objectAt:(args at:'objectHandle'). point:=DebugPointManager installNew:WatchDebugPoint forObject:object onVariableNamed:slot accessStrategy:access withBehaviors:#(). target:='object ',(args at:'objectHandle') ] ifFalse:[ | cls | (args includesKey:'className') ifFalse:[Error signal:'className or objectHandle is required']. cls:=PharoCAImageNavigation classNamed:(args at:'className'). point:=DebugPointManager installNew:WatchDebugPoint inClass:cls onVariableNamed:slot accessStrategy:access withBehaviors:#(). target:=cls name ].
 point limit:(args at:'historyLimit' ifAbsent:[20]).
 self configureDebugPoint:point fromArguments:args.
 handle:=self registerDebugPoint:point context:context. result:=self summaryForDebugPoint:point context:context. result at:'handle' put:handle. context recordChangeKind:#debugPointInstalled target:target before:nil after:result metadata:{'runtimeOnly'->true} asDictionary. ^ result ]
