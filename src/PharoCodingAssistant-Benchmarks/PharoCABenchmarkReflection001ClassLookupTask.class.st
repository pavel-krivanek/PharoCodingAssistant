Class {
	#name : 'PharoCABenchmarkReflection001ClassLookupTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Reflection',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Reflection'
}

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> id [
	^ 'reflection-001-class-lookup'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> title [
	^ 'Resolve a class by name'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> prompt [
	^ 'Create class PCABenchmarkReflection in package PCABenchmark-Workspace. Implement instance method classNamed: whose argument is a String. Answer the class with that global name when it exists, otherwise nil. Use Pharo image/global-environment reflection rather than a hard-coded table. Verify Object and a missing name, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> category [
	^ 'reflection'
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> tags [
	^ #('reflection' 'globals')
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkReflection001ClassLookupTask >> maxIterations [
	^ 14
]
