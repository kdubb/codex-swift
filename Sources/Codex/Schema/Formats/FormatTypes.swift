//
//  FormatTypes.swift
//  Codex
//
//  Created by Kevin Wooten on 2/9/25.
//

import Foundation
import BigDecimal
import ScreamURITemplate

public class FormatTypes: FormatTypeLocator, @unchecked Sendable {

  public enum Error: Swift.Error {
    case unknownFormat(String)
  }

  public private(set) var formats: [String: Schema.FormatType] = [:]
  private let lock = NSLock()

  public init() {
    // Register the draft 2020-12 formats
    register(format: FormatTypes.DateTimeType.instance)
    register(format: FormatTypes.DateType.instance)
    register(format: FormatTypes.TimeType.instance)
    register(format: FormatTypes.DurationType.instance)
    register(format: FormatTypes.EmailType.instance)
    register(format: FormatTypes.IdnEmailType.instance)
    register(format: FormatTypes.HostnameType.instance)
    register(format: FormatTypes.IdnHostnameType.instance)
    register(format: FormatTypes.Ipv4Type.instance)
    register(format: FormatTypes.Ipv6Type.instance)
    register(format: FormatTypes.URIType.instance)
    register(format: FormatTypes.URIReferenceType.instance)
    register(format: FormatTypes.IRIType.instance)
    register(format: FormatTypes.IRIReferenceType.instance)
    register(format: FormatTypes.UUIDType.instance)
    register(format: FormatTypes.URITemplateType.instance)
    register(format: FormatTypes.JSONPointerType.instance)
    register(format: FormatTypes.RelativeJSONPointerType.instance)
    register(format: FormatTypes.RegexType.instance)
  }

  public func locate(formatType id: String) throws -> Schema.FormatType {
    try lock.withLock {
      guard let format = formats[id] else {
        throw Error.unknownFormat(id)
      }
      return format
    }
  }

  public func register(format: Schema.FormatType) {
    lock.withLock {
      formats[format.identifier] = format
    }
  }

}

extension FormatTypes {

  public enum DateTimeType: Schema.FormatType {
    case instance

    public var identifier: String { "date-time" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC3339.DateTime.parse(string: string) != nil
    }
  }

  public enum DateType: Schema.FormatType {
    case instance

    public static let formatStyle = Foundation.Date.FormatStyle()
      .year(.padded(4))
      .month(.twoDigits)
      .day(.twoDigits)
      .locale(.init(identifier: "en_US"))

    public var identifier: String { "date" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC3339.FullDate.parse(string: string) != nil
    }
  }

  public enum TimeType: Schema.FormatType {
    case instance

    public static let formatStyle = Foundation.Date.FormatStyle()
      .hour(.twoDigits(amPM: .omitted))
      .minute(.twoDigits)
      .second(.twoDigits)
      .secondFraction(.fractional(9))
      .timeZone(.iso8601(.short))
      .locale(.init(identifier: "en_US"))

    public var identifier: String { "time" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC3339.FullTime.parse(string: string) != nil
    }
  }

  public enum DurationType: Schema.FormatType {
    case instance

    public var identifier: String { "duration" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let value) = value else {
        return false
      }
      return RFC3339.Duration.parse(string: value) != nil
    }
  }

  public enum EmailType: Schema.FormatType {
    case instance

    public var identifier: String { "email" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let value) = value else {
        return false
      }
      return RFC5321.Mailbox.parse(string: value) != nil
    }
  }

  public enum IdnEmailType: Schema.FormatType {
    case instance

    public var identifier: String { "idn-email" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let value) = value else {
        return false
      }
      return RFC6531.Mailbox.parse(string: value) != nil
    }
  }

  public enum HostnameType: Schema.FormatType {
    case instance

    public var identifier: String { "hostname" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC1123.Hostname.parse(string: string) != nil
    }
  }

  public enum IdnHostnameType: Schema.FormatType {
    case instance

    public var identifier: String { "idn-hostname" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC5890.IDNHostname.parse(string: string) != nil
    }
  }

  public enum Ipv4Type: Schema.FormatType {
    case instance

    public var identifier: String { "ipv4" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC2673.IPv4Address.parse(string: string) != nil
    }
  }

  public enum Ipv6Type: Schema.FormatType {
    case instance

    public var identifier: String { "ipv6" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RFC4291.IPv6Address.parse(string: string) != nil
    }
  }

  public enum URIType: Schema.FormatType {
    case instance

    public var identifier: String { "uri" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return URI(encoded: string, requirements: [.kinds(.uri)]) != nil
    }
  }

  public enum URIReferenceType: Schema.FormatType {
    case instance

    public var identifier: String { "uri" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return URI(encoded: string, requirements: [.kinds(.uriReference)]) != nil
    }
  }

  public enum IRIType: Schema.FormatType {
    case instance

    public var identifier: String { "uri" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      // TODO: Implement IRI validation
      return URI(encoded: string, requirements: [.kinds(.uri)]) != nil
    }
  }

  public enum IRIReferenceType: Schema.FormatType {
    case instance

    public var identifier: String { "uri" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      // TODO: Implement IRI Reference validation
      return URI(encoded: string, requirements: [.kinds(.uriReference)]) != nil
    }
  }

  public enum UUIDType: Schema.FormatType {
    case instance

    public var identifier: String { "uuid" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return UUID(uuidString: string) != nil
    }
  }

  public enum URITemplateType: Schema.FormatType {
    case instance

    public var identifier: String { "uri-template" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      do {
        _ = try URITemplate(string: string)
        return true
      } catch {
        return false
      }
    }
  }

  public enum JSONPointerType: Schema.FormatType {
    case instance

    public var identifier: String { "json-pointer" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return Pointer(encoded: string) != nil
    }
  }

  public enum RelativeJSONPointerType: Schema.FormatType {
    case instance

    public var identifier: String { "relative-json-pointer" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      return RelativePointer(encoded: string) != nil
    }
  }

  public enum RegexType: Schema.FormatType {
    case instance

    public var identifier: String { "regex" }

    public func validate(_ value: Value) -> Bool {
      guard case .string(let string) = value else {
        return false
      }
      do {
        _ = try Regex(string)
        return true
      } catch {
        return false
      }
    }
  }
}
