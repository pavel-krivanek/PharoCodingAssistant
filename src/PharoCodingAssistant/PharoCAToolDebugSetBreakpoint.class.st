Class { #name : 'PharoCAToolDebugSetBreakpoint', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugSetBreakpoint class >> toolName [ ^ #debug_set_breakpoint ]
{ #category : 'execution' } PharoCAToolDebugSetBreakpoint class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugSetBreakpoint class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'debug_set_breakpoint' description:'Installs a Pharo BreakDebugPoint on a method AST node selected by preorder nodeIndex. Optionally scopes the breakpoint to one receiver object and adds a runtime condition, one-shot behavior, and hit counter. The point is removed on session cleanup.' parameters:{
 'type'->'object'.'properties'->{
 'className'->{'type'->'string'} asDictionary.
 'selector'->{'type'->'string'} asDictionary.
 'side'->{'type'->'string'.'enum'->#('instance' 'class')} asDictionary.
 'nodeIndex'->{'type'->'integer'.'minimum'->1.'maximum'->100000} asDictionary.
 'objectHandle'->{'type'->'string'} asDictionary.
 'condition'->{'type'->'string'.'minLength'->1.'maxLength'->2000} asDictionary.
 'once'->{'type'->'boolean'} asDictionary.
 'countHits'->{'type'->'boolean'} asDictionary
 } asDictionary.'required'->#('className' 'selector' 'nodeIndex')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugSetBreakpoint class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugSetBreakpoint class >> execute: args context: context [ | cls side behavior method node point handle result object target |
 cls:=PharoCAImageNavigation classNamed:(args at:'className'). side:=args at:'side' ifAbsent:['instance']. behavior:=side='class' ifTrue:[cls class] ifFalse:[cls]. method:=behavior compiledMethodAt:(args at:'selector') asSymbol ifAbsent:[Error signal:'Local method not found'].
 node:=self nodeAtPreorderIndex:(args at:'nodeIndex') inMethod:method.
 (args includesKey:'objectHandle')
  ifTrue:[
   side='class' ifTrue:[Error signal:'Object-centric breakpoints require instance-side methods'].
   object:=context requireObjectHandleRegistry objectAt:(args at:'objectHandle').
   (object isKindOf:cls) ifFalse:[Error signal:'Breakpoint object is not an instance of ',cls name].
   point:=DebugPointManager installNew:BreakDebugPoint on:node forObject:object.
   target:=cls name,'>>',(args at:'selector'),' object ',(args at:'objectHandle') ]
  ifFalse:[point:=DebugPointManager installNew:BreakDebugPoint on:node. target:=cls name,'>>',(args at:'selector')].
 self configureDebugPoint:point fromArguments:args.
 handle:=self registerDebugPoint:point context:context. result:=self summaryForDebugPoint:point context:context. result at:'handle' put:handle. context recordChangeKind:#debugPointInstalled target:target before:nil after:result metadata:{'runtimeOnly'->true} asDictionary. ^ result ]
