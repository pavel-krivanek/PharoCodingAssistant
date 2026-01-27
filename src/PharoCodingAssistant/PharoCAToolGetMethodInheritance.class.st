Class {
	#name : 'PharoCAToolGetMethodInheritance',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolGetMethodInheritance class >> execute: args [
	| aClass classSymbol side targetClass selSymbol implementorClass source |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].

	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := (side = 'class')
		ifTrue: [ aClass class ]
		ifFalse: [ aClass ].

	selSymbol := (args at: 'selector') asSymbol.
	implementorClass := targetClass whichClassIncludesSelector: selSymbol.
	implementorClass ifNil: [
		^ {
			'error' -> ('Selector not found in hierarchy: ', (args at: 'selector')).
			'className' -> aClass name.
			'side' -> side
		} asDictionary
	].

	source := implementorClass sourceCodeAt: selSymbol.

	^ {
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selSymbol asString.
		'implementedIn' -> implementorClass name.
		'isLocal' -> (implementorClass == targetClass).
		'lookupOrder' -> ((targetClass withAllSuperclasses collect: [ :c | c name ]) asArray).
		'source' -> source
	} asDictionary
]

{ #category : 'as yet unclassified' }
PharoCAToolGetMethodInheritance class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'get_method_inheritance'.
			'description' -> 'Finds where a selector is implemented in the superclass chain and returns source.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary.
					'side' -> { 'type' -> 'string' } asDictionary.
					'selector' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className' 'selector')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'as yet unclassified' }
PharoCAToolGetMethodInheritance class >> toolName [
	^ #get_method_inheritance
]
