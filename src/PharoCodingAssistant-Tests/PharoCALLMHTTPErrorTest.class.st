Class {
	#name : 'PharoCALLMHTTPErrorTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'LLM'
}

{ #category : 'tests' }
PharoCALLMHTTPErrorTest >> testRecognizesCurrentLlamaCppContextSizeError [
	| error |
	error := PharoCALLMHTTPError new
		statusCode: 400;
		responseBody: '{"error":{"code":400,"message":"request (4390 tokens) exceeds the available context size (4096 tokens), try increasing it","type":"exceed_context_size_error"}}';
		yourself.
	self assert: error looksLikeContextOverflow
]

{ #category : 'tests' }
PharoCALLMHTTPErrorTest >> testRecognizesLlamaCppServerErrorContextExhaustion [
	| error |
	error := PharoCALLMHTTPError new
		statusCode: 500;
		responseBody: '{"error":{"code":500,"message":"Context size has been exceeded.","type":"server_error"}}';
		yourself.
	self assert: error looksLikeContextOverflow
]

{ #category : 'tests' }
PharoCALLMHTTPErrorTest >> testUnrelatedServerErrorIsNotContextOverflow [
	| error |
	error := PharoCALLMHTTPError new
		statusCode: 500;
		responseBody: '{"error":{"code":500,"message":"Model worker failed unexpectedly.","type":"server_error"}}';
		yourself.
	self deny: error looksLikeContextOverflow
]

{ #category : 'tests' }
PharoCALLMHTTPErrorTest >> testUnrelatedStatusIsNotContextOverflow [
	| error |
	error := PharoCALLMHTTPError new statusCode: 401; responseBody: 'context size has been exceeded'; yourself.
	self deny: error looksLikeContextOverflow
]
