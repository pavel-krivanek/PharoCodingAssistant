"Side-effect-conscious presentation for inspection tools. It deliberately avoids sending arbitrary domain messages such as size or printString to general objects."
Class {
	#name : 'PharoCAObjectPresenter',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'presenting' }
PharoCAObjectPresenter class >> previewOf: object [
	| cls printed |
	object isNil ifTrue: [ ^ 'nil' ].
	(object == true or: [ object == false ]) ifTrue: [ ^ object printString ].
	cls := object class.
	(cls isImmediateClass or: [ (cls inheritsFrom: Number) or: [ (cls inheritsFrom: String) or: [ cls = Symbol ] ] ]) ifTrue: [
		printed := object printString.
		^ printed size > 1000 ifTrue: [ (printed first: 1000), '…' ] ifFalse: [ printed ] ].
	^ '<', cls name asString, '>'
]
