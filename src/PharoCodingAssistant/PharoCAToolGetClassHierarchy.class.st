Class {
	#name : 'PharoCAToolGetClassHierarchy',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> execute: args [
	| aClass classSymbol |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].
	^ {
		'className' -> aClass name.
		'superclasses' -> ((aClass withAllSuperclasses collect: [ :c | c name ]) asArray).
		'directSubclasses' -> ((aClass subclasses collect: [ :c | c name ]) asArray).
		'allSubclasses' -> ((aClass allSubclasses collect: [ :c | c name ]) asArray)
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'get_class_hierarchy'.
			'description' -> 'Returns superclass chain and subclasses for a class.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> toolName [
	^ #get_class_hierarchy
]
