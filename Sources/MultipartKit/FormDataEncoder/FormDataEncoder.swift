#if canImport(Foundation)
import Foundation
#endif

/// Encodes `Encodable` or `EncodableWithConfiguration` items to `multipart/form-data` encoded `Data`.
///
/// See [RFC#2388](https://tools.ietf.org/html/rfc2388) for more information about `multipart/form-data` encoding.
///
/// - Seealso: ``MultipartParser`` for more information about the `multipart` encoding.
public struct FormDataEncoder: Sendable {
    /// Any contextual information set by the user for encoding.
    public var userInfo: [CodingUserInfoKey: any Sendable] = [:]

    /// Creates a new `FormDataEncoder`.
    public init() {}

    /// Encodes an `Encodable` item to `String` using the supplied boundary.
    ///
    /// ```swift
    /// let a = Foo(string: "a", int: 42, double: 3.14, array: [1, 2, 3])
    /// let data = try FormDataEncoder().encode(a, boundary: "123")
    /// ```
    ///
    /// - parameters:
    ///     - encodable: Generic `Encodable` item.
    ///     - boundary: Multipart boundary to use for encoding. This must not appear anywhere in the encoded data.
    /// - throws: Any errors encoding the model with `Codable` or serializing the data.
    /// - returns: `multipart/form-data`-encoded `String`.
    public func encode<E: Encodable>(_ encodable: E, boundary: String) throws -> String {
        let parts: [MultipartPart<[UInt8]>] = try self.parts(from: encodable)
        let serialized = MultipartSerializer(boundary: boundary).serialize(parts: parts, into: [UInt8].self)
        return String(decoding: serialized, as: Unicode.UTF8.self)
    }
    
    #if canImport(Foundation)
    /// Encodes an `EncodableWithConfiguration` item to `String` using the supplied boundary.
    ///
    /// ```swift
    /// let a = Foo(string: "a", int: 42, double: 3.14, array: [1, 2, 3])
    /// let data = try FormDataEncoder().encode(a, configuration: Foo.EncodingConfiguration(flexibleDate: true), boundary: "123")
    /// ```
    ///
    /// - parameters:
    ///     - encodable: Generic `EncodableWithConfiguration` item.
    ///     - boundary: Multipart boundary to use for encoding. This must not appear anywhere in the encoded data.
    /// - throws: Any errors encoding the model with `EncodableWithConfiguration` or serializing the data.
    /// - returns: `multipart/form-data`-encoded `String`.
    @available(iOS 15, macOS 12, macCatalyst 15, tvOS 15, watchOS 8, visionOS 1, *)
    public func encode<E: EncodableWithConfiguration>(_ encodable: E, configuration: E.EncodingConfiguration, boundary: String) throws -> String {
        let parts: [MultipartPart<[UInt8]>] = try self.parts(from: encodable, configuration: configuration)
        let serialized = MultipartSerializer(boundary: boundary).serialize(parts: parts, into: [UInt8].self)
        return String(decoding: serialized, as: Unicode.UTF8.self)
    }
    #endif

    /// Encodes an `Encodable` item into some ``MultipartPartBodyElement`` using the supplied boundary.
    ///
    /// ```swift
    /// let a = Foo(string: "a", int: 42, double: 3.14, array: [1, 2, 3])
    /// var buffer = ByteBuffer()
    /// let data = try FormDataEncoder().encode(a, boundary: "123", into: &buffer)
    /// ```
    ///
    /// - parameters:
    ///     - encodable: Generic `EncodingConfiguration` item.
    ///     - configuration: The `EncodingConfiguration` used when encoding the item.
    ///     - boundary: Multipart boundary to use for encoding. This must not appear anywhere in the encoded data.
    ///     - to: Buffer to write to.
    /// - throws: Any errors encoding the model with `Codable` or serializing the data.
    public func encode<E: Encodable, Body: MultipartPartBodyElement>(
        _ encodable: E,
        boundary: String,
        to: Body.Type = Body.self
    ) throws -> Body {
        let parts: [MultipartPart<Body>] = try self.parts(from: encodable)
        return MultipartSerializer(boundary: boundary).serialize(parts: parts)
    }
    
    #if canImport(Foundation)
    /// Encodes an ``Foundation/EncodableWithConfiguration`` item into some ``MultipartPartBodyElement`` using the supplied boundary.
    ///
    /// ```swift
    /// let a = Foo(string: "a", int: 42, double: 3.14, array: [1, 2, 3])
    /// var buffer = ByteBuffer()
    /// let data = try FormDataEncoder().encode(a, configuration: Foo.EncodingConfiguration(flexibleDate: true), boundary: "123", into: &buffer)
    /// ```
    ///
    /// - parameters:
    ///     - encodable: Generic ``Foundation/EncodableWithConfiguration`` item.
    ///     - configuration: The `EncodingConfiguration` used when encoding the item.
    ///     - boundary: Multipart boundary to use for encoding. This must not appear anywhere in the encoded data.
    ///     - to: Buffer to write to.
    /// - throws: Any errors encoding the model with `Codable` or serializing the data.
    @available(iOS 15, macOS 12, macCatalyst 15, tvOS 15, watchOS 8, visionOS 1, *)
    public func encode<E: EncodableWithConfiguration, Body: MultipartPartBodyElement>(
        _ encodable: E,
        configuration: E.EncodingConfiguration,
        boundary: String,
        to: Body.Type = Body.self
    ) throws -> Body {
        let parts: [MultipartPart<Body>] = try self.parts(from: encodable, configuration: configuration)
        return MultipartSerializer(boundary: boundary).serialize(parts: parts)
    }
    #endif

    private func parts<E: Encodable, Body: MultipartPartBodyElement>(
        from encodable: E
    ) throws -> [MultipartPart<Body>] {
        let encoder = Encoder<Body>(codingPath: [], userInfo: userInfo)
        try encodable.encode(to: encoder)
        return encoder.storage.data?.namedParts() ?? []
    }
    
    #if canImport(Foundation)
    @available(iOS 15, macOS 12, macCatalyst 15, tvOS 15, watchOS 8, visionOS 1, *)
    private func parts<E: EncodableWithConfiguration, Body: MultipartPartBodyElement>(
        from encodable: E,
        configuration: E.EncodingConfiguration
    ) throws -> [MultipartPart<Body>] {
        let encoder = Encoder<Body>(codingPath: [], userInfo: userInfo)
        try encodable.encode(to: encoder, configuration: configuration)
        return encoder.storage.data?.namedParts() ?? []
    }
    #endif
}
