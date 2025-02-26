//
//  JSONTokenConverter.swift
//  Codex
//
//  Created by Kevin Wooten on 2/25/25.
//

protocol JSONTokenConverter {

  associatedtype ValueType: Hashable

  func convertScalar(_ value: JSONToken.Scalar) throws -> ValueType
  func convertArray(_ value: [ValueType]) throws -> ValueType
  func convertObject(_ value: [String: ValueType]) throws -> ValueType
  func convertNull() throws -> ValueType

}
