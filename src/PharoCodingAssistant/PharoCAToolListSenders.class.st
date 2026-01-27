Class {
	#name : 'PharoCAToolListSenders',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListSenders class >> execute: args [
	| sel refs items |
	sel := (args at: 'selector') asSymbol.
	refs := SystemNavigation default allCallsOn: sel.

	items := (refs collect: [ :ref |
		| mc |
		mc := ref methodClass.
		{
			'className' -> (mc isMeta ifTrue: [ mc instanceSide name ] ifFalse: [ mc name ]).
			'side' -> (mc isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]).
			'selector' -> ref selector asString
		} asDictionary
	]) asArray.

	^ { 'senders' -> items } asDictionary
]

{ #category : 'definition' }
PharoCAToolListSenders class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_senders'.
			'description' -> 'Lists methods that send a selector.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'selector' -> { 'type' -> 'string' }
				} asDictionary.
				'required' -> #('selector')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListSenders class >> toolName [
	^ #list_senders
]
