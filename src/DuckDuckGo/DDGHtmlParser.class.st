Class {
	#name : 'DDGHtmlParser',
	#superclass : 'Object',
	#category : 'DuckDuckGo',
	#package : 'DuckDuckGo'
}

{ #category : 'parsing' }
DDGHtmlParser class >> plainTextFrom: html [
	^ self new plainTextFrom: html
]

{ #category : 'parsing' }
DDGHtmlParser class >> textResultsFrom: html [
	^ self new textResultsFrom: html
]

{ #category : 'private' }
DDGHtmlParser >> collapseWhitespace: aString [
	| out previousWasSpace normalized punctuation |
	out := String new writeStream.
	previousWasSpace := true.
	aString do: [ :ch |
		ch isSeparator
			ifTrue: [
				previousWasSpace ifFalse: [
					out space.
					previousWasSpace := true ] ]
			ifFalse: [
				out nextPut: ch.
				previousWasSpace := false ] ].
	normalized := out contents trimBoth.
	punctuation := #('.' ',' ';' ':' '?').
	punctuation do: [ :mark |
		normalized := normalized copyReplaceAll: ' ', mark with: mark ].
	normalized := normalized
		copyReplaceAll: ' ', (Character value: 33) asString
		with: (Character value: 33) asString.
	^ normalized
]

{ #category : 'private' }
DDGHtmlParser >> decodeEntity: entity [
	entity = 'amp' ifTrue: [ ^ '&' ].
	entity = 'lt' ifTrue: [ ^ '<' ].
	entity = 'gt' ifTrue: [ ^ '>' ].
	entity = 'quot' ifTrue: [ ^ '"' ].
	entity = 'apos' ifTrue: [ ^ (Character value: 39) asString ].
	entity = 'nbsp' ifTrue: [ ^ ' ' ].
	(entity beginsWith: '#x') ifTrue: [
		[ ^ (Character value: (Integer readFrom: (entity allButFirst: 2) readStream radix: 16)) asString ]
			on: Error do: [ ^ '&', entity, ';' ] ].
	(entity beginsWith: '#') ifTrue: [
		[ ^ (Character value: (entity allButFirst asInteger)) asString ]
			on: Error do: [ ^ '&', entity, ';' ] ].
	^ '&', entity, ';'
]

{ #category : 'private' }
DDGHtmlParser >> hrefFrom: htmlFragment [
	| hrefStart quoteStart quoteChar end |
	hrefStart := htmlFragment findString: 'href=' startingAt: 1.
	hrefStart = 0 ifTrue: [ ^ nil ].
	quoteStart := hrefStart + 5.
	[ quoteStart <= htmlFragment size and: [ (htmlFragment at: quoteStart) isSeparator ] ]
		whileTrue: [ quoteStart := quoteStart + 1 ].
	quoteStart > htmlFragment size ifTrue: [ ^ nil ].
	quoteChar := htmlFragment at: quoteStart.
	(quoteChar = $" or: [ quoteChar = $' ])
		ifTrue: [
			end := htmlFragment indexOf: quoteChar startingAt: quoteStart + 1.
			end = 0 ifTrue: [ ^ nil ].
			^ htmlFragment copyFrom: quoteStart + 1 to: end - 1 ].
	end := quoteStart.
	[ end <= htmlFragment size and: [
		((htmlFragment at: end) isSeparator or: [ (htmlFragment at: end) = $> ]) not ] ]
			whileTrue: [ end := end + 1 ].
	^ htmlFragment copyFrom: quoteStart to: end - 1
]

{ #category : 'private' }
DDGHtmlParser >> normalizeResultUrl: href [
	| normalized url redirected |
	normalized := href.
	(normalized beginsWith: '//') ifTrue: [ normalized := 'https:', normalized ].
	[ url := ZnUrl fromString: normalized ] on: Error do: [ ^ normalized ].
	((url host = 'duckduckgo.com' or: [ url host = 'www.duckduckgo.com' ]) and: [ url hasQuery ])
		ifTrue: [
			redirected := url queryAt: 'uddg' ifAbsent: [ nil ].
			redirected ifNotNil: [ ^ redirected ] ].
	^ normalized
]

{ #category : 'html text' }
DDGHtmlParser >> plainTextFrom: html [
	| out insideTag i ch entity semi |
	out := String new writeStream.
	insideTag := false.
	i := 1.
	[ i <= html size ] whileTrue: [
		ch := html at: i.
		insideTag
			ifTrue: [ ch = $> ifTrue: [ insideTag := false. out space ] ]
			ifFalse: [
				ch = $<
					ifTrue: [ insideTag := true ]
					ifFalse: [
						ch = $&
							ifTrue: [
								semi := html indexOf: $; startingAt: i + 1.
								(semi > 0 and: [ semi - i <= 12 ])
									ifTrue: [
										entity := html copyFrom: i + 1 to: semi - 1.
										out nextPutAll: (self decodeEntity: entity).
										i := semi ]
									ifFalse: [ out nextPut: ch ] ]
							ifFalse: [ out nextPut: ch ] ] ].
		i := i + 1 ].
	^ self collapseWhitespace: out contents
]

{ #category : 'private' }
DDGHtmlParser >> positionsOf: needle in: haystack [
	| positions pos start |
	positions := OrderedCollection new.
	start := 1.
	[ pos := haystack findString: needle startingAt: start. pos > 0 ] whileTrue: [
		positions add: pos.
		start := pos + needle size ].
	^ positions asArray
]

{ #category : 'private' }
DDGHtmlParser >> previousTagStartBefore: position in: string [
	| index |
	index := position min: string size.
	[ index > 1 and: [ (string at: index) ~= $< ] ] whileTrue: [ index := index - 1 ].
	^ index
]

{ #category : 'private' }
DDGHtmlParser >> textResultFromSegment: segment [
	| h2Start h2End h2 title href snippetStart snippetEnd snippet |
	h2Start := segment findString: '<h2' startingAt: 1.
	h2Start = 0 ifTrue: [ ^ nil ].
	h2End := segment findString: '</h2>' startingAt: h2Start.
	h2End = 0 ifTrue: [ ^ nil ].
	h2 := segment copyFrom: h2Start to: h2End + 4.
	title := self plainTextFrom: h2.
	href := self hrefFrom: h2.
	href ifNil: [
		snippetStart := segment findString: 'result__snippet' startingAt: h2End.
		snippetStart > 0 ifTrue: [
			href := self hrefFrom: (segment copyFrom: (self previousTagStartBefore: snippetStart in: segment) to: segment size) ] ].
	href ifNil: [ ^ nil ].
	snippetStart := segment findString: 'result__snippet' startingAt: h2End.
	snippet := ''.
	snippetStart > 0 ifTrue: [
		snippetEnd := segment findString: '</a>' startingAt: snippetStart.
		snippetEnd > 0 ifTrue: [
			snippet := self plainTextFrom:
				(segment copyFrom: (self previousTagStartBefore: snippetStart in: segment) to: snippetEnd + 3) ] ].
	^ Dictionary new
		at: 'title' put: title;
		at: 'href' put: (self normalizeResultUrl: href);
		at: 'body' put: snippet;
		yourself
]

{ #category : 'text search' }
DDGHtmlParser >> textResultsFrom: html [
	| markers results start next segment result |
	markers := self positionsOf: 'result__body' in: html.
	markers isEmpty ifTrue: [
		markers := self positionsOf: 'links_main' in: html ].
	results := OrderedCollection new.
	1 to: markers size do: [ :index |
		start := self previousTagStartBefore: (markers at: index) in: html.
		next := index < markers size
			ifTrue: [ self previousTagStartBefore: (markers at: index + 1) in: html ]
			ifFalse: [ html size + 1 ].
		segment := html copyFrom: start to: next - 1.
		result := self textResultFromSegment: segment.
		result ifNotNil: [ results add: result ] ].
	^ results asArray
]
