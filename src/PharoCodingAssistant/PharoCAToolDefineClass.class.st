Class {
	#name : 'PharoCAToolDefineClass',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolDefineClass class >> execute: args [
	"Uses the modern Fluid Class Syntax"
    | builder resolvedSuperclass |
    resolvedSuperclass := self resolveClass: (args at: 'superclassName').
    builder := resolvedSuperclass << (args at: 'className') asSymbol.
    (args includesKey: 'slots') ifTrue: [ builder slots: (args at: 'slots') ].
    (args includesKey: 'package') ifTrue: [ builder package: (args at: 'package') ].
    builder install.
    ^ { 'status' -> 'Class defined/modified' } asDictionary
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> toolDefinition [
	^ {
        'type' -> 'function'.
        'function' -> {
            'name' -> 'define_class'.
            'description' -> 'Creates or modifies a class using Fluid syntax.'.
            'parameters' -> {
                'type' -> 'object'.
                'properties' -> { 
                    'className' -> { 'type' -> 'string' } asDictionary.
                    'superclassName' -> { 'type' -> 'string' } asDictionary.
                    'slots' -> { 'type' -> 'string' } asDictionary.
                    'package' -> { 'type' -> 'string' } asDictionary.
                } asDictionary.
                'required' -> #('className' 'superclassName' 'package')
            } asDictionary
        } asDictionary
    } asDictionary.
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> toolName [
	^ #define_class

]
