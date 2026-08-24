Class { #name : 'PharoCAToolTranscriptStatus', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolTranscriptStatus class >> toolName [ ^ #transcript_status ]
{ #category : 'definition' } PharoCAToolTranscriptStatus class >> toolPack [ ^ #runtime ]
{ #category : 'definition' } PharoCAToolTranscriptStatus class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolTranscriptStatus class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolTranscriptStatus class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'transcript_status' description:'Reports Transcript implementation and assistant ring-buffer capture status.' parameters:{'type'->'object'.'properties'->Dictionary new.'required'->#()} asDictionary ]
{ #category : 'execution' } PharoCAToolTranscriptStatus class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' } PharoCAToolTranscriptStatus class >> execute: args context: context [ ^ context requireTranscriptBuffer statusDictionary ]
