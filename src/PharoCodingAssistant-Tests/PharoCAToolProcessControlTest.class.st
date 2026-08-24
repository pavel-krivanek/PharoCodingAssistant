Class { #name : 'PharoCAToolProcessControlTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'private' }
PharoCAToolProcessControlTest >> registry [ ^ PharoCAToolRegistry default useProfileNamed:'full'; yourself ]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testListStackSuspendResumePriorityAndTerminate [
 | registry stop process listed handle stack oldPriority newPriority suspended resumed changed terminated |
 registry:=self registry. stop:=false. process:=[[stop] whileFalse:[Processor yield]] forkNamed:'PCA051-Test-Worker'. oldPriority:=process priority.
 [ listed:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Test-Worker'} asDictionary. self assert:(listed at:'ok'). self assert:((((listed at:'result') at:'processes') size)) equals:1. handle:=(((listed at:'result') at:'processes') first) at:'handle'.
   stack:=registry executeNamed:'process_stack' arguments:{'processHandle'->handle} asDictionary. self assert:(stack at:'ok'). self assert:((((stack at:'result') at:'frames') notEmpty)).
   suspended:=registry executeNamed:'process_suspend' arguments:{'processHandle'->handle} asDictionary. self assert:(suspended at:'ok'). self assert:process isSuspended.
   resumed:=registry executeNamed:'process_resume' arguments:{'processHandle'->handle} asDictionary. self assert:(resumed at:'ok'). self deny:process isSuspended.
   newPriority:=oldPriority=Processor userBackgroundPriority ifTrue:[Processor userSchedulingPriority] ifFalse:[Processor userBackgroundPriority]. changed:=registry executeNamed:'process_set_priority' arguments:{'processHandle'->handle.'priority'->newPriority} asDictionary. self assert:(changed at:'ok'). self assert:process priority equals:newPriority.
   terminated:=registry executeNamed:'process_terminate' arguments:{'processHandle'->handle} asDictionary. self assert:(terminated at:'ok'). self assert:process isTerminated
 ] ensure:[ process isTerminated ifFalse:[process priority:oldPriority. stop:=true. process terminate] ]
]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testProtectedActiveProcessCannotBeSuspendedOrTerminated [
 | registry runtime handle suspend terminate |
 registry:=self registry. runtime:=registry runtimeHandleRegistryForSession:nil. handle:=runtime handleFor:Processor activeProcess kind:#process metadata:Dictionary new cleanup:nil.
 suspend:=registry executeNamed:'process_suspend' arguments:{'processHandle'->handle} asDictionary. self deny:(suspend at:'ok').
 terminate:=registry executeNamed:'process_terminate' arguments:{'processHandle'->handle} asDictionary. self deny:(terminate at:'ok')
]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testCpuSampleReturnsBoundedProcessRows [
 | result |
 result:=self registry executeNamed:'process_cpu_sample' arguments:{'durationMilliseconds'->20.'sampleMilliseconds'->5.'limit'->5} asDictionary.
 self assert:(result at:'ok'). self assert:((((result at:'result') at:'processes') size)<=5). self assert:(((result at:'result') at:'totalSamples')>=0)
]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testProcessDebugAndDebugAttachResumeWorker [
 | registry stop process listed handle debug resumed |
 registry:=self registry. stop:=false. process:=[[stop] whileFalse:[Processor yield]] forkNamed:'PCA051-Debug-Worker'.
 [ listed:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Debug-Worker'} asDictionary. handle:=(((listed at:'result') at:'processes') first) at:'handle'.
   debug:=registry executeNamed:'process_debug' arguments:{'processHandle'->handle} asDictionary. self assert:(debug at:'ok'). self assert:process isSuspended.
   resumed:=registry executeNamed:'debug_resume' arguments:{'debugHandle'->((debug at:'result') at:'debugHandle')} asDictionary. self assert:(resumed at:'ok'). self deny:process isSuspended.
   debug:=registry executeNamed:'debug_attach_process' arguments:{'processHandle'->handle} asDictionary. self assert:(debug at:'ok').
   resumed:=registry executeNamed:'debug_resume' arguments:{'debugHandle'->((debug at:'result') at:'debugHandle')} asDictionary. self assert:(resumed at:'ok')
 ] ensure:[stop:=true. process isTerminated ifFalse:[process terminate]]
]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testProcessStackCursorIsScopedToProcessHandle [
 | registry stop1 stop2 p1 p2 list1 list2 h1 h2 page cursor bad |
 registry:=self registry. stop1:=false. stop2:=false. p1:=[[stop1] whileFalse:[Processor yield]] forkNamed:'PCA051-Cursor-A'. p2:=[[stop2] whileFalse:[Processor yield]] forkNamed:'PCA051-Cursor-B'.
 [ list1:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Cursor-A'} asDictionary. list2:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Cursor-B'} asDictionary. h1:=(((list1 at:'result') at:'processes') first) at:'handle'. h2:=(((list2 at:'result') at:'processes') first) at:'handle'. page:=registry executeNamed:'process_stack' arguments:{'processHandle'->h1.'limit'->1} asDictionary. cursor:=(((page at:'result') at:'page') at:'nextCursor'). self deny:cursor isNil. bad:=registry executeNamed:'process_stack' arguments:{'processHandle'->h2.'limit'->1.'cursor'->cursor} asDictionary. self deny:(bad at:'ok')
 ] ensure:[stop1:=true. stop2:=true. p1 isTerminated ifFalse:[p1 terminate]. p2 isTerminated ifFalse:[p2 terminate]]
]

{ #category : 'tests' }
PharoCAToolProcessControlTest >> testPriorityOutsideProcessorRangeIsRejected [
 | registry stop process listed handle result |
 registry:=self registry. stop:=false. process:=[[stop] whileFalse:[Processor yield]] forkNamed:'PCA051-Priority-Guard'.
 [ listed:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Priority-Guard'} asDictionary. handle:=(((listed at:'result') at:'processes') first) at:'handle'. result:=registry executeNamed:'process_set_priority' arguments:{'processHandle'->handle.'priority'->100} asDictionary. self deny:(result at:'ok') ] ensure:[stop:=true. process isTerminated ifFalse:[process terminate]]
]
