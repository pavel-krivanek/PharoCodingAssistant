Class {
	#name : 'PharoCAToolListImplementors',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListImplementors class >> execute: args [
	| sel refs items |
	sel := (args at: 'selector') asSymbol.
	refs := SystemNavigation default allImplementorsOf: sel.

	items := (refs collect: [ :ref |
		| mc |
		mc := ref methodClass.
		{
			'className' -> (mc isMeta ifTrue: [ mc instanceSide name ] ifFalse: [ mc name ]).
			'side' -> (mc isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]).
			'selector' -> ref selector asString
		} asDictionary
	]) asArray.

	^ { 'implementors' -> items } asDictionary
]

{ #category : 'definition' }
PharoCAToolListImplementors class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_implementors'.
			'description' -> 'Lists classes/methods implementing a selector.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'selector' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('selector')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListImplementors class >> toolName [
	^ #list_implementors
]
