"Session-scoped lazy skill activation. Skill bodies are never copied into session messages; active bodies are exposed as ephemeral instruction sources for provider requests."
Class {
	#name : 'PharoCASkillRegistry',
	#superclass : 'Object',
	#instVars : [ 'skillsByName', 'skillNames', 'activeNamesBySessionId', 'mutex', 'discoveryCharacterBudget' ],
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'activation' }
PharoCASkillRegistry >> activateNamed: aName session: aSession [
	| skill active |
	skill := self skillNamed: aName ifAbsent: [ Error signal: 'Unknown skill: ', aName asString ].
	mutex wait.
	[
		active := activeNamesBySessionId at: aSession id ifAbsentPut: [ Set new ].
		active add: skill name
	] ensure: [ mutex signal ].
	^ skill
]

{ #category : 'accessing' }
PharoCASkillRegistry >> activeSkillNamesForSession: aSession [
	^ ((self activeSkillsForSession: aSession) collect: [ :each | each name ]) asArray
]

{ #category : 'accessing' }
PharoCASkillRegistry >> activeSkillsForSession: aSession [
	| names |
	mutex wait.
	[
		names := (activeNamesBySessionId at: aSession id ifAbsent: [ Set new ]) copy
	] ensure: [ mutex signal ].
	^ ((self skills select: [ :each | names includes: each name ]) asSortedCollection: [ :a :b | a name <= b name ]) asArray
]

{ #category : 'state' }
PharoCASkillRegistry >> clearStateForSession: aSession [
	mutex wait.
	[ activeNamesBySessionId removeKey: aSession id ifAbsent: [ ] ] ensure: [ mutex signal ]
]

{ #category : 'activation' }
PharoCASkillRegistry >> deactivateNamed: aName session: aSession [
	| active removed |
	removed := false.
	mutex wait.
	[
		active := activeNamesBySessionId at: aSession id ifAbsent: [ nil ].
		active ifNotNil: [
			(active includes: aName asString) ifTrue: [
				active remove: aName asString.
				removed := true ] ]
	] ensure: [ mutex signal ].
	^ removed
]

{ #category : 'accessing' }
PharoCASkillRegistry >> discoveryCharacterBudget [ ^ discoveryCharacterBudget ]

{ #category : 'accessing' }
PharoCASkillRegistry >> discoveryCharacterBudget: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Skill discovery character budget must be positive' ].
	discoveryCharacterBudget := anInteger
]

{ #category : 'discovery' }
PharoCASkillRegistry >> discoveryInstructionSourceForSession: aSession [
	| discoverable text |
	"Built-in skills are named by the compact system prompt and remain inspectable via list_skills.
	Do not spend context repeating their inactive metadata on every model request. Workspace and
	extension skills are dynamic, so keep their discovery descriptions ephemeral and visible."
	discoverable := self skills reject: [ :skill | skill scope = #builtin ].
	discoverable isEmpty ifTrue: [ ^ nil ].
	text := self discoveryTextForSession: aSession skills: discoverable.
	^ (PharoCAInstructionSource named: 'available-skills' content: text)
		kind: #skills;
		priority: 900;
		yourself
]

{ #category : 'discovery' }
PharoCASkillRegistry >> discoveryTextForSession: aSession [
	^ self discoveryTextForSession: aSession skills: self skills
]

{ #category : 'discovery-private' }
PharoCASkillRegistry >> discoveryTextForSession: aSession skills: skillsToDescribe [
	| stream count included line activeNames remaining text |
	stream := String new writeStream.
	stream nextPutAll: 'Optional skills are available. Activate one only when its procedure is relevant, using activate_skill. Use list_skills for the complete catalog.'; cr.
	activeNames := (self activeSkillNamesForSession: aSession) asSet.
	count := skillsToDescribe size.
	included := 0.
	skillsToDescribe do: [ :skill |
		line := '- ', skill name, ': ', skill description,
			((activeNames includes: skill name) ifTrue: [ ' [active]' ] ifFalse: [ '' ]), String lf.
		(stream position + line size + 80 <= discoveryCharacterBudget)
			ifTrue: [ stream nextPutAll: line. included := included + 1 ]
			ifFalse: [ included < count ifTrue: [
				remaining := count - included.
				stream nextPutAll: ('... {1} more skill(s) omitted; use list_skills to inspect them.' format: { remaining }).
				included := count ] ] ].
	text := stream contents.
	^ text size <= discoveryCharacterBudget
		ifTrue: [ text ]
		ifFalse: [ text copyFrom: 1 to: discoveryCharacterBudget ]
]

{ #category : 'initialization' }
PharoCASkillRegistry >> initialize [
	super initialize.
	skillsByName := Dictionary new.
	skillNames := OrderedCollection new.
	activeNamesBySessionId := Dictionary new.
	mutex := Semaphore forMutualExclusion.
	discoveryCharacterBudget := 4000
]

{ #category : 'instructions' }
PharoCASkillRegistry >> instructionSourcesForSession: aSession [
	^ ((self activeSkillsForSession: aSession) collect: [ :each | each asInstructionSource ]) asArray
]

{ #category : 'registration' }
PharoCASkillRegistry >> register: aSkill [
	mutex wait.
	[
		(skillsByName includesKey: aSkill name) ifTrue: [ Error signal: 'Skill already registered: ', aSkill name ].
		skillsByName at: aSkill name put: aSkill.
		skillNames add: aSkill name
	] ensure: [ mutex signal ].
	^ aSkill
]

{ #category : 'accessing' }
PharoCASkillRegistry >> size [
	| size |
	mutex wait.
	[ size := skillNames size ] ensure: [ mutex signal ].
	^ size
]

{ #category : 'accessing' }
PharoCASkillRegistry >> skillNamed: aName ifAbsent: aBlock [
	| skill |
	mutex wait.
	[ skill := skillsByName at: aName asString ifAbsent: [ nil ] ] ensure: [ mutex signal ].
	^ skill ifNil: aBlock ifNotNil: [ skill ]
]

{ #category : 'accessing' }
PharoCASkillRegistry >> skills [
	| result |
	mutex wait.
	[ result := skillNames collect: [ :name | skillsByName at: name ] ] ensure: [ mutex signal ].
	^ (result asSortedCollection: [ :a :b | a name <= b name ]) asArray
]

{ #category : 'registration' }
PharoCASkillRegistry >> unregisterNamed: aName [
	| skill |
	mutex wait.
	[
		skill := skillsByName removeKey: aName asString ifAbsent: [ ^ nil ].
		skillNames remove: aName asString ifAbsent: [ ].
		activeNamesBySessionId valuesDo: [ :set | set remove: aName asString ifAbsent: [ ] ]
	] ensure: [ mutex signal ].
	^ skill
]


{ #category : 'persistence' }
PharoCASkillRegistry >> restoreActiveSkillNames: names forSession: aSession [
	| normalized |
	normalized := names collect: [ :each | each asString ].
	normalized do: [ :name |
		self skillNamed: name ifAbsent: [ Error signal: 'Cannot restore unknown active skill: ', name ] ].
	mutex wait.
	[ activeNamesBySessionId at: aSession id put: normalized asSet ] ensure: [ mutex signal ]
]
