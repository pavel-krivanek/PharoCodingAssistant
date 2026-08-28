"Built-in domain knowledge adapted from ChatPharo's MIT-licensed AI-ChatPharo-Skills package. The bodies are deliberately concise, verification-oriented rewrites rather than verbatim copies."
Class {
	#name : 'PharoCABuiltinSkills',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'accessing' }
PharoCABuiltinSkills class >> all [
	^ { self collections. self spec2. self bloc. self roassal }
]

{ #category : 'skills' }
PharoCABuiltinSkills class >> collections [
	^ (PharoCASkill
		named: 'Collections'
		description: 'Pharo collection selection and idioms: Array/OrderedCollection/Set/Dictionary, enumeration, grouping, folding and streams.'
		instructions: self collectionsInstructions)
		keywords: #(Collection OrderedCollection Array Set IdentitySet Dictionary SortedCollection Bag Association Stream collect select reject detect inject groupedBy flatCollect keysAndValuesDo);
		scope: #builtin;
		yourself
]

{ #category : 'instructions-private' }
PharoCABuiltinSkills class >> collectionsInstructions [
	^ '## Pharo Collections

Use this skill when choosing collection representations or writing non-trivial enumeration code. Inspect the live image when exact protocol details matter.

### Choosing a collection
- `Array` is fixed-size and indexed. Literal arrays `#(...)` contain literals; `{ ... }` evaluates expressions and builds an Array.
- `OrderedCollection` is the usual growable ordered collection. Prefer it when size changes frequently.
- `Set` removes duplicates using equality/hash semantics. Use `IdentitySet` when identity (`==`) is the intended key semantics.
- `Dictionary` maps keys to values. Prefer `at:ifAbsent:` when absence is normal, and `keysAndValuesDo:` when both sides are needed.
- `SortedCollection` maintains a sort order; do not use it merely to obtain one sorted snapshot.
- `Bag` models multiplicity/counts rather than unique membership.

### Prefer collection protocol over manual loops
Use `do:` for effects, `collect:` for one-to-one transformation, `select:` / `reject:` for filtering, `detect:ifNone:` for lookup, `anySatisfy:` / `allSatisfy:` for predicates, `inject:into:` for folds, `flatCollect:` for map+flatten, and `groupedBy:` for partitioning. When a combined selector such as `select:thenCollect:` exists and improves clarity, prefer it to needless intermediate collections.

```smalltalk
adultCities := people
    select: [ :each | each age >= 18 ]
    thenCollect: [ :each | each city ].

counts := words groupedBy: [ :each | each first ].
total := values inject: 0 into: [ :sum :each | sum + each ].
```

### Mutation and return values
Do not assume mutating messages return the receiver. If a cascade must return the configured object, finish with `yourself`. Distinguish `add:`/`remove:` mutation from functional operations such as `collect:`. When changing a collection while traversing it, iterate over a copy or use an API designed for removal.

### Species and equality
Collection transforms often preserve the receiver species when sensible; do not hard-code an Array/OrderedCollection result unless the caller requires that representation. For Sets and Dictionaries, ensure keys/elements implement compatible `=` and `hash`; use identity collections when identity is intentional.

### Streams and strings
For incremental text construction prefer `String streamContents:` rather than repeated concatenation in a loop. Use read/write streams when sequential consumption or production is the natural abstraction.

Before introducing a custom loop or collection class, search the existing protocol for a selector that expresses the operation directly.'
]

{ #category : 'skills' }
PharoCABuiltinSkills class >> spec2 [
	^ (PharoCASkill
		named: 'Spec2'
		description: 'Pharo Spec2 desktop UI: presenters, layouts, widgets, events, models and window lifecycle.'
		instructions: self spec2Instructions)
		keywords: #(Spec2 SpPresenter SpApplication SpBoxLayout SpGridLayout SpPanedLayout initializePresenters connectPresenters defaultLayout initializeWindow newButton newTextInput newLabel newList newTable newTree newNotebook presenter widget dialog);
		scope: #builtin;
		yourself
]

{ #category : 'instructions-private' }
PharoCABuiltinSkills class >> spec2Instructions [
	^ '## Spec2 UI

Use this skill for Pharo desktop UI built with Spec2. The supplied Pharo 14 image contains `SpPresenter`, `SpApplication`, `SpBoxLayout`, `SpGridLayout` and the standard presenter classes. Still inspect the live class/method before relying on a less-common selector.

### Presenter lifecycle
A normal presenter subclasses `SpPresenter` and separates responsibilities:
- `initializePresenters` creates/configures child presenters.
- `connectPresenters` installs callbacks/connections.
- `defaultLayout` answers the layout tree.
- `initializeWindow:` configures title/extent/window behavior when needed.
- `setModelBeforeInitialization:` is appropriate when construction depends on an external model.

```smalltalk
MyPresenter >> initializePresenters
    input := self newTextInput.
    saveButton := self newButton label: ''Save''; yourself.

MyPresenter >> connectPresenters
    saveButton action: [ self save ].

MyPresenter >> defaultLayout
    ^ SpBoxLayout newTopToBottom
        add: input expand: false;
        add: saveButton expand: false;
        yourself
```

Keep domain logic outside widget callbacks where possible; callbacks should delegate to presenter/model behavior.

### Layouts
Use `SpBoxLayout` for ordinary vertical/horizontal composition, `SpGridLayout` for aligned rows/columns, and paned/notebook layouts only when the interaction requires them. Prefer layout constraints over manual pixel positioning. Do not create widgets in `defaultLayout`; create them once in `initializePresenters` and compose them in the layout.

### Widgets and data
Factories on `SpPresenter` (`newButton`, `newTextInput`, `newLabel`, `newList`, `newTable`, `newTree`, etc.) are preferred over constructing backend-specific widgets directly. Configure collections/models before selection callbacks when initialization order matters. For tables, use proper table-column presenters and keep display/conversion logic side-effect free.

### Events and UI thread
Connect events once; avoid installing duplicate handlers during refresh. UI mutation belongs on the UI process. For asynchronous work, keep long computation off the UI process and marshal only the presentation update back to it.

### Verification
Spec2 evolves. Before emitting unfamiliar code, browse/search the concrete presenter class and selector in the running image. Reuse an existing presenter pattern from the target package when one exists.'
]

{ #category : 'skills' }
PharoCABuiltinSkills class >> bloc [
	^ (PharoCASkill
		named: 'Bloc'
		description: 'Bloc scene-graph/vector UI concepts: elements, layouts, constraints, events, text, spaces and custom drawing; optional package.'
		instructions: self blocInstructions)
		keywords: #(Bloc BlElement BlSpace BlTextElement BlLinearLayout BlFrameLayout BlGridLayout BlClickEvent BlBorder BlRoundedRectangleGeometry constraintsDo openInNewSpace RopedText scenegraph Skia);
		scope: #builtin;
		yourself
]

{ #category : 'instructions-private' }
PharoCABuiltinSkills class >> blocInstructions [
	^ '## Bloc UI

Bloc is an optional low-level scene-graph/vector UI framework. **Do not assume it is installed.** In the supplied base Pharo 14 image `BlElement` is absent. Before writing Bloc code, use code browsing/search to verify `BlElement` and the relevant Bloc packages/classes are loaded. If they are absent, report that fact or use the project''s actual UI framework instead of inventing selectors.

When Bloc is installed, its core model is a tree of elements (commonly rooted in a space). Elements own geometry/appearance, children, layout constraints and event handlers. Typical work therefore follows this order:
1. create/configure elements;
2. compose them as parent/children;
3. choose a layout and constraints rather than manually calculating every position;
4. attach narrowly scoped event handlers;
5. open/show through a space or the project''s established host.

Common concepts in Bloc versions include `BlElement`, `BlTextElement`, `BlSpace`, linear/frame/grid layouts, constraints, borders/backgrounds, rounded geometry, rich `RopedText`, and mouse/click events. These APIs are version-sensitive, so treat the names as discovery anchors, not permission to guess exact selectors.

For custom drawing, first inspect subclasses already present in the loaded Bloc version and follow their canvas protocol. For interaction, verify the exact event classes and propagation model before implementing drag/hover/click behavior. After structural or visual changes, request layout/redraw through the API used by that Bloc version rather than forcing Morphic refresh behavior onto Bloc.

Prefer a higher-level framework (for example Spec2) for ordinary forms/dialogs unless the project already uses Bloc or needs its scene-graph/rendering capabilities.'
]

{ #category : 'skills' }
PharoCABuiltinSkills class >> roassal [
	^ (PharoCASkill
		named: 'Roassal'
		description: 'Roassal visualization: canvases, shapes/models, layouts, interactions, edges and charts.'
		instructions: self roassalInstructions)
		keywords: #(Roassal RSCanvas RSShape RSBox RSEllipse RSLabel RSLine RSGroup RSGridLayout RSTreeLayout RSForceBasedLayout RSChart RSLinePlot RSBarPlot RSScatterPlot RSDraggable RSPopup RSCanvasController visualization chart graph diagram);
		scope: #builtin;
		yourself
]

{ #category : 'instructions-private' }
PharoCABuiltinSkills class >> roassalInstructions [
	^ '## Roassal Visualization

Use this skill when the task is a visualization, chart or interactive diagram. The supplied Pharo 14 image contains Roassal classes including `RSCanvas`, `RSBox`, `RSEllipse`, `RSLabel`, `RSLine`, common layouts and `RSChart`. Inspect exact selectors for advanced builders/interactions because Roassal APIs evolve.

### Basic model
A canvas owns shapes. Shapes can carry a domain `model`; keep that association when interactions or labels need to map back to domain objects.

```smalltalk
canvas := RSCanvas new.
shapes := values collect: [ :value |
    RSBox new
        size: 20;
        model: value;
        yourself ].
canvas addAll: shapes.
RSGridLayout on: shapes.
```

Open a canvas only when an actual UI result is desired; tests and data preparation should normally avoid opening windows.

### Shapes and layout
Choose shapes (`RSBox`, `RSEllipse`, `RSLabel`, lines/edges, composites/groups) based on semantics, then apply a layout to the collection rather than manually assigning positions. Useful discovery anchors include grid, tree, force-based, circle, horizontal/vertical-line and flow layouts. Verify the exact layout protocol in the running image before using configuration selectors.

### Graphs and edges
Keep node shapes associated with models. Prefer Roassal builders when the installed version provides an appropriate builder; otherwise construct edges from the actual node shapes. Apply graph layouts only after node/edge relationships are established.

### Interactions
Roassal commonly supports click/hover events and attachable interactions such as dragging, popups, highlighting, zooming and panning. Event/interaction selectors are version-sensitive: browse the installed classes before emitting code. Event handlers should update the affected model/shape and request the framework''s normal refresh rather than rebuilding the whole canvas unnecessarily.

### Charts
For line/bar/scatter charts, inspect `RSChart` and the installed plot classes first. Separate data transformation from chart construction so tests can verify the data independently of UI rendering.

Prefer existing visualization conventions in the target package over introducing a new style or interaction model.'
]
