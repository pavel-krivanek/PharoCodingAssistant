Class { #name : 'PharoCAToolDebugProcessPackContractTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Contracts', #package : 'PharoCodingAssistant-Tests', #tag : 'Contracts' }

{ #category : 'tests' }
PharoCAToolDebugProcessPackContractTest >> testNewToolsHaveExpectedPackCapabilityAndMode [
 | expected |
 expected:={
  PharoCAToolDebugStart->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugAttachProcess->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugStatus->#(#debug #debugging #parallelSafe).
  PharoCAToolDebugStack->#(#debug #debugging #parallelSafe).
  PharoCAToolDebugFrame->#(#debug #debugging #parallelSafe).
  PharoCAToolDebugStep->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugContinue->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugEvaluate->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugRestart->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugResume->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugTerminate->#(#debug #destructive #exclusiveMutation).
  PharoCAToolDebugPoints->#(#debug #debugging #parallelSafe).
  PharoCAToolDebugSetBreakpoint->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugSetWatchpoint->#(#debug #debugging #exclusiveMutation).
  PharoCAToolDebugRemovePoint->#(#debug #debugging #exclusiveMutation).
  PharoCAToolProcessList->#(#process #inspection #parallelSafe).
  PharoCAToolProcessStack->#(#process #inspection #parallelSafe).
  PharoCAToolProcessCpuSample->#(#process #inspection #sequential).
  PharoCAToolProcessSuspend->#(#process #process #exclusiveMutation).
  PharoCAToolProcessResume->#(#process #process #exclusiveMutation).
  PharoCAToolProcessSetPriority->#(#process #process #exclusiveMutation).
  PharoCAToolProcessTerminate->#(#process #destructive #exclusiveMutation).
  PharoCAToolProcessDebug->#(#process #debugging #exclusiveMutation)
 } asDictionary.
 expected keysAndValuesDo:[:tool :triple|self assert:tool toolPack equals:triple first. self assert:tool capability equals:triple second. self assert:tool executionMode equals:triple third]
]

{ #category : 'tests' }
PharoCAToolDebugProcessPackContractTest >> testPacksAreLazyAndFullProfileCanExposeThem [
 | registry session names |
 registry:=PharoCAToolRegistry default useProfileNamed:'full'; yourself. session:=PharoCASession new.
 names:=(registry definitionsForSession:session) collect:[:each|(each at:'function') at:'name'].
 self deny:(names includes:'debug_start'). self deny:(names includes:'process_list').
 registry activatePackNamed:'debug' forSession:session. registry activatePackNamed:'process' forSession:session.
 names:=(registry definitionsForSession:session) collect:[:each|(each at:'function') at:'name'].
 self assert:(names includes:'debug_start'). self assert:(names includes:'debug_terminate'). self assert:(names includes:'process_list'). self assert:(names includes:'process_terminate')
]

{ #category : 'tests' }
PharoCAToolDebugProcessPackContractTest >> testCodingProfileCanInspectProcessesButCannotDebugOrControlThem [
 | registry session names |
 registry:=PharoCAToolRegistry default. session:=PharoCASession new. registry activatePackNamed:'debug' forSession:session. registry activatePackNamed:'process' forSession:session.
 names:=(registry definitionsForSession:session) collect:[:each|(each at:'function') at:'name'].
 self assert:(names includes:'process_list'). self assert:(names includes:'process_stack'). self deny:(names includes:'debug_start'). self deny:(names includes:'process_suspend'). self deny:(names includes:'process_terminate')
]

{ #category : 'tests' }
PharoCAToolDebugProcessPackContractTest >> testRequiredArgumentSchemasAreEnforced [
 | registry names |
 registry:=PharoCAToolRegistry default useProfileNamed:'full'; yourself.
 names:=#(debug_start debug_attach_process debug_status debug_stack debug_frame debug_step debug_continue debug_evaluate debug_restart debug_resume debug_terminate debug_set_breakpoint debug_set_watchpoint debug_remove_point process_stack process_suspend process_resume process_set_priority process_terminate process_debug).
 names do:[:name||result| result:=registry executeNamed:name arguments:Dictionary new. self deny:(result at:'ok'). self assert:((result at:'error') at:'type') equals:'invalid_arguments']
]
