Class {
	#name : 'PharoCABenchmarkAnnouncements001CountDuringTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Announcements',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Announcements'
}

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> id [
	^ 'announcements-001-count-during'
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> title [
	^ 'Subscribe temporarily to an Announcer'
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> prompt [
	^ 'Create class PCABenchmarkAnnouncementCounter in package PCABenchmark-Workspace. Implement instance method countDuring:on:. The first argument is a zero-argument block and the second an Announcer. Temporarily subscribe the receiver to Announcement (including subclasses), count announcements delivered while the block runs, unsubscribe the receiver before returning even if the block signals an exception, and answer the count on normal completion. Do not leave a subscription behind. Discover and use the Announcer API present in this image, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> category [
	^ 'announcements'
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> tags [
	^ #('announcements' 'events' 'ensure')
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkAnnouncements001CountDuringTask >> maxIterations [
	^ 22
]
