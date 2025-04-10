//
//  RFC5321.swift
//  Codex
//
//  Created by Kevin Wooten on 4/4/25.
//

import Foundation

public enum RFC5321 {

  /// A structure representing an SMTP mailbox.
  public struct Mailbox: CustomStringConvertible {
    /// The local-part (before the "@").
    public var local: String
    /// The domain (after the "@"). If provided as a domain-literal, the brackets remain.
    public var domain: String

    /// Initializes a Mailbox instance.
    /// - Parameters:
    ///   - local: The local part of the mailbox.
    ///   - domain: The domain part of the mailbox.
    public init(local: String, domain: String) {
      self.local = local
      self.domain = domain
    }

    public var description: String {
      "\(local)@\(domain)"
    }

    /// Attempts to parse a mailbox string according to RFC 5321.
    ///
    /// RFC 5321 (and related RFCs) define a mailbox as:
    ///     mailbox = local-part "@" domain
    ///
    /// local-part can be a dot-string or a quoted-string.
    /// For dot-string, we allow one or more "atoms" separated by dots.
    /// Atoms are composed of allowed characters:
    ///     A–Z, a–z, 0–9 and these symbols: ! # $ % & ' * + - / = ? ^ _ ` { | } ~
    ///
    /// For a quoted-string, we allow any printable ASCII (with proper escaping of
    /// double quotes and backslashes).
    ///
    /// The domain is either a dot-string of labels (letters, digits, and hyphens,
    /// not starting or ending with a hyphen) or a domain-literal enclosed in [ and ].
    ///
    /// - Parameter string: The mailbox string to validate and parse.
    /// - Returns: A Mailbox instance if the input is valid; otherwise, nil.
    public static func parse(string: String) -> Mailbox? {

      // The following regex uses named capture groups "local" and "domain".
      let regex =
        #/^(?<local>(?:[A-Za-z0-9!#$%&'*+\-\/=?^_`{|}~]+(?:\.[A-Za-z0-9!#$%&'*+\-\/=?^_`{|}~]+)*|"(?:[^\x00-\x1F\x7F"\\]|\\["\\])*"))@(?<domain>(?:[A-Za-z0-9-.]+|\[.+\]))$/#

      guard let match = string.wholeMatch(of: regex) else {
        return nil
      }

      let local = String(match.output.local)
      let domain = String(match.output.domain)

      // Additional validation
      guard validate(local: local) && validate(domain: domain) else {
        return nil
      }

      return Mailbox(local: local, domain: domain)
    }

    public static func validate(local: String) -> Bool {

      // Check max length of local part
      guard local.count <= 64 else {
        return false
      }

      // Validate quoted strings
      if isQuotedString(local) {
        guard validate(quotedString: local) else {
          return false
        }
      }

      return true
    }

    public static func isQuotedString(_ string: String) -> Bool {
      string.hasPrefix("\"") && string.hasSuffix("\"")
    }

    public static func validate(quotedString: String) -> Bool {

      let content = quotedString.dropFirst().dropLast()

      // Check for valid escape sequences
      var i = content.startIndex
      while i < content.endIndex {
        if content[i] == "\\" {
          // Must have a character after the backslash
          let nextIndex = content.index(after: i)
          guard nextIndex < content.endIndex else {
            return false
          }

          // Only " and \ can be escaped
          let nextChar = content[nextIndex]
          guard ["\"", "\\"].contains(nextChar) else {
            return false
          }

          // Skip the escaped character
          i = nextIndex
        }
        i = content.index(after: i)
      }

      // Ensure we don't end with a single backslash
      if content.last == "\\" {
        return false
      }

      return true
    }

    public static func validate(domain: String) -> Bool {

      // If the domain is a literal, we need to validate the content
      if isDomainLiteral(domain) {
        guard validate(domainLiteral: domain) else {
          return false
        }
      }
      // Otherwise, validate as a hostname
      else {
        guard
          !domain.hasPrefix(".") && !domain.hasSuffix(".")
            && RFC1123.Hostname.parse(string: String(domain)) != nil
        else {
          return false
        }
      }
      return true
    }

    public static func isDomainLiteral(_ string: String) -> Bool {
      string.hasPrefix("[") && string.hasSuffix("]")
    }

    public static func validate(domainLiteral: String) -> Bool {
      let literalContent = String(domainLiteral.dropFirst().dropLast())
      return validateIPv4AddressLiteral(literalContent)
        || validateIPv6AddressLiteral(literalContent) || validateGeneralLiteral(literalContent)
    }

    public static func validateIPv4AddressLiteral(_ string: String) -> Bool {
      RFC2673.IPv4Address.parse(string: string) != nil
    }

    public static let ipv6LiteralPrefix = "IPv6:"

    public static func validateIPv6AddressLiteral(_ string: String) -> Bool {
      string.hasPrefix(Self.ipv6LiteralPrefix)
        && RFC4291.IPv6Address.parse(string: String(string.trimmingPrefix(Self.ipv6LiteralPrefix)))
          != nil
    }

    public static func validateGeneralLiteral(_ string: String) -> Bool {
      let parts = string.split(separator: ":", maxSplits: 2)
      guard parts.count == 2 else {
        return false
      }
      // Validate the label is a valid hostname
      let standardizedLabel = String(parts[0])
      guard RFC1123.Hostname.parse(string: standardizedLabel) != nil else {
        return false
      }
      // Validate the content
      let content = String(parts[1])
      guard content.wholeMatch(of: #/^[\x21-\x5A\x5E-\x7E]+$/#) != nil else {
        return false
      }
      return true
    }

  }
}
