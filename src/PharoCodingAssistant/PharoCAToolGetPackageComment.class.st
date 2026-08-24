"Retrieves a bounded page of a package comment."
Class {
	#name : 'PharoCAToolGetPackageComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolGetPackageComment class >> execute: args [
	| pkgName pkg comment page |
	pkgName := args at: 'packageName'.
	pkg := [ PackageOrganizer default packageNamed: pkgName ]
		on: Error
		do: [ :ex | ^ { 'error' -> ('Package not found: ', pkgName) } asDictionary ].
	comment := (pkg respondsTo: #comment)
		ifTrue: [ pkg comment ]
		ifFalse: [ (pkg respondsTo: #packageComment) ifTrue: [ pkg packageComment ] ifFalse: [ '' ] ].
	page := PharoCAToolPagination
		pageText: comment
		arguments: args
		scope: 'get_package_comment|', pkgName.
	^ {
		'packageName' -> pkgName.
		'comment' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolGetPackageComment class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetPackageComment class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolGetPackageComment class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_package_comment'
		description: 'Returns a bounded character range of a package comment, if available. Continue with range.nextCursor only when needed.'
		parameters: { 'properties' -> { 'cursor' -> { 'type' -> 'string' } asDictionary. 'packageName' -> { 'type' -> 'string' } asDictionary. 'maxCharacters' -> { 'minimum' -> 1. 'maximum' -> 16000. 'type' -> 'integer' } asDictionary } asDictionary. 'required' -> { 'packageName' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolGetPackageComment class >> toolName [ ^ #get_package_comment ]
