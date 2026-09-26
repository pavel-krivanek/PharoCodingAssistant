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
			package: 'PharoCodingAssistant-Benchmarks-Tests'
			with: [ spec requires: #( 'PharoCodingAssistant-Benchmarks' ) ].

		spec
			baseline: 'LLMPharoMCP'
			with: [
				spec
					repository: 'github://pharo-llm/pharo-mcp:main/src';
					loads: #( 'Core' ) ].
		spec
			package: 'PharoCodingAssistant-MCP'
			with: [ spec requires: #( 'PharoCodingAssistant' 'LLMPharoMCP' ) ].
		spec
			package: 'PharoCodingAssistant-MCP-Tests'
			with: [ spec requires: #( 'PharoCodingAssistant-MCP' 'PharoCodingAssistant-Tests' ) ].

		spec
			group: 'Core' with: #( 'PharoCodingAssistant' );
			group: 'Tests' with: #( 'DuckDuckGoTests' 'PharoCodingAssistant-Tests' );
			group: 'Development' with: #( 'Core' 'Tests' );
			group: 'Benchmarks' with: #( 'PharoCodingAssistant-Benchmarks' );
			group: 'BenchmarkTests' with: #( 'PharoCodingAssistant-Benchmarks-Tests' );
			group: 'BenchmarkDevelopment' with: #( 'Development' 'Benchmarks' 'BenchmarkTests' );
			group: 'MCP' with: #( 'PharoCodingAssistant-MCP' );
			group: 'MCPTests' with: #( 'PharoCodingAssistant-MCP-Tests' );
			group: 'MCPDevelopment' with: #( 'Development' 'MCPTests' );
			group: 'default' with: #( 'Core' ) ]
]
