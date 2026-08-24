Class { #name : 'PharoCARuntimeHandleRegistryTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'tests' }
PharoCARuntimeHandleRegistryTest >> testStrongHandlesAreTypedStableAndExplicitlyReleased [
 | registry object h1 h2 |
 registry:=PharoCARuntimeHandleRegistry new. object:=Object new.
 h1:=registry handleFor:object kind:#process metadata:Dictionary new cleanup:nil.
 h2:=registry handleFor:object kind:#process metadata:Dictionary new cleanup:nil.
 self assert:h1 equals:'process-1'. self assert:h2 equals:h1.
 self assert:(registry objectAt:h1 kind:#process) identicalTo:object.
 self should:[registry objectAt:h1 kind:#debugger] raise:Error.
 self assert:(registry forget:h1). self should:[registry objectAt:h1 kind:#process] raise:Error
]

{ #category : 'tests' }
PharoCARuntimeHandleRegistryTest >> testReleaseAndReleaseAllRunCleanupExactlyOnce [
 | registry count h1 h2 |
 registry:=PharoCARuntimeHandleRegistry new. count:=0.
 h1:=registry add:Object new kind:#debugger metadata:Dictionary new cleanup:[:o :m|count:=count+1].
 h2:=registry add:Object new kind:#debugPoint metadata:Dictionary new cleanup:[:o :m|count:=count+1].
 self assert:(registry release:h1). self deny:(registry release:h1). self assert:count equals:1.
 registry releaseAll. self assert:count equals:2. self assert:registry size equals:0. self assert:(registry handlesOfKind:#debugPoint) isEmpty
]
