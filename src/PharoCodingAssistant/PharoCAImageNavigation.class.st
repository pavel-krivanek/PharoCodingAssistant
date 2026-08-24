"Shared, read-only navigation helpers used by the advanced Pharo browsing tools. The helpers deliberately derive metadata from installed classes/methods without materializing package tags or modifying the image."
Class {
	#name : 'PharoCAImageNavigation',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'resolving' }
PharoCAImageNavigation class >> classNamed: aString [
	^ Smalltalk globals at: aString asSymbol ifAbsent: [ Error signal: 'Class not found: ', aString ]
]

{ #category : 'metadata' }
PharoCAImageNavigation class >> baseClassOfMethod: aCompiledMethod [
	| behavior |
	behavior := aCompiledMethod methodClass.
	^ behavior isMeta ifTrue: [ behavior instanceSide ] ifFalse: [ behavior ]
]

{ #category : 'metadata' }
PharoCAImageNavigation class >> sideOfMethod: aCompiledMethod [
	^ aCompiledMethod methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]
]

{ #category : 'metadata' }
PharoCAImageNavigation class >> tagNameOfClass: aClass [
	^ aClass packageTag name asString
]

{ #category : 'metadata' }
PharoCAImageNavigation class >> methodSummary: aCompiledMethod [
	| baseClass |
	baseClass := self baseClassOfMethod: aCompiledMethod.
	^ {
		'className' -> baseClass name.
		'side' -> (self sideOfMethod: aCompiledMethod).
		'selector' -> aCompiledMethod selector asString.
		'protocol' -> aCompiledMethod protocolName asString.
		'package' -> baseClass package name.
		'tag' -> (self tagNameOfClass: baseClass)
	} asDictionary
]

{ #category : 'filtering' }
PharoCAImageNavigation class >> class: aClass matchesPackage: packageName tag: tagName className: className [
	(packageName notNil and: [ aClass package name ~= packageName ]) ifTrue: [ ^ false ].
	(tagName notNil and: [ (self tagNameOfClass: aClass) ~= tagName ]) ifTrue: [ ^ false ].
	(className notNil and: [ aClass name ~= className ]) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'validation' }
PharoCAImageNavigation class >> validatePackage: packageName tag: tagName className: className [
	| package |
	packageName ifNotNil: [
		package := PackageOrganizer default packageNamed: packageName ifAbsent: [ Error signal: 'Package not found: ', packageName ].
		tagName ifNotNil: [
			(package tagNames includes: tagName asSymbol) ifFalse: [ Error signal: 'Tag not found in package ', packageName, ': ', tagName ] ] ].
	className ifNotNil: [ self classNamed: className ].
]

{ #category : 'enumerating' }
PharoCAImageNavigation class >> methodsForPackage: packageName tag: tagName className: className context: context [
	| classes methods package |
	self validatePackage: packageName tag: tagName className: className.
	classes := className
		ifNotNil: [ { self classNamed: className } ]
		ifNil: [
			packageName
				ifNotNil: [
					package := PackageOrganizer default packageNamed: packageName.
					package definedClasses ]
				ifNil: [ SystemNavigation default allClasses ] ].
	methods := OrderedCollection new.
	classes doWithIndex: [ :aClass :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		(self class: aClass matchesPackage: packageName tag: tagName className: className) ifTrue: [
			methods addAll: aClass methods.
			methods addAll: aClass class methods ] ].
	^ methods
]

{ #category : 'sorting' }
PharoCAImageNavigation class >> sortedMethodSummariesFor: methods [
	^ ((methods collect: [ :method | self methodSummary: method ]) asSortedCollection: [ :a :b |
		(a at: 'className') = (b at: 'className')
			ifTrue: [ (a at: 'side') = (b at: 'side')
				ifTrue: [ (a at: 'selector') <= (b at: 'selector') ]
				ifFalse: [ (a at: 'side') <= (b at: 'side') ] ]
			ifFalse: [ (a at: 'className') <= (b at: 'className') ] ]) asArray
]
