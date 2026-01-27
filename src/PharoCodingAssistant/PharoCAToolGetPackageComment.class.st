Class {
	#name : 'PharoCAToolGetPackageComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolGetPackageComment class >> execute: args [
	| pkgName pkg comment |
	pkgName := args at: 'packageName'.

	pkg := [ PackageOrganizer default packageNamed: pkgName ]
		on: Error
		do: [ :ex | ^ { 'error' -> ('Package not found: ', pkgName) } asDictionary ].

	comment := (pkg respondsTo: #comment)
		ifTrue: [ pkg comment ]
		ifFalse: [
			(pkg respondsTo: #packageComment)
				ifTrue: [ pkg packageComment ]
				ifFalse: [ '' ]
		].

	^ {
		'packageName' -> pkgName.
		'comment' -> comment
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolGetPackageComment class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'get_package_comment'.
			'description' -> 'Returns the comment/description of a package (if available on the package model).'.
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
PharoCAToolGetPackageComment class >> toolName [
	^ #get_package_comment
]
