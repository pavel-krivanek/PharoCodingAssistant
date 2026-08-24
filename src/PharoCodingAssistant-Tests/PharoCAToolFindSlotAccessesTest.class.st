Class { #name : 'PharoCAToolFindSlotAccessesTest', #superclass : 'PharoCAToolTestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }
{ #category : 'tests' }
PharoCAToolFindSlotAccessesTest >> testSeparatesReadsAndWrites [
 | reads writes | reads:=PharoCAToolFindSlotAccesses execute:{'className'->'PharoCATestSearchFixture'.'slotName'->'probeValue'.'access'->'read'} asDictionary. writes:=PharoCAToolFindSlotAccesses execute:{'className'->'PharoCATestSearchFixture'.'slotName'->'probeValue'.'access'->'write'} asDictionary.
 self assert:((reads at:'methods') anySatisfy:[:e|(e at:'selector')='readProbeValue']). self assert:((writes at:'methods') anySatisfy:[:e|(e at:'selector')='writeProbeValue:']) ]
{ #category : 'tests' }
PharoCAToolFindSlotAccessesTest >> testMissingClassSlotAndInvalidAccessAreRejected [
 self should:[PharoCAToolFindSlotAccesses execute:{'className'->'PharoCATestSearchFixture'.'slotName'->'missing'} asDictionary] raise:Error.
 self deny:((PharoCAToolRegistry default executeNamed:'find_slot_accesses' arguments:{'className'->'PharoCATestSearchFixture'.'slotName'->'probeValue'.'access'->'bogus'} asDictionary) at:'ok') ]
