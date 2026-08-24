"Previews one OCParseTreeRewriter transformation on a freshly parsed copy of an installed method. It never mutates or recompiles the live method."
Class {
	#name : 'PharoCAToolASTRewritePreview',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolASTRewritePreview class >> toolName [ ^ #ast_rewrite_preview ]
{ #category : 'definition' }
PharoCAToolASTRewritePreview class >> toolPack [ ^ #browse ]
{ #category : 'definition' }
PharoCAToolASTRewritePreview class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolASTRewritePreview class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolASTRewritePreview class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ast_rewrite_preview'
		description: 'Previews a native OCParseTreeRewriter pattern replacement on a freshly parsed copy of one installed method. Returns rewritten source and hashes but never recompiles or mutates the live method.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary.
				'selector' -> { 'type' -> 'string' } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary.
				'pattern' -> { 'type' -> 'string'. 'minLength' -> 1. 'maxLength' -> 10000 } asDictionary.
				'replacement' -> { 'type' -> 'string'. 'minLength' -> 1. 'maxLength' -> 10000 } asDictionary.
				'methodPattern' -> { 'type' -> 'boolean' } asDictionary
			} asDictionary.
			'required' -> #('className' 'selector' 'pattern' 'replacement')
		} asDictionary
]

{ #category : 'private' }
PharoCAToolASTRewritePreview class >> hashOf: text [
	^ (SHA256 hashMessage: text) hex
]

{ #category : 'execution' }
PharoCAToolASTRewritePreview class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolASTRewritePreview class >> execute: args context: context [
	| cls side behavior selector method source tree rewriter changed rewritten methodPattern searcher matchCount |
	context checkActive.
	cls := PharoCAImageNavigation classNamed: (args at: 'className').
	side := args at: 'side' ifAbsent: [ 'instance' ].
	behavior := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	selector := (args at: 'selector') asSymbol.
	method := behavior compiledMethodAt: selector ifAbsent: [ Error signal: 'Local method not found: ', cls name, ' ', side, '>>', selector asString ].
	source := method sourceCode.
	source isString ifFalse: [ Error signal: 'Method source is unavailable' ].
	tree := OCParser parseMethod: source.
	methodPattern := args at: 'methodPattern' ifAbsent: [ false ].
	searcher := OCParseTreeSearcher new.
	matchCount := 0.
	methodPattern
		ifTrue: [ searcher matchesMethod: (args at: 'pattern') do: [ :node :answer | matchCount := matchCount + 1. answer ] ]
		ifFalse: [ searcher matches: (args at: 'pattern') do: [ :node :answer | matchCount := matchCount + 1. answer ] ].
	methodPattern
		ifTrue: [ searcher executeMethod: tree initialAnswer: nil ]
		ifFalse: [ searcher executeTree: tree initialAnswer: nil ].
	rewriter := OCParseTreeRewriter new.
	methodPattern
		ifTrue: [ rewriter replaceMethod: (args at: 'pattern') with: (args at: 'replacement') ]
		ifFalse: [ rewriter replace: (args at: 'pattern') with: (args at: 'replacement') ].
	changed := rewriter executeTree: tree.
	rewritten := rewriter tree formattedCode.
	context checkActive.
	^ {
		'className' -> cls name asString.
		'side' -> side.
		'selector' -> selector asString.
		'methodPattern' -> methodPattern.
		'matchCount' -> matchCount.
		'changed' -> changed.
		'originalSha256' -> (self hashOf: source).
		'rewrittenSha256' -> (self hashOf: rewritten).
		'rewrittenSource' -> rewritten
	} asDictionary
]
