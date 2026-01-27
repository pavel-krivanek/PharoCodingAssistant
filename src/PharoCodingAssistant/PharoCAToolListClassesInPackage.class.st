Class {
	#name : 'PharoCAToolListClassesInPackage',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> execute: args [
	| pkgName pkg classes |
	pkgName := args at: 'packageName'.

	pkg := [ PackageOrganizer default packageNamed: pkgName ]
		on: Error
		do: [ :ex | ^ { 'error' -> ('Package not found: ', pkgName) } asDictionary ].

	classes := ((pkg definedClasses collect: [ :c | c name ]) asSortedCollection) asArray.

	^ {
		'packageName' -> pkgName.
		'classes' -> classes
	} asDictionary

]

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'list_classes_in_package'.
			'description' -> 'Lists classes defined in a package.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'packageName' -> { 'type' -> 'string' }
				} asDictionary.
				'required' -> #('packageName')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> toolName [
	^ #list_classes_in_package
]
