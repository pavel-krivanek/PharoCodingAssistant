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
		spec package: 'DuckDuckGo'.
		spec
			package: 'DuckDuckGoTests'
			with: [ spec requires: #( 'DuckDuckGo' ) ].
		spec
			package: 'PharoCodingAssistant'
			with: [ spec requires: #( 'DuckDuckGo' ) ].
		spec
			package: 'PharoCodingAssistant-Tests'
			with: [ spec requires: #( 'PharoCodingAssistant' ) ].
		spec
			package: 'PharoCodingAssistant-Benchmarks'
			with: [ spec requires: #( 'PharoCodingAssistant' ) ].
		spec
			package: 'PharoCodingAssistant-Benchmarks-Evaluator'
			with: [ spec requires: #( 'PharoCodingAssistant-Benchmarks' ) ].
		spec
			package: 'PharoCodingAssistant-Benchmarks-Tests'
			with: [ spec requires: #( 'PharoCodingAssistant-Benchmarks' 'PharoCodingAssistant-Benchmarks-Evaluator' ) ].

		spec
			group: 'Core' with: #( 'PharoCodingAssistant' );
			group: 'Tests' with: #( 'DuckDuckGoTests' 'PharoCodingAssistant-Tests' );
			group: 'Development' with: #( 'Core' 'Tests' );
			group: 'Benchmarks' with: #( 'PharoCodingAssistant-Benchmarks' );
			group: 'BenchmarkEvaluator' with: #( 'PharoCodingAssistant-Benchmarks-Evaluator' );
			group: 'BenchmarkTests' with: #( 'PharoCodingAssistant-Benchmarks-Tests' );
			group: 'BenchmarkDevelopment' with: #( 'Development' 'Benchmarks' 'BenchmarkEvaluator' 'BenchmarkTests' );
			group: 'default' with: #( 'Core' ) ]
]
