Class {
	#name : 'PharoCAToolDoIt',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> execute: args [
	Smalltalk compiler evaluate: (args at: 'code').
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'evaluate'.
			'description' -> 'Evaluates Pharo code (DoIt). Returns status only.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> { 'code' -> { 'type' -> 'string' } asDictionary } asDictionary.
				'required' -> #('code')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> toolName [
	^ #evaluate
]
