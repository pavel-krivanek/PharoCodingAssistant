Class { #name : 'PharoCAToolDebugPointTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'private' }
PharoCAToolDebugPointTest >> registry [ ^ PharoCAToolRegistry default useProfileNamed:'full'; yourself ]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testBreakpointListRemoveAndSessionCleanup [
 | registry before created handle listed session context created2 point2 |
 registry:=self registry. before:=DebugPoint all size.
 created:=registry executeNamed:'debug_set_breakpoint' arguments:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'nodeIndex'->1} asDictionary.
 self assert:(created at:'ok'). handle:=(created at:'result') at:'handle'. self assert:(DebugPoint all size) equals:before+1.
 listed:=registry executeNamed:'debug_points' arguments:Dictionary new. self assert:(listed at:'ok'). self assert:((((listed at:'result') at:'points') anySatisfy:[:each|(each at:'handle' ifAbsent:[nil])=handle])).
 self assert:((registry executeNamed:'debug_remove_point' arguments:{'pointHandle'->handle} asDictionary) at:'ok'). self assert:DebugPoint all size equals:before.
 session:=PharoCASession new. context:=PharoCAToolExecutionContext unlimited run:(PharoCARun new session:session; yourself); yourself.
 created2:=registry executeNamed:'debug_set_breakpoint' arguments:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'nodeIndex'->1} asDictionary context:context. point2:=(created2 at:'result') at:'handle'. self assert:DebugPoint all size equals:before+1.
 registry clearPackStateForSession:session. self assert:DebugPoint all size equals:before. self should:[registry runtimeHandleRegistryForSession:session objectAt:point2 kind:#debugPoint] raise:Error
]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testClassAndObjectWatchpointsCanBeInstalledAndRemoved [
 | registry before classPoint object objectHandle objectPoint |
 registry:=self registry. before:=DebugPoint all size.
 classPoint:=registry executeNamed:'debug_set_watchpoint' arguments:{'className'->'PharoCATestSearchFixture'.'slotName'->'probeValue'.'access'->'read'} asDictionary. self assert:(classPoint at:'ok').
 self assert:((registry executeNamed:'debug_remove_point' arguments:{'pointHandle'->((classPoint at:'result') at:'handle')} asDictionary) at:'ok').
 object:=registry executeNamed:'evaluate_expression' arguments:{'code'->'PharoCATestSearchFixture new'} asDictionary. objectHandle:=(object at:'result') at:'handle'.
 objectPoint:=registry executeNamed:'debug_set_watchpoint' arguments:{'objectHandle'->objectHandle.'slotName'->'probeValue'.'access'->'write'} asDictionary. self assert:(objectPoint at:'ok').
 self assert:((registry executeNamed:'debug_remove_point' arguments:{'pointHandle'->((objectPoint at:'result') at:'handle')} asDictionary) at:'ok'). self assert:DebugPoint all size equals:before
]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testWatchpointRequiresClassOrObject [
 | result |
 result:=self registry executeNamed:'debug_set_watchpoint' arguments:{'slotName'->'probeValue'.'access'->'read'} asDictionary.
 self deny:(result at:'ok')
]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testBreakpointSupportsObjectScopeAndConditions [
 | registry object objectHandle created summary behaviors handle |
 registry:=self registry.
 object:=registry executeNamed:'evaluate_expression' arguments:{'code'->'PharoCATestSearchFixture new'} asDictionary.
 objectHandle:=(object at:'result') at:'handle'.
 created:=registry executeNamed:'debug_set_breakpoint' arguments:{
  'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'nodeIndex'->1.
  'objectHandle'->objectHandle.'condition'->'true'.'once'->true.'countHits'->true} asDictionary.
 self assert:(created at:'ok').
 summary:=created at:'result'.
 self assert:((summary at:'scope') asLowercase includesSubstring:'obj').
 behaviors:=summary at:'behaviors'.
 self assert:(behaviors anySatisfy:[:each|(each at:'type')='condition' and:[(each at:'expression')='true']]).
 self assert:(behaviors anySatisfy:[:each|(each at:'type')='once']).
 self assert:(behaviors anySatisfy:[:each|(each at:'type')='count']).
 handle:=summary at:'handle'.
 self assert:((registry executeNamed:'debug_remove_point' arguments:{'pointHandle'->handle} asDictionary) at:'ok')
]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testWatchpointSupportsConditionCountingAndHistoryLimit [
 | registry created summary behaviors handle |
 registry:=self registry.
 created:=registry executeNamed:'debug_set_watchpoint' arguments:{
  'className'->'PharoCATestSearchFixture'.'slotName'->'probeValue'.'access'->'write'.
  'condition'->'true'.'countHits'->true.'historyLimit'->3} asDictionary.
 self assert:(created at:'ok'). summary:=created at:'result'.
 self assert:(summary at:'historyLimit') equals:3.
 self assert:(summary at:'historyCount') equals:0.
 behaviors:=summary at:'behaviors'.
 self assert:(behaviors anySatisfy:[:each|(each at:'type')='condition']).
 self assert:(behaviors anySatisfy:[:each|(each at:'type')='count']).
 handle:=summary at:'handle'.
 self assert:((registry executeNamed:'debug_remove_point' arguments:{'pointHandle'->handle} asDictionary) at:'ok')
]

{ #category : 'tests' }
PharoCAToolDebugPointTest >> testObjectBreakpointRejectsWrongReceiverClass [
 | registry object handle result |
 registry:=self registry.
 object:=registry executeNamed:'evaluate_expression' arguments:{'code'->'Object new'} asDictionary.
 handle:=(object at:'result') at:'handle'.
 result:=registry executeNamed:'debug_set_breakpoint' arguments:{'className'->'PharoCATestSearchFixture'.'selector'->'astMarker:'.'nodeIndex'->1.'objectHandle'->handle} asDictionary.
 self deny:(result at:'ok')
]
