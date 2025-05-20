//
//  RegionZoneRulesTests.swift
//  SolidFoundation
//
//  Created by Kevin Wooten on 5/19/25.
//

@testable import SolidTempo
import SolidTesting
import Testing


@Suite("RegionZoneRules Tests")
struct RegionZoneRulesTests {

  static let details = RegionZoneRulesDetails.loadFromBundle(name: "region-details", bundle: .module)

  @Test(
    "standard offset",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantStandardOffset) }
  )
  func testStandardOffset(zone: Zone, instant: Instant, expectedStandardOffset: ZoneOffset) throws {
    let standardOffset = zone.rules.standardOffset(at: instant)
    #expect(standardOffset == expectedStandardOffset)
  }

  @Test(
    "dst duration",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantDstDuration[.totalSeconds]) }
  )
  func testDstDuration(zone: Zone, instant: Instant, expectedDstDurationSeconds: Int) throws {
    let dstDuration = zone.rules.daylightSavingsTime(at: instant)
    let expectedDstDuration: Duration = .seconds(expectedDstDurationSeconds)
    #expect(dstDuration == expectedDstDuration)
  }

  @Test(
    "dst flag",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantDstFlag) }
  )
  func testDstFlag(zone: Zone, instant: Instant, expectedDstFlag: Bool) throws {
    let dstFlag = zone.rules.isDaylightSavingsTime(at: instant)
    #expect(dstFlag == expectedDstFlag)
  }

  @Test(
    "offset at instant",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantOffset) }
  )
  func testOffset(zone: Zone, instant: Instant, expectedOffset: ZoneOffset) throws {
    let offset = zone.rules.offset(at: instant)
    #expect(offset == expectedOffset)
  }

  @Test(
    "offset for local",
    arguments: details.flattened.map { ($0.zone, $0.entry.local, $0.entry.localOffset) }
  )
  func testOffsetForLocal(zone: Zone, local: LocalDateTime, expectedOffset: ZoneOffset) throws {
    let offset = zone.rules.offset(for: local)
    #expect(offset == expectedOffset)
  }

  @Test(
    "valid offsets",
    arguments: details.flattened.map { ($0.zone, $0.entry.local, $0.entry.localValidOffsets) }
  )
  func testValidOffsets(zone: Zone, local: LocalDateTime, expectedValidOffsets: [ZoneOffset]) throws {
    let validOffsets = Array(zone.rules.validOffsets(for: local))
    #expect(validOffsets == expectedValidOffsets)
  }

  @Test(
    "applicable transition",
    arguments: details.flattened.map { ($0.zone, $0.entry.local, $0.entry.localApplicableTransition) }
  )
  func testApplicableTransition(
    zone: Zone,
    local: LocalDateTime,
    expectedTransition: RegionZoneRulesDetails.ZoneDetails.Entry.Transition?
  ) throws {
    let foundTransition = zone.rules.applicableTransition(for: local)
    guard let expectedTransition else {
      #expect(foundTransition == nil)
      return
    }

    let transition = try #require(foundTransition)
    #expect(transition.instant == expectedTransition.instant)
    #expect(transition.before.local == expectedTransition.localBefore)
    #expect(transition.after.local == expectedTransition.localAfter)
    #expect(transition.before.offset == expectedTransition.offsetBefore)
    #expect(transition.after.offset == expectedTransition.offsetAfter)
    #expect(transition.kind == (expectedTransition.isGap ? .gap : .overlap))
    #expect(transition.duration == expectedTransition.duration)
  }

  @Test(
    "next transition",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantNextTransition) }
  )
  func testNextTransition(
    zone: Zone,
    instant: Instant,
    expectedTransition: RegionZoneRulesDetails.ZoneDetails.Entry.Transition?
  ) throws {
    let nextTransition = zone.rules.nextTransition(after: instant)
    guard let expectedTransition else {
      #expect(nextTransition == nil)
      return
    }

    let transition = try #require(nextTransition)
    #expect(transition.instant == expectedTransition.instant)
    #expect(transition.before.local == expectedTransition.localBefore)
    #expect(transition.after.local == expectedTransition.localAfter)
    #expect(transition.before.offset == expectedTransition.offsetBefore)
    #expect(transition.after.offset == expectedTransition.offsetAfter)
    #expect(transition.kind == (expectedTransition.isGap ? .gap : .overlap))
    #expect(transition.duration == expectedTransition.duration)
  }

  @Test(
    "prior transition",
    arguments: details.flattened.map { ($0.zone, $0.entry.instant, $0.entry.instantPriorTransition) }
  )
  func testPriorTransition(
    zone: Zone,
    instant: Instant,
    expectedTransition: RegionZoneRulesDetails.ZoneDetails.Entry.Transition?
  ) throws {
    let priorTransition = zone.rules.priorTransition(before: instant)
    guard let expectedTransition else {
      #expect(priorTransition == nil)
      return
    }

    let transition = try #require(priorTransition)
    #expect(transition.instant == expectedTransition.instant)
    #expect(transition.before.local == expectedTransition.localBefore)
    #expect(transition.after.local == expectedTransition.localAfter)
    #expect(transition.before.offset == expectedTransition.offsetBefore)
    #expect(transition.after.offset == expectedTransition.offsetAfter)
    #expect(transition.kind == (expectedTransition.isGap ? .gap : .overlap))
    #expect(transition.duration == expectedTransition.duration)
  }

  @Test(
    "designation",
    arguments: details.flattened
      .filter { $0.entry.local.year >= 1970 }
      .filter { $0.zone.identifier != "Europe/Kyiv" || $0.entry.local.year >= 1989 }
      .map { ($0.zone, $0.entry.instant, $0.entry.instantOffset, $0.entry.designation) }
  )
  func testDesignation(zone: Zone, instant: Instant, instantOffset: ZoneOffset, expectedDesignation: String) throws {
    let designation = zone.rules.designation(for: instant)
    let expected =
      if designation.wholeMatch(of: /^(\+|\-)\d+$/) != nil {
        instantOffset.designation
      } else {
        expectedDesignation
      }
    #expect(designation == expected)
  }

}

struct RegionZoneRulesDetails: TestData, Decodable {

  struct ZoneDetails: Codable {

    struct Entry: Codable {

      struct Transition: Codable {
        let instant: Instant
        let localBefore: LocalDateTime
        let localAfter: LocalDateTime
        let offsetBefore: ZoneOffset
        let offsetAfter: ZoneOffset
        let isGap: Bool
        let duration: Duration
      }

      let instant: Instant
      let local: LocalDateTime
      let instantStandardOffset: ZoneOffset
      let instantDstDuration: Duration
      let instantDstFlag: Bool
      let instantOffset: ZoneOffset
      let localOffset: ZoneOffset
      let localValidOffsets: [ZoneOffset]
      let localApplicableTransition: Transition?
      let instantNextTransition: Transition?
      let instantPriorTransition: Transition?
      let designation: String
    }

    let zone: Zone
    let entries: [Entry]
  }

  let zones: [ZoneDetails]

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.zones = try container.decode([ZoneDetails].self)
  }

  var flattened: [(zone: Zone, entry: ZoneDetails.Entry)] {
    return zones.flatMap { zone in zone.entries.map { (zone.zone, $0) } }
  }
}
