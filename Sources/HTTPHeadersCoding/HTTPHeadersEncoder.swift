// Copyright 2018-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  HTTPHeadersEncoder.swift
//  HTTPHeadersCoding
//

import Foundation
import ShapeCoding

///
/// Encode Swift types into HTTP Headers.
///
/// Nested types, arrays and dictionaries are serialized into header keys using
/// key concatination
/// Array entries are indicated by a 1-based index
/// ie. HeadersInput(theArray: ["Value1", "Value2"]) --> ["theArray1": "Value1", "theArray2": "Value2"]
/// Dictionary entries are indicated by the attribute keys
/// ie. HeadersInput(theMap: [foo: "Value1", bar: "Value2"]) --> ["theMapfoo": "Value1", "theMapbar": "Value2"]
/// Nested type attributes are indicated by the attribute keys
/// ie. HeadersInput(theType: TheType(foo: "Value1", bar: "Value2")) --> ["theArrayfoo": "Value1", "theArraybar": "Value2"]
public class HTTPHeadersEncoder {
    public typealias KeyEncodingStrategy = ShapeKeyEncodingStrategy
    public typealias KeyEncodeTransformStrategy = ShapeKeyEncodeTransformStrategy

    internal let options: StandardEncodingOptions
    
    /// The strategy to use for encoding maps.
    public enum MapEncodingStrategy {
        /// The output will contain a single header for
        /// each entry of the map. This is the default.
        /// ie. HeadersInput(theMap: ["Key": "Value"]) --> ["theMap.Key": "Value"]
        /// Matches the decoding strategy `HTTPHeadersDecoder.MapEncodingStrategy.singleHeader`.
        case singleHeader

        /// The output will contain separate headers for the key and value
        /// of each entry of the map, specified as a list.
        /// ie. HeadersInput(theMap: ["Key": "Value"]) --> ["theMap.1.KeyTag": "Key", "theMap.1.ValueTag": "Value"]
        /// Matches the decoding strategy `HTTPHeadersDecoder.MapEncodingStrategy.separateHeadersWith`.
        case separateHeadersWith(keyTag: String, valueTag: String)
        
        var shapeMapEncodingStrategy: ShapeMapEncodingStrategy {
            switch self {
            case .singleHeader:
                return .singleShapeEntry
            case let .separateHeadersWith(keyTag: keyTag, valueTag: valueTag):
                return .separateShapeEntriesWith(keyTag: keyTag, valueTag: valueTag)
            }
        }
    }

    /**
     Initializer.
     
     - Parameters:
        - keyEncodingStrategy: the `KeyEncodingStrategy` to use for encoding.
                               By default uses `.useAsShapeSeparator("-")`.
        - mapEncodingStrategy: the `MapEncodingStrategy` to use for encoding.
                               By default uses `.singleHeader`.
        - KeyEncodeTransformStrategy: the `KeyEncodeTransformStrategy` to use for transforming keys.
                               By default uses `.none`.
     */
    public init(keyEncodingStrategy: KeyEncodingStrategy = .useAsShapeSeparator("-"),
                mapEncodingStrategy: MapEncodingStrategy = .singleHeader,
                keyEncodeTransformStrategy: KeyEncodeTransformStrategy = .none) {
        self.options = StandardEncodingOptions(
            shapeKeyEncodingStrategy: keyEncodingStrategy,
            shapeMapEncodingStrategy: mapEncodingStrategy.shapeMapEncodingStrategy,
            shapeListEncodingStrategy: .expandListWithIndex,
            shapeKeyEncodeTransformStrategy: keyEncodeTransformStrategy)
    }

    /**
     Encode the provided value.

     - Parameters:
        - value: The value to be encoded
        - allowedCharacterSet: The allowed character set for header values. If nil,
          all characters are allowed.
        - userInfo: The user info to use for this encoding.
     */
    public func encode<T: Swift.Encodable>(_ value: T,
                                           allowedCharacterSet: CharacterSet? = nil,
                                           userInfo: [CodingUserInfoKey: Any] = [:]) throws -> [(String, String?)] {
        let delegate = StandardShapeSingleValueEncodingContainerDelegate(options: options)
        let container = ShapeSingleValueEncodingContainer(
            userInfo: userInfo,
            codingPath: [],
            delegate: delegate,
            allowedCharacterSet: allowedCharacterSet,
            defaultValue: nil)
        try value.encode(to: container)

        var elements: [(String, String?)] = []
        try container.getSerializedElements(nil, isRoot: true, elements: &elements)
        
        // The headers need to be sorted into canonical form
        let sortedElements = elements.sorted { (left, right) in left.0.lowercased() < right.0.lowercased() }

        return sortedElements
    }
}
