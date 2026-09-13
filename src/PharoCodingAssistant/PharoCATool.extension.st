Extension { #name : #PharoCATool }

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCATool class >> loadingStrategy [
	"How this tool enters a session's exposed tool set.

	#eager    - the tool's pack is active in a new session.
	#lazy     - the tool is registered in the catalog but its pack must be enabled.
	#disabled - the tool class is intentionally omitted from the registry.

	The default preserves the existing PCA behaviour: catalog/core are available
	immediately, all other packs are lazy. Individual tool classes can override
	this method when their lifecycle differs from their pack's usual policy."

	(#(catalog core) includes: self toolPack) ifTrue: [ ^ #eager ].
	^ #lazy
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCATool class >> supportedLoadingStrategies [
	^ #(eager lazy disabled)
]
