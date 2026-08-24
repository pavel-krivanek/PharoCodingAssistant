Class { #name : 'PharoCAToolGetPackageDependenciesTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolGetPackageDependenciesTest >> testFindsProductionDependencyFromTestPackage [
 | r | r:=PharoCAToolGetPackageDependencies execute:{'package'->'PharoCodingAssistant-Tests'} asDictionary context:PharoCAToolExecutionContext unlimited.
 self assert:((r at:'dependencies') anySatisfy:[:e|(e at:'package')='PharoCodingAssistant']) ]
{ #category : 'tests' }
PharoCAToolGetPackageDependenciesTest >> testUnknownPackageAndCancellationAreExplicit [
 | context | self should:[PharoCAToolGetPackageDependencies execute:{'package'->'NoPCA049Package'} asDictionary context:PharoCAToolExecutionContext unlimited] raise:Error.
 context:=PharoCAToolExecutionContext unlimited. context cancellationToken cancel. self should:[PharoCAToolGetPackageDependencies execute:{'package'->'PharoCodingAssistant-Tests'} asDictionary context:context] raise:PharoCAToolExecutionCancelled ]
