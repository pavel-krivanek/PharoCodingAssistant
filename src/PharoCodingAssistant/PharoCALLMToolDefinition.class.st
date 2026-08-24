"Provider-neutral function/tool schema advertised to a model. Parameters are JSON Schema and therefore provider-independent."
Class {
	#name : 'PharoCALLMToolDefinition',
	#superclass : 'Object',
	#instVars : [ 'name', 'description', 'parameters' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMToolDefinition class >> name: aName description: aDescription parameters: aSchema [
	^ self new name: aName; description: aDescription; parameters: aSchema; yourself
]

{ #category : 'accessing' }
PharoCALLMToolDefinition >> name [ ^ name ]
{ #category : 'accessing' }
PharoCALLMToolDefinition >> name: aString [ name := aString ]
{ #category : 'accessing' }
PharoCALLMToolDefinition >> description [ ^ description ]
{ #category : 'accessing' }
PharoCALLMToolDefinition >> description: aString [ description := aString ]
{ #category : 'accessing' }
PharoCALLMToolDefinition >> parameters [ ^ parameters ]
{ #category : 'accessing' }
PharoCALLMToolDefinition >> parameters: aDictionary [ parameters := aDictionary ]

{ #category : 'converting' }
PharoCALLMToolDefinition >> asDictionary [
	^ { 'name' -> name. 'description' -> description. 'parameters' -> parameters } asDictionary
]
