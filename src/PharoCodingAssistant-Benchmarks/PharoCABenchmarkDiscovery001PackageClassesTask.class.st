Class {
	#name : 'PharoCABenchmarkDiscovery001PackageClassesTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Discovery',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Discovery'
}

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> id [
	^ 'discovery-001-package-classes'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> title [
	^ 'Discover the package organizer API'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> prompt [
	^ 'Create class PCABenchmarkPackageQuery in package PCABenchmark-Workspace. Implement instance method classNamesInPackageNamed:. Its argument is a package name Symbol or String. Use the live Pharo package model to answer a sorted Array of the names of classes defined by that package. If the package does not exist, answer an empty Array. Do not hard-code package contents or scan source files. Discover the package APIs available in this image and verify the method on #Kernel and #PharoCodingAssistant-Benchmarks.'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> category [
	^ 'discovery'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> tags [
	^ #('discovery' 'packages' 'reflection')
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery001PackageClassesTask >> maxIterations [
	^ 24
]
