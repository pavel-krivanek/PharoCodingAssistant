"Public benchmark catalog. Expected answers and hidden evaluators deliberately do not live here. Keep the first levels intentionally simple so smaller/local models remain measurable."
Class {
	#name : 'PharoCABenchmarkCatalog',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Core',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Core'
}

{ #category : 'tasks' }
PharoCABenchmarkCatalog class >> allTasks [
	^ self basicTasks, self collectionTasks, self libraryTasks, self testingTasks, self exceptionTasks, self concurrencyTasks, self announcementTasks, self reflectionTasks, self discoveryTasks, self unknownApiTasks, self refactoringTasks, self spec2Tasks, self navigationTasks
]

{ #category : 'tasks - basic' }
PharoCABenchmarkCatalog class >> basicTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'basic-001-expression'
			title: 'Evaluate a simple expression'
			prompt: 'Use the Pharo image to calculate (17 * 3) + 4. Reply with only the decimal result.'
			difficulty: 1
			category: 'language')
			tags: #( 'basic' 'evaluation' );
			maxIterations: 4;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-002-method'
			title: 'Create a tiny method'
			prompt: 'Create class PCABenchmarkBasicAdder in package PCABenchmark-Workspace with instance method add:to: that answers the sum of its two arguments. Verify it with 2 and 3, then finish.'
			difficulty: 1
			category: 'coding')
			tags: #( 'basic' 'coding' );
			maxIterations: 8;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-003-collection'
			title: 'Use a basic collection idiom'
			prompt: 'Create class PCABenchmarkSquares in package PCABenchmark-Workspace with instance method squaresOf: that answers a new collection containing the square of each input element, preserving order. Verify it on #(1 2 3 4), then finish.'
			difficulty: 1
			category: 'collections')
			tags: #( 'basic' 'collections' );
			skillNames: #( 'Collections' );
			maxIterations: 10;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-004-precedence'
			title: 'Respect Smalltalk message precedence'
			prompt: 'Evaluate the Pharo expression 2 + 3 * 4 exactly as written. Reply with only the decimal result.'
			difficulty: 1
			category: 'language')
			tags: #( 'basic' 'language' 'precedence' );
			maxIterations: 4;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-005-condition'
			title: 'Implement a three-way conditional'
			prompt: 'Create class PCABenchmarkSignClassifier in package PCABenchmark-Workspace. Implement instance method classify: so negative numbers answer #negative, zero answers #zero, and positive numbers answer #positive. Verify all three cases, then finish.'
			difficulty: 1
			category: 'coding')
			tags: #( 'basic' 'conditionals' );
			maxIterations: 9;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-006-block'
			title: 'Evaluate a block argument'
			prompt: 'Create class PCABenchmarkBlockApplier in package PCABenchmark-Workspace. Implement instance method apply:to: whose first argument is a one-argument block and whose second argument is a value. Answer the result of evaluating the block with that value. Verify it with [ :x | x * 2 ] and 5, then finish.'
			difficulty: 1
			category: 'language')
			tags: #( 'basic' 'blocks' );
			maxIterations: 9;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-007-range-sum'
			title: 'Sum an integer interval'
			prompt: 'Create class PCABenchmarkRangeSum in package PCABenchmark-Workspace. Implement instance method sumFrom:to: that answers the inclusive sum of the integer interval. If the first argument is greater than the second, answer 0. Verify 1 to 5 and a reversed interval, then finish.'
			difficulty: 2
			category: 'coding')
			tags: #( 'basic' 'intervals' 'iteration' );
			maxIterations: 10;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-008-palindrome'
			title: 'Recognize a palindrome'
			prompt: 'Create class PCABenchmarkPalindrome in package PCABenchmark-Workspace. Implement instance method isPalindrome: for strings. Comparison is exact and case-sensitive; the empty string is a palindrome. Verify at least ''level'', ''Level'', and the empty string, then finish.'
			difficulty: 2
			category: 'strings')
			tags: #( 'basic' 'strings' );
			maxIterations: 10;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-009-repeat-string'
			title: 'Repeat a string'
			prompt: 'Create class PCABenchmarkRepeater in package PCABenchmark-Workspace. Implement instance method repeat:times: that answers a new String containing the first String argument repeated the requested non-negative integer number of times. Zero repetitions answer the empty String. Verify ''ab'' repeated 3 times and zero times, then finish.'
			difficulty: 1
			category: 'strings')
			tags: #( 'basic' 'strings' );
			maxIterations: 9;
			yourself.
		(PharoCABenchmarkTask
			id: 'basic-010-maximum-two'
			title: 'Choose the larger value'
			prompt: 'Create class PCABenchmarkMaximum in package PCABenchmark-Workspace. Implement instance method maximumOf:and: that answers the larger of its two comparable arguments. Equal arguments may answer either argument. Verify it with values in both orders and with equal values, then finish.'
			difficulty: 1
			category: 'coding')
			tags: #( 'basic' 'conditionals' );
			maxIterations: 8;
			yourself
	}
]

