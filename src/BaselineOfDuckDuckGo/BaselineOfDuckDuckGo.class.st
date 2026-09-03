Class {
	#name : 'BaselineOfDuckDuckGo',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfDuckDuckGo',
	#package : 'BaselineOfDuckDuckGo'
}

{ #category : 'baseline' }
BaselineOfDuckDuckGo >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'DuckDuckGo';
			package: 'DuckDuckGoTests' with: [ spec requires: #('DuckDuckGo') ].
		spec
			group: 'default' with: #('DuckDuckGo');
			group: 'tests' with: #('DuckDuckGoTests') ]
]
