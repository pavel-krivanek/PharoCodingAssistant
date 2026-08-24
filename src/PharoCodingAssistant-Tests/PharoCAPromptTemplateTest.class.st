Class {
	#name : 'PharoCAPromptTemplateTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAPromptTemplateTest >> testVariableNamesAndRendering [
	| template rendered |
	template := PharoCAPromptTemplate named: 'review' content: 'Review {{class}} in {{package}}. {{class}} matters.'.
	self assert: template variableNames equals: #('class' 'package').
	rendered := template renderWith: ({ 'class' -> 'Foo'. 'package' -> 'Core' } asDictionary).
	self assert: rendered equals: 'Review Foo in Core. Foo matters.'.
	self assert: (template asDictionary at: 'variables') equals: #('class' 'package')
]

{ #category : 'tests' }
PharoCAPromptTemplateTest >> testRenderingRejectsUnresolvedVariables [
	| template |
	template := PharoCAPromptTemplate named: 'review' content: 'Review {{class}} in {{package}}'.
	self should: [ template renderWith: ({ 'class' -> 'Foo' } asDictionary) ] raise: Error
]