{ #category : 'tasks - collections' }
PharoCABenchmarkCatalog class >> collectionTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'collections-001-select-even'
			title: 'Filter even numbers'
			prompt: 'Create class PCABenchmarkEvenFilter in package PCABenchmark-Workspace. Implement instance method evensFrom: that answers a new collection containing only even input numbers in their original order. Do not mutate the input. Verify it on #(1 2 3 4 5 6), then finish.'
			difficulty: 1
			category: 'collections')
			tags: #( 'collections' 'selection' );
			skillNames: #( 'Collections' );
			maxIterations: 10;
			yourself.
		(PharoCABenchmarkTask
			id: 'collections-002-frequency-table'
			title: 'Build a frequency table'
			prompt: 'Create class PCABenchmarkFrequencyTable in package PCABenchmark-Workspace. Implement instance method countsOf: that answers a Dictionary mapping every distinct input element to its occurrence count. The empty input must answer an empty Dictionary. Verify it on #(a b a c a b), then finish.'
			difficulty: 2
			category: 'collections')
			tags: #( 'collections' 'dictionary' 'counting' );
			skillNames: #( 'Collections' );
			maxIterations: 12;
			yourself.
		(PharoCABenchmarkTask
			id: 'collections-003-unique-order'
			title: 'Remove duplicates while preserving order'
			prompt: 'Create class PCABenchmarkUnique in package PCABenchmark-Workspace. Implement instance method uniquePreservingOrder: that answers a new sequence containing the first occurrence of each distinct element in original order. Do not mutate the input. Verify it on #(3 1 3 2 1 4), then finish.'
			difficulty: 2
			category: 'collections')
			tags: #( 'collections' 'set' 'order' );
			skillNames: #( 'Collections' );
			maxIterations: 12;
			yourself.
		(PharoCABenchmarkTask
			id: 'collections-004-group-parity'
			title: 'Group values into a dictionary'
			prompt: 'Create class PCABenchmarkGrouping in package PCABenchmark-Workspace. Implement instance method groupByParity: that answers a Dictionary with keys #odd and #even. Each value is a collection of matching input integers in original order. Both keys must be present even if one group is empty. Verify it on #(1 2 3 4 6), then finish.'
			difficulty: 2
			category: 'collections')
			tags: #( 'collections' 'grouping' 'dictionary' );
			skillNames: #( 'Collections' );
			maxIterations: 14;
			yourself.
		(PharoCABenchmarkTask
			id: 'collections-005-sort-descending'
			title: 'Sort without mutating the input'
			prompt: 'Create class PCABenchmarkSorter in package PCABenchmark-Workspace. Implement instance method descending: that answers a new collection containing the input numbers from largest to smallest. The supplied collection must remain unchanged. Verify it on an OrderedCollection containing 4, 1, 3, 2, then finish.'
			difficulty: 2
			category: 'collections')
			tags: #( 'collections' 'sorting' );
			skillNames: #( 'Collections' );
			maxIterations: 12;
			yourself.
		(PharoCABenchmarkTask
			id: 'collections-006-any-negative'
			title: 'Test whether any value matches'
			prompt: 'Create class PCABenchmarkNegativeQuery in package PCABenchmark-Workspace. Implement instance method hasNegative: that answers true when the supplied collection contains at least one negative number and false otherwise. Empty input answers false. Verify positive-only, mixed, and empty collections, then finish.'
			difficulty: 1
			category: 'collections')
			tags: #( 'basic' 'collections' 'testing' );
			skillNames: #( 'Collections' );
			maxIterations: 9;
			yourself
	}
]

