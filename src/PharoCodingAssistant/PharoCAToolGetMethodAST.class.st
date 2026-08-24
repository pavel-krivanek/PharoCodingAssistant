"Returns a bounded flat preorder projection of a method's real Opal/RB AST. Flat nodes keep parent identity stable across pagination."
Class { #name : 'PharoCAToolGetMethodAST', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolGetMethodAST class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolGetMethodAST class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolGetMethodAST class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolGetMethodAST class >> toolName [ ^ #get_method_ast ]
{ #category : 'definition' }
PharoCAToolGetMethodAST class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'get_method_ast' description:'Returns a cursor-paginated flat preorder summary of the real Opal AST for one local method. Each node includes stable index/parent/depth, node type, source range/snippet and selector/name when applicable.' parameters:{
 'type'->'object'. 'properties'->{
 'className'->{ 'type'->'string' } asDictionary. 'selector'->{ 'type'->'string' } asDictionary. 'side'->{ 'type'->'string'. 'enum'->#('instance' 'class') } asDictionary.
 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary.
 'required'->#('className' 'selector') } asDictionary ]
{ #category : 'private' }
PharoCAToolGetMethodAST class >> snippetOf: node source: source [
 | start stop text |
 start:=node start. stop:=node stop.
 ((start isNil or:[stop isNil]) or:[start<1 or:[stop<start or:[start>source size]]]) ifTrue:[^''].
 stop:=stop min:source size. text:=source copyFrom:start to:stop.
 text size>180 ifTrue:[text:=(text copyFrom:1 to:177),'...'].
 ^ text ]
{ #category : 'private' }
PharoCAToolGetMethodAST class >> collectNode: node parent: parent depth: depth source: source into: nodes [
 | index item |
 index:=nodes size+1.
 item:={'index'->index. 'parentIndex'->parent. 'depth'->depth. 'type'->node class name. 'start'->node start. 'stop'->node stop. 'source'->(self snippetOf:node source:source)} asDictionary.
 (node respondsTo:#selector) ifTrue:[item at:'selector' put:node selector asString].
 (node respondsTo:#name) ifTrue:[item at:'name' put:node name asString].
 nodes add:item.
 node children do:[:child| self collectNode:child parent:index depth:depth+1 source:source into:nodes ] ]
{ #category : 'execution' }
PharoCAToolGetMethodAST class >> execute: args [
 | cls side behavior selector method source root nodes page scope |
 cls:=PharoCAImageNavigation classNamed:(args at:'className'). side:=args at:'side' ifAbsent:['instance'].
 behavior:=side='class' ifTrue:[cls class] ifFalse:[cls]. selector:=(args at:'selector') asSymbol.
 method:=behavior compiledMethodAt:selector ifAbsent:[Error signal:'Local method not found: ',cls name,' ',side,'>>',selector asString].
 source:=method sourceCode. root:=method sourceNode. nodes:=OrderedCollection new.
 self collectNode:root parent:nil depth:0 source:source into:nodes.
 scope:='get_method_ast|',cls name,'|',side,'|',selector asString.
 page:=PharoCAToolPagination pageItems:nodes asArray arguments:args scope:scope.
 ^ {'className'->cls name. 'side'->side. 'selector'->selector asString. 'nodes'->(page at:'items'). 'page'->(page at:'page')} asDictionary ]
