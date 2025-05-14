//
//  LocalDate.swift
//  SolidFoundation
//
//  Created by Kevin Wooten on 4/27/25.
//

import SolidCore


/// Date in the proleptic Gregorian calendar system.
///
public struct LocalDate {

  public static let epoch = LocalDate(storage: (year: 1970, month: 1, day: 1))
  public static let min = LocalDate(storage: (year: -999_999_999, month: 1, day: 1))
  public static let max = LocalDate(storage: (year: 999_999_999, month: 12, day: 31))

  internal typealias Storage = (year: Int32, month: UInt8, day: UInt8)

  internal var storage: Storage

  public var year: Int {
    get { Int(storage.year) }
  }

  public var month: Int {
    get { Int(storage.month) }
  }

  public var day: Int {
    get { Int(storage.day) }
  }

  internal init(storage: Storage) {
    self.storage = storage
  }

  internal init(valid: (year: Int, month: Int, day: Int)) {
    // swift-format-ignore: NeverUseForceTry
    try! self.init(
      year: valid.year,
      month: valid.month,
      day: valid.day
    )
  }

  public init(
    @Validated(.year) year: Int,
    @Validated(.monthOfYear) month: Int,
    @Validated(.dayOfMonth) day: Int
  ) throws {

    let year = try $year.get()
    let month = try $month.get()
    let day = try $day.get()

    // Validate the day is within the valid range for the month.
    let cal: GregorianCalendarSystem = .default
    let daysInMonth = cal.daysInMonth(year: year, month: month)
    try _day.assert(1...daysInMonth, "Invalid day for month '\(month)' of year '\(year)'")

    self.init(
      storage: (
        year: Int32(year),
        month: UInt8(month),
        day: UInt8(day)
      )
    )
  }

  public func with(
    @ValidatedOptional(.year) year: Int? = nil,
    @ValidatedOptional(.monthOfYear) month: Int? = nil,
    @ValidatedOptional(.dayOfMonth) day: Int? = nil,
  ) throws -> Self {
    return Self(
      storage: try (
        year: Int32($year.getOrElse(self.year)),
        month: UInt8($month.getOrElse(self.month)),
        day: UInt8($day.getOrElse(self.day))
      )
    )
  }

  public static func now(clock: some Clock = .system, in calendarSystem: CalendarSystem = .default) -> Self {
    return calendarSystem.components(from: clock.instant, in: clock.zone)
  }
}

extension LocalDate: Sendable {}
extension LocalDate: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(storage.year)
    hasher.combine(storage.month)
    hasher.combine(storage.day)
  }

}
extension LocalDate: Equatable {
  public static func == (lhs: LocalDate, rhs: LocalDate) -> Bool {
    return lhs.storage == rhs.storage
  }
}

extension LocalDate: Comparable {

  public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
    if lhs.year != rhs.year {
      return lhs.year < rhs.year
    }
    if lhs.month != rhs.month {
      return lhs.month < rhs.month
    }
    return lhs.day < rhs.day
  }
}

extension LocalDate: CustomStringConvertible {

  private static let yearFormatter = fixedWidthFormat(Int.self, width: 4)
  private static let monthFormatter = fixedWidthFormat(Int.self, width: 2)
  private static let dayFormatter = fixedWidthFormat(Int.self, width: 2)

  public var description: String {
    let yearField = year.formatted(Self.yearFormatter)
    let monthField = month.formatted(Self.monthFormatter)
    let dayField = day.formatted(Self.dayFormatter)
    return "\(yearField)-\(monthField)-\(dayField)"
  }

}

extension LocalDate: LinkedComponentContainer, ComponentBuildable {

  public static let links: [any ComponentLink<Self>] = [
    ComponentKeyPathLink(.year, to: \.year),
    ComponentKeyPathLink(.monthOfYear, to: \.month),
    ComponentKeyPathLink(.dayOfMonth, to: \.day),
  ]

  public init(components: some ComponentContainer) {

    if let date = components as? LocalDate {
      self = date
      return
    } else if let date = components as? DateTime {
      self = date.date
      return
    }

    self.init(
      storage: (
        Int32(components.value(for: .year)),
        UInt8(components.value(for: .monthOfYear)),
        UInt8(components.value(for: .dayOfMonth)),
      )
    )
  }

  public init(availableComponents components: some ComponentContainer) {

    if let date = components as? LocalDate {
      self = date
      return
    } else if let date = components as? DateTime {
      self = date.date
      return
    }

    self.init(
      storage: (
        Int32(components.valueIfPresent(for: .year) ?? 0),
        UInt8(components.valueIfPresent(for: .monthOfYear) ?? 1),
        UInt8(components.valueIfPresent(for: .dayOfMonth) ?? 1),
      )
    )
  }

}

// MARK: - Conversion Initializers

extension LocalDate {

  public init(_ dateTime: some DateTime) {
    self = dateTime.date
  }

  /// Initialize a local date from a year and an ordinal day of year.
  ///
  /// - Parameters:
  ///   - year: Proleptic year.
  ///   - ordinalDay: Ordinal day-of-year in range **1...365** (366
  ///   for leap years).
  /// - Throws: `Error.invalidComponentValue` if the
  ///   ordinal is outside the valid range for that year.
  public init(year: Int, ordinalDay: Int) throws {
    self = try GregorianCalendarSystem.default.localDate(year: year, ordinalDay: ordinalDay)
  }

}

extension LocalDate {

  private nonisolated(unsafe) static let parseRegex =
    /^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$/
    .asciiOnlyDigits()

  /// Parses a date string (`YYYY-MM-DD`) per RFC-3339.
  ///
  /// - Parameter string: The full-date string.
  /// - Returns: Parsed date instance if valid; otherwise, nil.
  ///
  public static func parse(string: String) -> Self? {
    let cal: GregorianCalendarSystem = .default

    guard let match = string.wholeMatch(of: parseRegex) else {
      return nil
    }

    guard
      let year = Int(match.output.year),
      let month = Int(match.output.month),
      let day = Int(match.output.day),
      let date = try? Self(year: year, month: month, day: day)
    else {
      return nil
    }

    let daysInMonth: Int = cal.daysInMonth(year: year, month: month)
    guard (1...daysInMonth).contains(day) else {
      return nil
    }

    return date
  }

}
