Class {
	#name : 'PharoCAToolListPackages',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListPackages class >> execute: args [
	| pkgs |
	pkgs := (PackageOrganizer default packages collect: [ :p | p name ]) asSortedCollection asArray.
	^ { 'packages' -> pkgs } asDictionary
]

{ #category : 'definition' }
PharoCAToolListPackages class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_packages'.
			'description' -> 'Lists package names from PackageOrganizer default.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> { } asDictionary asDictionary.
				'required' -> #()
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListPackages class >> toolName [
	^ #list_packages
]
