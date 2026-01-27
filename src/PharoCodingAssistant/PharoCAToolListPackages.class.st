Class {
	#name : 'PharoCAToolListPackages',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListPackages class >> execute: args [
	| pkgs substring |
	
	substring := (args at: 'substring').
	pkgs := (PackageOrganizer default packages select: [ :p | p name asLowercase includesSubstring: substring asLowercase ] thenCollect: [ :p | p name ]) asSortedCollection asArray.
	^ { 'packages' -> pkgs } asDictionary
]

{ #category : 'definition' }
PharoCAToolListPackages class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_packages'.
			'description' -> 'Lists package names from PackageOrganizer default. It can generate too long results if substring is not choosen with care.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'substring' -> { 'type' -> 'string' } asDictionary. } asDictionary asDictionary.
				'required' -> #()
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListPackages class >> toolName [
	^ #list_packages
]