{ #category : 'tasks - libraries' }
PharoCABenchmarkCatalog class >> libraryTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'library-001-stream-lines'
			title: 'Format values with a stream'
			prompt: 'Create class PCABenchmarkLineFormatter in package PCABenchmark-Workspace. Implement instance method linesFor: that answers one String containing each input element printString on its own line, using a single LF character between lines and no trailing LF. Empty input answers the empty string. Use a stream to construct the result. Verify it on #(10 20 30), then finish.'
			difficulty: 2
			category: 'streams')
			tags: #( 'libraries' 'streams' 'strings' );
			maxIterations: 14;
			yourself.
		(PharoCABenchmarkTask
			id: 'library-002-json-decode'
			title: 'Decode JSON with the image library'
			prompt: 'Create class PCABenchmarkJSON in package PCABenchmark-Workspace. Implement instance method decode: that accepts a JSON String and answers the corresponding Pharo object using the JSON support already present in the image. Verify it with {"name":"Ada","values":[1,2,3]}, then finish.'
			difficulty: 2
			category: 'serialization')
			tags: #( 'libraries' 'json' 'ston' );
			maxIterations: 14;
			yourself.
		(PharoCABenchmarkTask
			id: 'library-003-regex-identifier'
			title: 'Use the regex library'
			prompt: 'Create class PCABenchmarkPattern in package PCABenchmark-Workspace. Implement instance method matchesIdentifier: using Pharo''s regex support. It must answer true only when the entire string consists of exactly one uppercase ASCII letter followed by one or more decimal digits. Examples: ''A1'' and ''Z123'' are true; ''a1'', ''AA1'', ''A'', and ''A1x'' are false. Verify these cases, then finish.'
			difficulty: 2
			category: 'regex')
			tags: #( 'libraries' 'regex' );
			maxIterations: 16;
			yourself.
		(PharoCABenchmarkTask
			id: 'library-004-date-difference'
			title: 'Work with Date and Duration'
			prompt: 'Create class PCABenchmarkDates in package PCABenchmark-Workspace. Implement instance method daysBetween:and: whose arguments are Date objects. Answer the signed whole-number day difference secondDate - firstDate. Verify 1 September 2026 to 10 September 2026 gives 9, and verify the reverse direction, then finish.'
			difficulty: 2
			category: 'dates')
			tags: #( 'libraries' 'dates' 'duration' );
			maxIterations: 16;
			yourself.
		(PharoCABenchmarkTask
			id: 'library-005-file-first-line'
			title: 'Read through FileReference'
			prompt: 'Create class PCABenchmarkFiles in package PCABenchmark-Workspace. Implement instance method firstLineOf: whose argument is a FileReference. Open it for reading, answer its first text line without the line terminator, and ensure the stream is closed. An empty file should answer the empty string. Use the FileReference/stream APIs already in the image and verify the method with a temporary file, then finish.'
			difficulty: 2
			category: 'filesystem')
			tags: #( 'libraries' 'filesystem' 'streams' );
			maxIterations: 18;
			yourself.
		(PharoCABenchmarkTask
			id: 'library-006-path-extension'
			title: 'Inspect a FileReference path'
			prompt: 'Create class PCABenchmarkPathInfo in package PCABenchmark-Workspace. Implement instance method extensionOf: whose argument is a FileReference. Answer its final path extension as a String without the dot, or the empty String when the basename has no extension. Use the FileReference/path API rather than manually splitting the full path String. Verify files named report.txt, archive.tar.gz, and README, then finish.'
			difficulty: 2
			category: 'filesystem')
			tags: #( 'libraries' 'filesystem' );
			maxIterations: 14;
			yourself
	}
]

{ #category : 'tasks - testing' }
PharoCABenchmarkCatalog class >> testingTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'testing-001-sunit-factorial'
			title: 'Create and run basic SUnit tests'
			prompt: 'Create a TestCase subclass named PCABenchmarkIntegerFactorialTest in package PCABenchmark-Workspace. Add at least three test methods that meaningfully verify Integer>>factorial, including 0 factorial, 1 factorial, and 5 factorial. Run the test class and leave all its tests passing, then finish.'
			difficulty: 2
			category: 'testing')
			tags: #( 'testing' 'sunit' );
			maxIterations: 18;
			yourself.
		(PharoCABenchmarkTask
			id: 'testing-002-sunit-exception'
			title: 'Test an expected exception with SUnit'
			prompt: 'Create a TestCase subclass named PCABenchmarkDictionaryAbsentKeyTest in package PCABenchmark-Workspace. Add at least two tests: one must verify normal Dictionary insertion/retrieval, and another must use SUnit exception assertions to verify that reading a missing key with Dictionary>>at: signals an Error. Run the test class and leave all tests passing, then finish.'
			difficulty: 2
			category: 'testing')
			tags: #( 'testing' 'sunit' 'exceptions' );
			maxIterations: 16;
			yourself
	}
]


