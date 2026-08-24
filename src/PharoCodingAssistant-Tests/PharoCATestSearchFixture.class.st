"Fixture with deliberately unique source markers for live-image source search tests."
Class {
	#name : 'PharoCATestSearchFixture',
	#superclass : 'Object',
	#instVars : [ 'probeValue' ],
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'search-fixture' }
PharoCATestSearchFixture >> alphaMarker [
	^ 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'
]

{ #category : 'search-fixture' }
PharoCATestSearchFixture >> caseMarker [
	^ 'Pca048_CaseSensitive_Source_Marker'
]

{ #category : 'search-fixture' }
PharoCATestSearchFixture class >> classSideMarker [
	^ 'PCA048_UNIQUE_CLASS_SIDE_MARKER'
]

{ #category : '049-fixture' }
PharoCATestSearchFixture >> readProbeValue [
	^ probeValue
]

{ #category : '049-fixture' }
PharoCATestSearchFixture >> writeProbeValue: anObject [
	probeValue := anObject
]

{ #category : '049-fixture' }
PharoCATestSearchFixture >> referenceFixtureClass [
	^ PharoCATestSearchFixture
]

{ #category : '049-fixture' }
PharoCATestSearchFixture >> pragmaMarker: anObject [
	<pca049Marker: 'alpha'>
	^ anObject
]

{ #category : '049-fixture' }
PharoCATestSearchFixture >> astMarker: anObject [
	| local |
	local := anObject + 1.
	^ self pragmaMarker: local
]
