Class { #name : 'PharoCAToolDebuggingTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'private' }
PharoCAToolDebuggingTest >> registry [ ^ PharoCAToolRegistry default useProfileNamed:'full'; yourself ]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testStartStatusStackFrameStepEvaluateContinueAndResume [
 | registry start h status stack frame step eval cont resume |
 registry:=self registry.
 start:=registry executeNamed:'debug_start' arguments:{'code'->'| x | x := 1. x + 2'} asDictionary.
 self assert:(start at:'ok'). h:=(start at:'result') at:'debugHandle'. self assert:h equals:'debug-1'.
 status:=registry executeNamed:'debug_status' arguments:{'debugHandle'->h} asDictionary. self assert:(status at:'ok'). self assert:(((status at:'result') at:'state')) equals:'suspended'.
 stack:=registry executeNamed:'debug_stack' arguments:{'debugHandle'->h.'limit'->1} asDictionary. self assert:(stack at:'ok'). self assert:((((stack at:'result') at:'page') at:'returned')) equals:1.
 frame:=registry executeNamed:'debug_frame' arguments:{'debugHandle'->h.'frameIndex'->1} asDictionary. self assert:(frame at:'ok'). self assert:(((frame at:'result') at:'temporaries') notNil).
 step:=registry executeNamed:'debug_step' arguments:{'debugHandle'->h.'kind'->'into'} asDictionary. self assert:(step at:'ok').
 eval:=registry executeNamed:'debug_evaluate' arguments:{'debugHandle'->h.'frameIndex'->1.'code'->'x'} asDictionary. self assert:(eval at:'ok'). self assert:(((eval at:'result') at:'preview')) equals:'1'.
 cont:=registry executeNamed:'debug_continue' arguments:{'debugHandle'->h} asDictionary. self assert:(cont at:'ok'). self assert:(((cont at:'result') at:'finished')).
 resume:=registry executeNamed:'debug_resume' arguments:{'debugHandle'->h} asDictionary. self assert:(resume at:'ok').
 self deny:((registry executeNamed:'debug_status' arguments:{'debugHandle'->h} asDictionary) at:'ok')
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testRestartAndTerminateOwnedDebugger [
 | registry start h step restart terminate |
 registry:=self registry. start:=registry executeNamed:'debug_start' arguments:{'code'->'| x | x := 1. x + 2'} asDictionary. h:=(start at:'result') at:'debugHandle'.
 step:=registry executeNamed:'debug_step' arguments:{'debugHandle'->h.'kind'->'into'} asDictionary. self assert:(step at:'ok').
 restart:=registry executeNamed:'debug_restart' arguments:{'debugHandle'->h} asDictionary. self assert:(restart at:'ok'). self assert:(((restart at:'result') at:'source')) equals:'x := 1'.
 terminate:=registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h} asDictionary. self assert:(terminate at:'ok')
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testContinueHonorsCancellationBeforeStepping [
 | registry start h token context result |
 registry:=self registry. start:=registry executeNamed:'debug_start' arguments:{'code'->'[ true ] whileTrue'} asDictionary. h:=(start at:'result') at:'debugHandle'.
 token:=PharoCACancellationToken new. token cancel. context:=PharoCAToolExecutionContext cancellationToken:token timeoutMilliseconds:1000 progressDo:[:p|].
 result:=registry executeNamed:'debug_continue' arguments:{'debugHandle'->h} asDictionary context:context.
 self deny:(result at:'ok'). self assert:(((result at:'error') at:'type')) equals:'tool_cancelled'.
 registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h} asDictionary
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testCodingProfileDoesNotExposeDebuggerExecution [
 | registry result |
 registry:=PharoCAToolRegistry default.
 result:=registry executeNamed:'debug_start' arguments:{'code'->'1+2'} asDictionary.
 self deny:(result at:'ok'). self assert:(((result at:'error') at:'type')) equals:'tool_not_allowed'
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testAllAdvertisedStepKindsExecute [
 | registry kinds |
 registry:=self registry. kinds:=#('into' 'over' 'through' 'bytecode' 'methodEntry' 'return').
 kinds do:[:kind| |start h result| start:=registry executeNamed:'debug_start' arguments:{'code'->'| x | x := 1. x + 2'} asDictionary. h:=(start at:'result') at:'debugHandle'. result:=registry executeNamed:'debug_step' arguments:{'debugHandle'->h.'kind'->kind} asDictionary. self assert:(result at:'ok') description:'step kind failed: ',kind. registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h} asDictionary ]
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testContinueStopsBeforeSignalledException [
 | registry start h result |
 registry:=self registry. start:=registry executeNamed:'debug_start' arguments:{'code'->'1 / 0'} asDictionary. h:=(start at:'result') at:'debugHandle'.
 result:=registry executeNamed:'debug_continue' arguments:{'debugHandle'->h} asDictionary. self assert:(result at:'ok'). self assert:(((result at:'result') at:'aboutToSignalException')). self deny:(((result at:'result') at:'finished')).
 registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h} asDictionary
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testDebugStackCursorIsScopedToDebuggerHandle [
 | registry first second h1 h2 page cursor bad |
 registry:=self registry. first:=registry executeNamed:'debug_start' arguments:{'code'->'1+2'} asDictionary. second:=registry executeNamed:'debug_start' arguments:{'code'->'3+4'} asDictionary. h1:=(first at:'result') at:'debugHandle'. h2:=(second at:'result') at:'debugHandle'.
 [ page:=registry executeNamed:'debug_stack' arguments:{'debugHandle'->h1.'limit'->1} asDictionary. cursor:=(((page at:'result') at:'page') at:'nextCursor'). self deny:cursor isNil.
   bad:=registry executeNamed:'debug_stack' arguments:{'debugHandle'->h2.'limit'->1.'cursor'->cursor} asDictionary. self deny:(bad at:'ok')
 ] ensure:[registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h1} asDictionary. registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h2} asDictionary]
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testDebugFrameReceiverHandleCanBeInspected [
 | registry start h frame receiverHandle summary |
 registry:=self registry. start:=registry executeNamed:'debug_start' arguments:{'code'->'1+2'} asDictionary. h:=(start at:'result') at:'debugHandle'.
 [ frame:=registry executeNamed:'debug_frame' arguments:{'debugHandle'->h.'frameIndex'->1} asDictionary. receiverHandle:=(frame at:'result') at:'receiverHandle'. summary:=registry executeNamed:'object_summary' arguments:{'handle'->receiverHandle} asDictionary. self assert:(summary at:'ok') ] ensure:[registry executeNamed:'debug_terminate' arguments:{'debugHandle'->h} asDictionary]
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testDebuggerHandlesAreSessionScopedAndCleanupTerminatesOwnedExecution [
 | registry s1 s2 c1 c2 start h processHandle process cross |
 registry:=self registry. s1:=PharoCASession new. s2:=PharoCASession new. c1:=PharoCAToolExecutionContext unlimited run:(PharoCARun new session:s1; yourself); yourself. c2:=PharoCAToolExecutionContext unlimited run:(PharoCARun new session:s2; yourself); yourself.
 start:=registry executeNamed:'debug_start' arguments:{'code'->'[true] whileTrue'} asDictionary context:c1. h:=(start at:'result') at:'debugHandle'. processHandle:=(start at:'result') at:'processHandle'. process:=(registry runtimeHandleRegistryForSession:s1) objectAt:processHandle kind:#process.
 cross:=registry executeNamed:'debug_status' arguments:{'debugHandle'->h} asDictionary context:c2. self deny:(cross at:'ok').
 registry clearPackStateForSession:s1. self assert:process isTerminated. self should:[(registry runtimeHandleRegistryForSession:s1) objectAt:h kind:#debugger] raise:Error
]

{ #category : 'tests' }
PharoCAToolDebuggingTest >> testAttachedDebuggerCannotUseOwnedRestart [
 | registry stop process listed handle debug result |
 registry:=self registry. stop:=false. process:=[[stop] whileFalse:[Processor yield]] forkNamed:'PCA051-Restart-Guard'.
 [ listed:=registry executeNamed:'process_list' arguments:{'nameContains'->'PCA051-Restart-Guard'} asDictionary. handle:=(((listed at:'result') at:'processes') first) at:'handle'. debug:=registry executeNamed:'debug_attach_process' arguments:{'processHandle'->handle} asDictionary. result:=registry executeNamed:'debug_restart' arguments:{'debugHandle'->((debug at:'result') at:'debugHandle')} asDictionary. self deny:(result at:'ok'). registry executeNamed:'debug_resume' arguments:{'debugHandle'->((debug at:'result') at:'debugHandle')} asDictionary
 ] ensure:[stop:=true. process isTerminated ifFalse:[process terminate]]
]
