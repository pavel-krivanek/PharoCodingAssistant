Class {
	#name : 'PharoCAToolASTDiagnosticsTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolASTDiagnosticsTest >> registry [ ^ PharoCAToolRegistry default ]

{ #category : 'tests' }
PharoCAToolASTDiagnosticsTest >> testSearchASTReturnsNativePatternBindings [
	| result match bindings |
	result := self registry executeNamed: 'search_ast' arguments: {
		'pattern' -> '``@receiver + ``@arg'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: (result at: 'ok').
	match := ((result at: 'result') at: 'matches') detect: [ :each | (each at: 'selector') = 'astMarker:' ].
	bindings := match at: 'bindings'.
	self assert: (bindings includesKey: '``@receiver').
	self assert: (bindings includesKey: '``@arg').
	self assert: (((bindings at: '``@arg') at: 'source') includesSubstring: '1')
]

{ #category : 'tests' }
PharoCAToolASTDiagnosticsTest >> testRewritePreviewUsesNativeRewriterWithoutMutatingMethod [
	| before result preview after |
	before := PharoCATestSearchFixture sourceCodeAt: #astMarker:.
	result := self registry executeNamed: 'ast_rewrite_preview' arguments: {
		'className' -> 'PharoCATestSearchFixture'.
		'selector' -> 'astMarker:'.
		'pattern' -> '``@receiver + 1'.
		'replacement' -> '``@receiver + 2'
	} asDictionary.
	self assert: (result at: 'ok').
	preview := result at: 'result'.
	self assert: (preview at: 'changed').
	self assert: (preview at: 'matchCount') equals: 1.
	self assert: ((preview at: 'rewrittenSource') includesSubstring: '+ 2').
	after := PharoCATestSearchFixture sourceCodeAt: #astMarker:.
	self assert: after equals: before
]

{ #category : 'tests' }
PharoCAToolASTDiagnosticsTest >> testRewritePreviewReportsNoChangeForNonMatchingPattern [
	| result preview |
	result := self registry executeNamed: 'ast_rewrite_preview' arguments: {
		'className' -> 'PharoCATestSearchFixture'.
		'selector' -> 'astMarker:'.
		'pattern' -> 'self definitelyMissingSelector'.
		'replacement' -> 'self yourself'
	} asDictionary.
	self assert: (result at: 'ok').
	preview := result at: 'result'.
	self deny: (preview at: 'changed').
	self assert: (preview at: 'matchCount') equals: 0
]

{ #category : 'tests' }
PharoCAToolASTDiagnosticsTest >> testRewritePreviewRejectsMissingMethod [
	| result |
	result := self registry executeNamed: 'ast_rewrite_preview' arguments: {
		'className' -> 'PharoCATestSearchFixture'.
		'selector' -> 'missingSelector'.
		'pattern' -> '1'.
		'replacement' -> '2'
	} asDictionary.
	self deny: (result at: 'ok')
]
