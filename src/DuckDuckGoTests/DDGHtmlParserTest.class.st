Class {
	#name : 'DDGHtmlParserTest',
	#superclass : 'TestCase',
	#category : 'DuckDuckGoTests',
	#package : 'DuckDuckGoTests'
}

{ #category : 'tests' }
DDGHtmlParserTest >> testPlainTextDecodesEntitiesAndTags [
	self
		assert: (DDGHtmlParser plainTextFrom: '<h1>A &amp; B</h1><p>C&nbsp;D &#33;</p>')
		equals: 'A & B C D', (Character value: 33) asString
]

{ #category : 'tests' }
DDGHtmlParserTest >> testTextResults [
	| html results |
	html := '<html><div class="links_main links_deep result__body"><h2 class="result__title"><a class="result__a" href="https://example.com/a">Example &amp; One</a></h2><a class="result__snippet" href="https://example.com/a">A <b>useful</b> snippet.</a></div><div class="links_main links_deep result__body"><h2><a href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.org%2Fb">Second</a></h2><a class="result__snippet" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.org%2Fb">More text</a></div></html>'.
	results := DDGHtmlParser textResultsFrom: html.
	self assert: results size equals: 2.
	self assert: (results first at: 'title') equals: 'Example & One'.
	self assert: (results first at: 'body') equals: 'A useful snippet.'.
	self assert: (results first at: 'href') equals: 'https://example.com/a'.
	self assert: (results second at: 'href') equals: 'https://example.org/b'
]
