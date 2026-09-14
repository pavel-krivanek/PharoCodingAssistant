Class {
	#name : 'PharoCABenchmarkBasic008PalindromeTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> id [
	^ 'basic-008-palindrome'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> title [
	^ 'Recognize a palindrome'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> prompt [
	^ 'Create class PCABenchmarkPalindrome in package PCABenchmark-Workspace. Implement instance method isPalindrome: for strings. Comparison is exact and case-sensitive; the empty string is a palindrome. Verify at least ''level'', ''Level'', and the empty string, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> category [
	^ 'strings'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> tags [
	^ #('basic' 'strings')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic008PalindromeTask >> maxIterations [
	^ 10
]
