"Lists classes defined in a specified package using deterministic cursor pagination."
Class {
	#name : 'PharoCAToolListClassesInPackage',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> execute: args [
	| pkgName pkg classes page |
	pkgName := args at: 'packageName'.
	pkg := [ PackageOrganizer default packageNamed: pkgName ]
		on: Error
		do: [ :ex | ^ { 'error' -> ('Package not found: ', pkgName) } asDictionary ].
	classes := ((pkg definedClasses collect: [ :c | c name ]) asSortedCollection) asArray.
	page := PharoCAToolPagination
		pageItems: classes
		arguments: args
		scope: 'list_classes_in_package|', pkgName.
	^ {
		'packageName' -> pkgName.
		'classes' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListClassesInPackage class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_classes_in_package'
		description: 'Lists classes defined in a package. Results are sorted and cursor-paginated; continue only when page.hasMore is true.'
		parameters: { 'properties' -> { 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'packageName' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'packageName' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListClassesInPackage class >> toolName [
	^ #list_classes_in_package
]
