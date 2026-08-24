Class { #name : 'PharoCAToolDebugStep', #superclass : 'PharoCADebugTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolDebugStep class >> toolName [ ^ #debug_step ]
{ #category : 'execution' } PharoCAToolDebugStep class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolDebugStep class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'debug_step' description:'Steps a Sindarin debugger by expression, over, through, bytecode, method entry, or until return.' parameters:{'type'->'object'.'properties'->{'debugHandle'->{'type'->'string'} asDictionary.'kind'->{'type'->'string'.'enum'->#('into' 'over' 'through' 'bytecode' 'methodEntry' 'return')} asDictionary} asDictionary.'required'->#('debugHandle' 'kind')} asDictionary ]
{ #category : 'execution' } PharoCAToolDebugStep class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolDebugStep class >> execute: args context: context [ | h d kind |
 h:=args at:'debugHandle'. kind:=args at:'kind'. d:=self debuggerAt:h context:context. d isExecutionFinished ifTrue:[Error signal:'Debugged execution is already finished'].
 context checkActive.
 kind='into' ifTrue:[d step]. kind='over' ifTrue:[d stepOver]. kind='through' ifTrue:[d stepThrough]. kind='bytecode' ifTrue:[d stepBytecode]. kind='methodEntry' ifTrue:[d stepToMethodEntry]. kind='return' ifTrue:[d stepToReturn].
 context checkActive. ^ self statusFor:d handle:h context:context ]
