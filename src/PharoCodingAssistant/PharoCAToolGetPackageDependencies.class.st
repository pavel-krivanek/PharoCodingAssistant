"Computes direct live-image package dependencies from superclass/trait relations and literal class references in package methods."
Class { #name : 'PharoCAToolGetPackageDependencies', #superclass : 'PharoCATool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolGetPackageDependencies class >> capability [ ^ #inspection ]
{ #category : 'execution' } PharoCAToolGetPackageDependencies class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' } PharoCAToolGetPackageDependencies class >> toolPack [ ^ #browse ]
{ #category : 'definition' } PharoCAToolGetPackageDependencies class >> toolName [ ^ #get_package_dependencies ]
{ #category : 'definition' }
PharoCAToolGetPackageDependencies class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'get_package_dependencies' description:'Computes direct package dependencies from installed superclass/trait relations and CompiledMethod referencedClasses, including extension methods. Returns dependency packages with referenced class names; cursor-paginated.' parameters:{
 'type'->'object'. 'properties'->{ 'package'->{ 'type'->'string' } asDictionary. 'limit'->{ 'type'->'integer'. 'minimum'->1. 'maximum'->200 } asDictionary. 'cursor'->{ 'type'->'string' } asDictionary } asDictionary. 'required'->#('package') } asDictionary ]
{ #category : 'private' }
PharoCAToolGetPackageDependencies class >> addClass: targetClass fromPackage: sourcePackage to: dependencies [
 | targetPackage names |
 targetClass ifNil:[^self]. targetPackage:=targetClass package name.
 targetPackage = sourcePackage name ifTrue:[^self].
 names := dependencies at:targetPackage ifAbsentPut:[Set new]. names add:targetClass name ]
{ #category : 'execution' }
PharoCAToolGetPackageDependencies class >> execute: args context: context [
 | packageName package dependencies methods items page |
 packageName:=args at:'package'. package:=PackageOrganizer default packageNamed:packageName ifAbsent:[Error signal:'Package not found: ',packageName].
 dependencies:=Dictionary new.
 package definedClasses doWithIndex:[:cls :i| (i \\ 100=0) ifTrue:[context checkActive]. self addClass:cls superclass fromPackage:package to:dependencies. cls traits do:[:trait|self addClass:trait fromPackage:package to:dependencies] ].
 methods := package methods.
 methods doWithIndex:[:m :i| (i \\ 500=0) ifTrue:[context checkActive]. m referencedClasses do:[:cls|self addClass:cls fromPackage:package to:dependencies] ].
 items := dependencies associations collect:[:assoc| |names| names:=assoc value asSortedCollection asArray. {'package'->assoc key. 'referencedClassCount'->names size. 'referencedClasses'->names} asDictionary].
 items := (items asSortedCollection:[:a :b|(a at:'package')<=(b at:'package')]) asArray.
 page:=PharoCAToolPagination pageItems:items arguments:args scope:'get_package_dependencies|',packageName.
 ^ {'package'->packageName. 'dependencies'->(page at:'items'). 'page'->(page at:'page')} asDictionary ]