{ #category : 'tasks - exceptions' }
PharoCABenchmarkCatalog class >> exceptionTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'exceptions-001-safe-division'
			title: 'Handle division by zero'
			prompt: 'Create class PCABenchmarkSafeDivision in package PCABenchmark-Workspace. Implement instance method divide:by: that answers the normal quotient, but answers #divisionByZero when Pharo signals division by zero. Do not pre-test the denominator; handle the exception raised by the division operation. Verify a normal division and division by zero, then finish.'
			difficulty: 2
			category: 'exceptions')
			tags: #( 'exceptions' 'error-handling' ); maxIterations: 12; yourself.
		(PharoCABenchmarkTask
			id: 'exceptions-002-ensure-cleanup'
			title: 'Guarantee cleanup with ensure:'
			prompt: 'Create class PCABenchmarkEnsure in package PCABenchmark-Workspace. Implement instance method evaluate:ensuring:. The first argument is a zero-argument work block and the second a zero-argument cleanup block. Answer the work block result. The cleanup block must run exactly once whether the work block succeeds or signals an exception, and any work exception must continue to propagate after cleanup. Verify both success and error cases, then finish.'
			difficulty: 2
			category: 'exceptions')
			tags: #( 'exceptions' 'ensure' 'blocks' ); maxIterations: 14; yourself
	}
]

