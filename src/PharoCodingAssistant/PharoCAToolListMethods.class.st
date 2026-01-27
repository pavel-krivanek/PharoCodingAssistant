"
Lists methods of a class, optionally filtered by protocol and side.
"
Class {
	#name : 'PharoCAToolListMethods',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListMethods class >> execute: args [
	| aClass classSymbol side targetClass protocol selectors methods |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].

	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := (side = 'class')
		ifTrue: [ aClass class ]
		ifFalse: [ aClass ].

	protocol := args at: 'protocol' ifAbsent: [ nil ].

	selectors := targetClass selectors.
	protocol ifNotNil: [
		| proto |
		proto :=  targetClass protocolNamed: protocol ifAbsent: [ nil ].
		proto ifNotNil: [ 
			selectors := proto methodSelectors.
		]
	].

	methods := (selectors asSortedCollection collect: [ :sel |
		| cat |
		cat := (targetClass methodNamed: sel asSymbol) protocolName. 
		{
			'selector' -> sel asString.
			'protocol' -> (cat ifNil: [ '' ])
		} asDictionary
	]) asArray.

	^ {
		'className' -> aClass name.
		'side' -> side.
		'methods' -> methods
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolListMethods class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_methods'.
			'description' -> 'Lists methods of a class. side: instance|class (default instance). Optional protocol to filter.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary.
					'side' -> { 'type' -> 'string' } asDictionary.
					'protocol' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListMethods class >> toolName [
	^ #list_methods
]
