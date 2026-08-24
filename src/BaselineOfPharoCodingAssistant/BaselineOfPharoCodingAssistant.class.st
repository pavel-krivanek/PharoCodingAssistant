Class {
	#name : 'BaselineOfPharoCodingAssistant',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPharoCodingAssistant',
	#package : 'BaselineOfPharoCodingAssistant'
}

{ #category : 'baselines' }
BaselineOfPharoCodingAssistant >> baseline: spec [
	<baseline>

	spec for: #common do: [
		spec package: 'PharoCodingAssistant'.
		spec
			package: 'PharoCodingAssistant-Tests'
			with: [ spec requires: #( 'PharoCodingAssistant' ) ].

		spec
			group: 'Core' with: #( 'PharoCodingAssistant' );
			group: 'Tests' with: #( 'PharoCodingAssistant-Tests' );
			group: 'Development' with: #( 'Core' 'Tests' );
			group: 'default' with: #( 'Core' ) ]
]