{ #category : 'tasks - concurrency' }
PharoCABenchmarkCatalog class >> concurrencyTasks [
	^ { (PharoCABenchmarkTask
		id: 'concurrency-001-fork-wait'
		title: 'Fork work and wait with a Semaphore'
		prompt: 'Create class PCABenchmarkAsyncRunner in package PCABenchmark-Workspace. Implement instance method runAndWait: for a zero-argument block. Evaluate the block in a newly forked Pharo Process, wait for its completion using a Semaphore, and answer the block result. The method must not simply evaluate the block synchronously. Verify that the block runs in a different Process and that its result is returned, then finish.'
		difficulty: 3
		category: 'concurrency') tags: #( 'processes' 'semaphore' 'concurrency' ); maxIterations: 18; yourself }
]

{ #category : 'tasks - announcements' }
PharoCABenchmarkCatalog class >> announcementTasks [
	^ { (PharoCABenchmarkTask
		id: 'announcements-001-count-during'
		title: 'Subscribe temporarily to an Announcer'
		prompt: 'Create class PCABenchmarkAnnouncementCounter in package PCABenchmark-Workspace. Implement instance method countDuring:on:. The first argument is a zero-argument block and the second an Announcer. Temporarily subscribe the receiver to Announcement (including subclasses), count announcements delivered while the block runs, unsubscribe the receiver before returning even if the block signals an exception, and answer the count on normal completion. Do not leave a subscription behind. Discover and use the Announcer API present in this image, then finish.'
		difficulty: 3
		category: 'announcements') tags: #( 'announcements' 'events' 'ensure' ); maxIterations: 22; yourself }
]

{ #category : 'tasks - reflection' }
PharoCABenchmarkCatalog class >> reflectionTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'reflection-001-class-lookup'
			title: 'Resolve a class by name'
			prompt: 'Create class PCABenchmarkReflection in package PCABenchmark-Workspace. Implement instance method classNamed: whose argument is a String. Answer the class with that global name when it exists, otherwise nil. Use Pharo image/global-environment reflection rather than a hard-coded table. Verify Object and a missing name, then finish.'
			difficulty: 2
			category: 'reflection') tags: #( 'reflection' 'globals' ); maxIterations: 14; yourself.
		(PharoCABenchmarkTask
			id: 'reflection-002-selector-prefix'
			title: 'Inspect selectors of a class'
			prompt: 'Create class PCABenchmarkSelectorQuery in package PCABenchmark-Workspace. Implement instance method selectorsBeginningWith:of:. The first argument is a String prefix and the second a class. Answer a sorted Array of selector Symbols defined directly by that class whose textual selector begins with the prefix. Do not include inherited selectors. Verify it against a class in the benchmark package, then finish.'
			difficulty: 2
			category: 'reflection') tags: #( 'reflection' 'selectors' 'browsing' ); maxIterations: 16; yourself
	}
]

{ #category : 'tasks - discovery' }
PharoCABenchmarkCatalog class >> discoveryTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'discovery-001-package-classes'
			title: 'Discover the package organizer API'
			prompt: 'Create class PCABenchmarkPackageQuery in package PCABenchmark-Workspace. Implement instance method classNamesInPackageNamed:. Its argument is a package name Symbol or String. Use the live Pharo package model to answer a sorted Array of the names of classes defined by that package. If the package does not exist, answer an empty Array. Do not hard-code package contents or scan source files. Discover the package APIs available in this image and verify the method on #Kernel and #PharoCodingAssistant-Benchmarks.'
			difficulty: 3
			category: 'discovery')
			tags: #( 'discovery' 'packages' 'reflection' );
			maxIterations: 24;
			yourself.
		(PharoCABenchmarkTask
			id: 'discovery-002-implementor-classes'
			title: 'Discover implementors through image navigation'
			prompt: 'Create class PCABenchmarkImplementorQuery in package PCABenchmark-Workspace. Implement instance method classNamesImplementing:. Its argument is a selector Symbol. Ask the live Pharo image/navigation facilities for methods implementing that selector and answer a sorted Array of unique defining-class names as Strings. Do not maintain a hard-coded class list and do not search source text. Verify it with benchmark-fixture selectors that have one implementor and a selector that has several implementors.'
			difficulty: 3
			category: 'discovery')
			tags: #( 'discovery' 'navigation' 'implementors' );
			maxIterations: 26;
			yourself.
		(PharoCABenchmarkTask
			id: 'discovery-003-sender-signatures'
			title: 'Discover senders through image navigation'
			prompt: 'Create class PCABenchmarkSenderQuery in package PCABenchmark-Workspace. Implement instance method senderSignaturesOf:. Its argument is a selector Symbol. Use Pharo image/navigation APIs to find compiled methods that send that selector. Answer a sorted Array of unique Strings formatted exactly as ClassName>>selector. Do not implement this by scanning source Strings. Verify it with selectors used by the benchmark fixture call chains.'
			difficulty: 4
			category: 'discovery')
			tags: #( 'discovery' 'navigation' 'senders' );
			maxIterations: 30;
			yourself.
		(PharoCABenchmarkTask
			id: 'discovery-004-ast-sent-selectors'
			title: 'Discover and use the Pharo AST API'
			prompt: 'Create class PCABenchmarkASTQuery in package PCABenchmark-Workspace. Implement instance method selectorsSentByMethodSource:. The argument is a complete Smalltalk method source String. Parse it using the parser/AST facilities already present in this plain Pharo image and answer a sorted Array of the unique selector Symbols sent anywhere in the method body. Do not use regexes, substring matching, or manual source tokenization. Verify it with unary, binary, keyword, nested, and cascade sends.'
			difficulty: 4
			category: 'discovery')
			tags: #( 'discovery' 'compiler' 'ast' 'parser' );
			maxIterations: 32;
			yourself
	}
]

