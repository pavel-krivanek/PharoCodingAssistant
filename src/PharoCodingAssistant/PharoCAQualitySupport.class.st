"Shared native QualityAssistant/Smalllint adaptation used by the lazy quality tool pack."
Class {
	#name : 'PharoCAQualitySupport',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'private' }
PharoCAQualitySupport class >> boundedString: anObject limit: limit [
	| text |
	text := anObject ifNil: [ '' ] ifNotNil: [ anObject asString ].
	text size <= limit ifTrue: [ ^ text ].
	^ (text copyFrom: 1 to: limit), '…'
]

{ #category : 'entities' }
PharoCAQualitySupport class >> classNamed: className [
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ Error signal: 'Class not found: ', className ].
	(cls isBehavior) ifFalse: [ Error signal: 'Global is not a class: ', className ].
	^ cls
]

{ #category : 'entities' }
PharoCAQualitySupport class >> entryEntity: entity descriptor: descriptor [
	^ {
		'entity' -> entity.
		'descriptor' -> descriptor
	} asDictionary
]

{ #category : 'entities' }
PharoCAQualitySupport class >> methodEntryForClass: cls side: side selector: selector [
	| target method |
	target := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	method := target compiledMethodAt: selector asSymbol ifAbsent: [
		Error signal: 'Method not found: ', cls name, ' ', side, '>>', selector ].
	^ self
		entryEntity: method
		descriptor: {
			'kind' -> 'method'.
			'className' -> cls name.
			'side' -> side.
			'selector' -> selector asString
		} asDictionary
]

{ #category : 'entities' }
PharoCAQualitySupport class >> appendClass: cls includeClassSide: includeClassSide to: addEntry [
	addEntry
		value: cls
		value: { 'kind' -> 'class'. 'className' -> cls name } asDictionary.
	(cls selectors asSortedCollection) do: [ :selector |
		addEntry value: (cls >> selector) value: {
			'kind' -> 'method'.
			'className' -> cls name.
			'side' -> 'instance'.
			'selector' -> selector asString
		} asDictionary ].
	includeClassSide ifTrue: [
		(cls class selectors asSortedCollection) do: [ :selector |
			addEntry value: (cls class >> selector) value: {
				'kind' -> 'method'.
				'className' -> cls name.
				'side' -> 'class'.
				'selector' -> selector asString
			} asDictionary ] ]
]

{ #category : 'entities' }
PharoCAQualitySupport class >> entriesForArguments: args maxEntities: maxEntities [
	| scope entries truncated addEntry className cls side selector includeClassSide packageName package methodEntry |
	entries := OrderedCollection new.
	truncated := false.
	addEntry := [ :entity :descriptor |
		entries size < maxEntities
			ifTrue: [ entries add: (self entryEntity: entity descriptor: descriptor) ]
			ifFalse: [ truncated := true ] ].
	scope := args at: 'scope'.
	scope = 'method' ifTrue: [
		className := args at: 'className' ifAbsent: [ Error signal: 'className is required for method scope' ].
		selector := args at: 'selector' ifAbsent: [ Error signal: 'selector is required for method scope' ].
		side := args at: 'side' ifAbsent: [ 'instance' ].
		cls := self classNamed: className.
		methodEntry := self methodEntryForClass: cls side: side selector: selector.
		addEntry value: (methodEntry at: 'entity') value: (methodEntry at: 'descriptor').
		^ { 'entries' -> entries asArray. 'truncated' -> truncated } asDictionary ].
	includeClassSide := args at: 'includeClassSide' ifAbsent: [ true ].
	scope = 'class' ifTrue: [
		className := args at: 'className' ifAbsent: [ Error signal: 'className is required for class scope' ].
		cls := self classNamed: className.
		self appendClass: cls includeClassSide: includeClassSide to: addEntry.
		^ { 'entries' -> entries asArray. 'truncated' -> truncated } asDictionary ].
	scope = 'package' ifTrue: [
		packageName := args at: 'packageName' ifAbsent: [ Error signal: 'packageName is required for package scope' ].
		package := [ PackageOrganizer default packageNamed: packageName ]
			on: Error
			do: [ :error | Error signal: 'Package not found: ', packageName ].
		addEntry value: package value: { 'kind' -> 'package'. 'packageName' -> packageName } asDictionary.
		((package definedClasses asSortedCollection: [ :a :b | a name <= b name ])) do: [ :eachClass |
			entries size < maxEntities
				ifTrue: [ self appendClass: eachClass includeClassSide: includeClassSide to: addEntry ]
				ifFalse: [ truncated := true ] ].
		^ { 'entries' -> entries asArray. 'truncated' -> truncated } asDictionary ].
	Error signal: 'Unsupported quality scope: ', scope
]

{ #category : 'critiques' }
PharoCAQualitySupport class >> findingForCritique: critique descriptor: descriptor [
	| rule anchor interval result description |
	rule := [ critique rule ] on: Error do: [ :error | nil ].
	result := {
		'entity' -> descriptor copy.
		'ruleClass' -> (rule ifNil: [ critique class name ] ifNotNil: [ rule class name ]).
		'ruleName' -> (self boundedString: ([ rule ifNil: [ critique class name ] ifNotNil: [ rule ruleName ] ] on: Error do: [ :error | critique class name ]) limit: 300).
		'group' -> (self boundedString: ([ rule ifNil: [ 'Unclassified' ] ifNotNil: [ rule group ] ] on: Error do: [ :error | 'Unclassified' ]) limit: 200).
		'severity' -> (self boundedString: ([ rule ifNil: [ 'information' ] ifNotNil: [ rule severity ] ] on: Error do: [ :error | 'information' ]) limit: 40).
		'title' -> (self boundedString: ([ critique title ] on: Error do: [ :error | critique printString ]) limit: 500)
	} asDictionary.
	description := [ critique description ] on: Error do: [ :error |
		rule ifNil: [ '' ] ifNotNil: [ [ rule rationale ] on: Error do: [ :ignored | '' ] ] ].
	description ifNotNil: [ result at: 'description' put: (self boundedString: description limit: 600) ].
	anchor := [ critique sourceAnchor ] on: Error do: [ :error | nil ].
	(anchor notNil and: [ [ anchor providesInterval ] on: Error do: [ :error | false ] ]) ifTrue: [
		interval := [ anchor interval ] on: Error do: [ :error | nil ].
		interval ifNotNil: [
			result at: 'sourceInterval' put: {
				'start' -> interval first.
				'end' -> interval last
			} asDictionary ] ].
	^ result
]

{ #category : 'filtering' }
PharoCAQualitySupport class >> finding: finding matchesArguments: args [
	| severity ruleClass |
	severity := args at: 'severity' ifAbsent: [ 'all' ].
	(severity = 'all' or: [ (finding at: 'severity') = severity ]) ifFalse: [ ^ false ].
	ruleClass := args at: 'ruleClass' ifAbsent: [ '' ].
	(ruleClass isEmpty or: [ (finding at: 'ruleClass') = ruleClass ]) ifFalse: [ ^ false ].
	^ true
]

{ #category : 'rules' }
PharoCAQualitySupport class >> ruleDescriptorFor: rule includeRationale: includeRationale [
	| result |
	result := {
		'ruleClass' -> rule class name.
		'name' -> (self boundedString: ([ rule ruleName ] on: Error do: [ :error | rule class name ]) limit: 300).
		'group' -> (self boundedString: ([ rule group ] on: Error do: [ :error | 'Unclassified' ]) limit: 200).
		'severity' -> (self boundedString: ([ rule severity ] on: Error do: [ :error | 'information' ]) limit: 40)
	} asDictionary.
	includeRationale ifTrue: [
		result at: 'rationale' put: (self boundedString: ([ rule rationale ] on: Error do: [ :error | '' ]) limit: 600) ].
	^ result
]
