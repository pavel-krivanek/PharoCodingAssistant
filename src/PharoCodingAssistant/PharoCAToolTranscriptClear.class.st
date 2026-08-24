Class { #name : 'PharoCAToolTranscriptClear', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolTranscriptClear class >> toolName [ ^ #transcript_clear ]
{ #category : 'definition' } PharoCAToolTranscriptClear class >> toolPack [ ^ #runtime ]
{ #category : 'definition' } PharoCAToolTranscriptClear class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolTranscriptClear class >> executionMode [ ^ #sequential ]
{ #category : 'definition' } PharoCAToolTranscriptClear class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'transcript_clear' description:'Clears the Pharo Transcript and the assistant Transcript capture buffer.' parameters:{'type'->'object'.'properties'->Dictionary new.'required'->#()} asDictionary ]
{ #category : 'execution' } PharoCAToolTranscriptClear class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolTranscriptClear class >> execute: args context: context [ context requireTranscriptBuffer clear. Transcript clear. ^ {'cleared'->true} asDictionary ]