{ #category : 'tasks - unknown api' }
PharoCABenchmarkCatalog class >> unknownApiTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'unknown-001-telemetry-mean'
			title: 'Learn an unfamiliar telemetry API'
			prompt: 'The PharoCodingAssistant-Benchmarks fixture code contains a small benchmark-local telemetry API that stores numeric samples by channel. Its API is intentionally not a standard Pharo library. Inspect the live image to discover its public protocol. Create class PCABenchmarkTelemetryAnalyzer in package PCABenchmark-Workspace with instance method meanFor:in:. The first argument is a channel key and the second is an instance of the fixture telemetry API. Answer the arithmetic mean of samples on that channel, or nil when the channel has no samples. Use the fixture public protocol rather than accessing its instance variables directly.'
			difficulty: 4
			category: 'unknown-api') tags: #( 'unknown-api' 'navigation' 'collections' ); maxIterations: 26; yourself.
		(PharoCABenchmarkTask
			id: 'unknown-002-ledger-balance'
			title: 'Learn an unfamiliar multi-class ledger API'
			prompt: 'The PharoCodingAssistant-Benchmarks fixture code contains a benchmark-local ledger API with signed postings assigned to account keys. Inspect the live image and learn the public protocols of the ledger and the posting objects it returns. Create class PCABenchmarkLedgerAnalyzer in package PCABenchmark-Workspace with instance method balanceFor:in:. Answer the sum of signed postings for the supplied account key, or 0 when there are none. Do not access fixture instance variables directly or replace the fixture data structure.'
			difficulty: 4
			category: 'unknown-api') tags: #( 'unknown-api' 'navigation' 'multi-class' ); maxIterations: 28; yourself.
		(PharoCABenchmarkTask
			id: 'unknown-003-cheapest-direct-route'
			title: 'Learn an unfamiliar route-map API'
			prompt: 'The PharoCodingAssistant-Benchmarks fixture code contains a benchmark-local directed route-map API. A route map can expose outgoing leg objects, and each leg provides a destination and numeric cost through its own public protocol. Discover those APIs in the live image. Create class PCABenchmarkRouteAnalyzer in package PCABenchmark-Workspace with instance method cheapestDirectDestinationFrom:in:. Answer the destination of the cheapest direct outgoing leg from the supplied source node, or nil if there is no outgoing leg. Hidden cases do not contain equal-cost ties. Do not inspect fixture instance variables directly.'
			difficulty: 4
			category: 'unknown-api') tags: #( 'unknown-api' 'navigation' 'multi-class' ); maxIterations: 30; yourself.
		(PharoCABenchmarkTask
			id: 'unknown-004-job-board-priority'
			title: 'Learn an unfamiliar scheduling API'
			prompt: 'The benchmark fixtures contain a small job-board API and a separate ticket object API. Inspect the live image to discover how jobs are scheduled, queried by owner, and represented. Create class PCABenchmarkJobBoardAnalyzer in package PCABenchmark-Workspace with instance method highestPriorityTitleFor:in:. The first argument is an owner key and the second a fixture job board. Answer the title String of that owner''s ticket with the greatest numeric priority, or nil when that owner has no tickets. Hidden cases have no equal-priority ties. Use only the fixture public protocol, not instance-variable inspection.'
			difficulty: 4
			category: 'unknown-api') tags: #( 'unknown-api' 'navigation' 'multi-class' ); maxIterations: 30; yourself.
		(PharoCABenchmarkTask
			id: 'unknown-005-document-subtree-weight'
			title: 'Discover and recursively traverse an unfamiliar tree API'
			prompt: 'The benchmark fixtures contain a document-tree API whose tree can locate node objects and whose nodes expose their own public traversal protocol. Inspect those classes in the live image. Create class PCABenchmarkDocumentTreeAnalyzer in package PCABenchmark-Workspace with instance method subtreeWeightFor:in:. The first argument is a document key and the second the fixture tree. Answer the sum of that node''s numeric weight plus all descendant weights recursively. Answer nil when the requested document is absent. Do not access fixture instance variables or replace the fixture representation.'
			difficulty: 5
			category: 'unknown-api') tags: #( 'unknown-api' 'navigation' 'multi-class' 'recursion' ); maxIterations: 36; yourself
	}
]

{ #category : 'tasks - refactoring' }
PharoCABenchmarkCatalog class >> refactoringTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'refactoring-001-rename-selector'
			title: 'Rename an API and update its callers'
			prompt: 'The benchmark fixture classes PharoCABenchmarkLegacyNameFormatter and PharoCABenchmarkBadgePrinter use a legacy selector #formatName:. Refactor the fixture so the formatter instead defines #displayNameFor:, update every benchmark-fixture caller to use the new selector, and remove the old #formatName: method. Preserve behavior exactly. Do not add compatibility forwarding from the old selector. Verify the formatter and badge printer after the refactoring, then finish.'
			difficulty: 3
			category: 'refactoring')
			tags: #( 'refactoring' 'rename' 'senders' );
			maxIterations: 22;
			yourself.
		(PharoCABenchmarkTask
			id: 'refactoring-002-pull-up-method'
			title: 'Pull duplicated behavior into a superclass'
			prompt: 'In the benchmark fixtures, PharoCABenchmarkUserKeyNormalizer and PharoCABenchmarkProjectKeyNormalizer are subclasses of PharoCABenchmarkKeyNormalizer and currently define the same #normalizeKey: implementation. Refactor the hierarchy so #normalizeKey: is implemented once on PharoCABenchmarkKeyNormalizer and removed from both subclasses. Preserve behavior for both subclasses. Verify method ownership as well as behavior, then finish.'
			difficulty: 3
			category: 'refactoring')
			tags: #( 'refactoring' 'hierarchy' 'duplication' );
			maxIterations: 22;
			yourself
	}
]

