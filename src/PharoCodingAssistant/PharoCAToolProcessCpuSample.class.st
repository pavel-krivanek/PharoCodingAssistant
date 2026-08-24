Class { #name : 'PharoCAToolProcessCpuSample', #superclass : 'PharoCAProcessTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolProcessCpuSample class >> toolName [ ^ #process_cpu_sample ]
{ #category : 'execution' } PharoCAToolProcessCpuSample class >> executionMode [ ^ #sequential ]
{ #category : 'definition' } PharoCAToolProcessCpuSample class >> capability [ ^ #inspection ]
{ #category : 'definition' }
PharoCAToolProcessCpuSample class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'process_cpu_sample' description:'Samples runnable Pharo processes using ProcessorScheduler>>tallyCPUUsageFor:every: and returns a bounded ranking.' parameters:{'type'->'object'.'properties'->{'durationMilliseconds'->{'type'->'integer'.'minimum'->10.'maximum'->5000} asDictionary.'sampleMilliseconds'->{'type'->'integer'.'minimum'->1.'maximum'->1000} asDictionary.'limit'->{'type'->'integer'.'minimum'->1.'maximum'->200} asDictionary} asDictionary.'required'->#()} asDictionary ]
{ #category : 'execution' } PharoCAToolProcessCpuSample class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolProcessCpuSample class >> execute: args context: context [ | duration sample bag processes rows limit total |
 duration:=args at:'durationMilliseconds' ifAbsent:[250]. sample:=args at:'sampleMilliseconds' ifAbsent:[10]. limit:=args at:'limit' ifAbsent:[20]. PharoCAToolPagination validateItemLimit:limit.
 context checkActive. bag:=(Processor tallyCPUUsageFor:(duration/1000.0) every:sample) value. context checkActive. total:=bag size.
 processes:=bag asSet asArray. rows:=processes collect:[:p| |count summary| count:=bag occurrencesOf:p. summary:=self summaryFor:p context:context. summary at:'samples' put:count; at:'percent' put:(total=0 ifTrue:[0] ifFalse:[(count*100.0/total) roundTo:0.1]); yourself].
 rows:=rows asSortedCollection:[:a :b| (a at:'samples')=(b at:'samples') ifTrue:[(a at:'name')<=(b at:'name')] ifFalse:[(a at:'samples')>(b at:'samples')]]. rows size>limit ifTrue:[rows:=rows first:limit].
 ^ {'durationMilliseconds'->duration.'sampleMilliseconds'->sample.'totalSamples'->total.'processes'->rows asArray} asDictionary ]
