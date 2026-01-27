Class {
	#name : 'PharoCAToolCompileMethod',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolCompileMethod class >> execute: args [
	| aClass classSymbol side targetClass source protocol selector |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].

	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := (side = 'class')
		ifTrue: [ aClass class ]
		ifFalse: [ aClass ].

	source := args at: 'source'.
	protocol := args at: 'protocol' ifAbsent: [ 'as yet unclassified' ].

	selector := targetClass compile: source classified: protocol.
	^ {
		'status' -> 'ok'.
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selector asString
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolCompileMethod class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'compile_method'.
			'description' -> 'Compiles a method into a class. side: instance|class (default instance). Optional protocol.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary.
					'side' -> { 'type' -> 'string' } asDictionary.
					'source' -> { 'type' -> 'string' } asDictionary.
					'protocol' -> { 'type' -> 'string' }  asDictionary
				} asDictionary.
				'required' -> #('className' 'source')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolCompileMethod class >> toolName [
	^ #compile_method
]