{ #category : 'tasks - spec2' }
PharoCABenchmarkCatalog class >> spec2Tasks [
	^ {
		(PharoCABenchmarkTask
			id: 'spec2-001-counter-presenter'
			title: 'Build a simple Spec2 counter presenter'
			prompt: 'Create PCABenchmarkCounterPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must have a label showing the current integer count, initially 0, and a button labelled ''Increment''. Clicking the button increments the count and updates the existing label presenter. Provide accessors #count, #countLabel, and #incrementButton, and provide a normal Spec2 #defaultLayout containing the label and button. Use normal Spec2 lifecycle methods; do not manually invoke #initializePresenters or #connectPresenters. Verify it headlessly without opening a window, then finish.'
			difficulty: 3
			category: 'ui')
			tags: #( 'spec2' 'ui' 'presenters' );
			skillNames: #( 'Spec2' );
			maxIterations: 24;
			yourself.
		(PharoCABenchmarkTask
			id: 'spec2-002-greeting-presenter'
			title: 'Connect text input, button, and dynamic label'
			prompt: 'Create PCABenchmarkGreetingPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must contain a text input, an initially empty greeting label, and a button labelled ''Greet''. Clicking the button must change the existing label to ''Hello, '' followed by the current text input contents. Provide accessors #nameInput, #greetingLabel, and #greetButton, plus a normal #defaultLayout containing all three presenters. Use Spec2 presenter APIs and lifecycle normally; do not manually invoke lifecycle hooks. Verify it headlessly without opening a window, then finish.'
			difficulty: 3
			category: 'ui')
			tags: #( 'spec2' 'ui' 'text-input' );
			skillNames: #( 'Spec2' );
			maxIterations: 26;
			yourself.
		(PharoCABenchmarkTask
			id: 'spec2-003-todo-presenter'
			title: 'Maintain list state through Spec2 presenters'
			prompt: 'Create PCABenchmarkTodoPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must contain a text input, an Add button, and a list presenter. Clicking Add with non-empty input appends that exact String to the end of the list and clears the input. Clicking Add with empty input changes nothing. Provide accessors #itemInput, #addButton, and #itemsList, and a normal #defaultLayout containing the three presenters. Keep list state through presenter APIs rather than replacing the presenter object. Verify it headlessly without opening a window, then finish.'
			difficulty: 4
			category: 'ui')
			tags: #( 'spec2' 'ui' 'list' 'state' );
			skillNames: #( 'Spec2' );
			maxIterations: 30;
			yourself
	}
]

{ #category : 'tasks - navigation' }
PharoCABenchmarkCatalog class >> navigationTasks [
	^ {
		(PharoCABenchmarkTask
			id: 'navigation-001-codebook'
			title: 'Locate and repair a fixture method'
			prompt: 'In the PharoCodingAssistant-Benchmarks package there is a fixture object that maps #alpha and #beta to numeric secret codes through an instance method named secretCodeFor:. Locate the implementing class in the live image. Extend the existing behavior so #gamma maps to 30 while preserving all existing mappings and unknown-key behavior. Do not create a replacement class; modify the existing fixture and verify the result.'
			difficulty: 3
			category: 'navigation')
			tags: #( 'navigation' 'browsing' 'repair' );
			maxIterations: 20;
			yourself.
		(PharoCABenchmarkTask
			id: 'navigation-002-running-total'
			title: 'Find a behavioral bug in fixtures'
			prompt: 'A class in the PharoCodingAssistant-Benchmarks fixture code is intended to answer the arithmetic total of a collection of numbers, but #(2 3 4) currently produces 24 instead of 9. Locate the responsible existing class and method in the live image and repair the implementation without changing its public selector. Verify empty input as well as #(2 3 4), then finish.'
			difficulty: 3
			category: 'navigation')
			tags: #( 'navigation' 'debugging' 'repair' );
			maxIterations: 22;
			yourself.
		(PharoCABenchmarkTask
			id: 'navigation-003-invoice-tax-chain'
			title: 'Trace a defect through collaborating fixtures'
			prompt: 'In the PharoCodingAssistant-Benchmarks fixture API, sending #invoiceSummaryForAmount: with 100 currently answers 120, but the intended result is 110 because the fixture tax is 10%. Locate the implementor of #invoiceSummaryForAmount:, follow the collaborating code that actually determines the gross amount, and repair the underlying defect rather than hard-coding a special case in the public entry method. Preserve the public selector and verify at least 100 and 50, then finish.'
			difficulty: 3
			category: 'navigation')
			tags: #( 'navigation' 'debugging' 'call-chain' );
			maxIterations: 24;
			yourself.
		(PharoCABenchmarkTask
			id: 'navigation-004-discount-chain'
			title: 'Trace a pricing defect through three collaborators'
			prompt: 'A benchmark fixture understands #checkoutTotalFor:tier:. For amount 100 and tier #gold it currently answers 95, but the intended gold discount is 10%, so the result must be 90. Tier #standard must remain undiscounted. Locate the public implementor, trace the pricing collaborators to the policy that owns the rule, and repair the underlying policy rather than special-casing the public entry method. Preserve the existing call structure and selector.'
			difficulty: 4
			category: 'navigation') tags: #( 'navigation' 'debugging' 'call-chain' 'policy' ); maxIterations: 30; yourself.
		(PharoCABenchmarkTask
			id: 'navigation-005-locale-chain'
			title: 'Trace locale selection through a rendering chain'
			prompt: 'A benchmark fixture understands #welcomeFor:locale:. With name ''Ada'' and locale #de it currently answers ''Hello, Ada!'' but should answer ''Hallo, Ada!''. English must remain ''Hello, Ada!'' and French must become ''Bonjour, Ada!''. Find the public implementor, follow the renderer/catalog collaborators, and fix locale selection at the layer that owns translations. Do not hard-code names or patch only the public entry method.'
			difficulty: 4
			category: 'navigation') tags: #( 'navigation' 'debugging' 'call-chain' 'localization' ); maxIterations: 30; yourself.
		(PharoCABenchmarkTask
			id: 'navigation-006-configuration-precedence'
			title: 'Find a precedence bug behind a service API'
			prompt: 'In the benchmark fixtures, an object understands #settingNamed:. #theme currently answers #light but should answer the override #dark; #language should similarly answer #de, while #pageSize should still fall back to 20. Locate the entry method and follow its collaborator into the layered configuration logic. Repair precedence in the configuration layer, not by special-casing keys in the service.'
			difficulty: 4
			category: 'navigation') tags: #( 'navigation' 'debugging' 'configuration' 'precedence' ); maxIterations: 30; yourself.
		(PharoCABenchmarkTask
			id: 'navigation-007-cache-invalidation'
			title: 'Diagnose a stateful stale-cache defect'
			prompt: 'A stateful benchmark fixture understands #displayNameFor: and #renameUser:to:. On a fresh instance, evaluating displayNameFor: #u1 answers ''Ada''. After renameUser: #u1 to: ''Grace'', displayNameFor: #u1 incorrectly still answers ''Ada''. Locate the fixture from these selectors, inspect the repository/cache collaborators, and repair the update path so cached values are invalidated using the cache''s public protocol. Preserve caching for reads and do not bypass or replace the cache.'
			difficulty: 5
			category: 'navigation') tags: #( 'navigation' 'debugging' 'state' 'cache' 'multi-class' ); maxIterations: 36; yourself
	}
]

{ #category : 'tasks' }
PharoCABenchmarkCatalog class >> taskNamed: anId [
	^ self allTasks
		detect: [ :each | each id = anId asString ]
		ifNone: [ Error signal: 'Unknown benchmark task: ', anId asString ]
]

{ #category : 'accessing' }
PharoCABenchmarkCatalog class >> taskSetVersion [
	^ '004'
]
