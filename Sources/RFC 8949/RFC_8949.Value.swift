extension RFC_8949 {

    /// One CBOR data item (section 3), with indefinite-length strings, arrays and maps already joined.
    ///
    /// Integers are kept in the two major types CBOR has for them, so the full range from -2^64 to 2^64 - 1 is
    /// exact. A map keeps its pairs in the order they were read or written.
    public indirect enum Value: Sendable {

        /// Major type 0: an unsigned integer.
        case unsigned(UInt64)

        /// Major type 1: the negative integer `-1 - n`.
        case negative(UInt64)

        /// Major type 2: a byte string.
        case bytes([UInt8])

        /// Major type 3: a text string.
        case text(String)

        /// Major type 4: an array.
        case array([Value])

        /// Major type 5: a map, its pairs in order.
        case map([Pair])

        /// Major type 6: a tag number and the item it tags.
        case tagged(UInt64, Value)

        /// Major type 7, values 20 and 21.
        case bool(Bool)

        /// Major type 7, value 22.
        case null

        /// Major type 7, value 23.
        case undefined

        /// Major type 7: any other simple value, 0 through 19 or 32 through 255.
        case simple(UInt8)

        /// Major type 7: a half-, single- or double-precision float, held as a `Double`, which all three convert
        /// to exactly.
        case float(Double)
    }
}

extension RFC_8949.Value {

    /// The integer `value`, in major type 0 or 1.
    public init(_ value: Int64) {
        self = value >= 0 ? .unsigned(UInt64(value)) : .negative(UInt64(-(value + 1)))
    }

    /// The integer, when it is one that fits in `Int64`.
    public var integer: Int64? {
        switch self {
        case .unsigned(let n): n <= UInt64(Int64.max) ? Int64(n) : nil
        case .negative(let n): n <= UInt64(Int64.max) ? -1 - Int64(n) : nil
        default: nil
        }
    }

    /// The bytes of a byte string.
    public var bytes: [UInt8]? {
        guard case .bytes(let bytes) = self else { return nil }
        return bytes
    }

    /// The text of a text string.
    public var text: String? {
        guard case .text(let text) = self else { return nil }
        return text
    }

    /// The items of an array.
    public var array: [RFC_8949.Value]? {
        guard case .array(let items) = self else { return nil }
        return items
    }

    /// The pairs of a map.
    public var map: [RFC_8949.Pair]? {
        guard case .map(let pairs) = self else { return nil }
        return pairs
    }

    /// The value of the first pair in a map whose key is `key`.
    public subscript(key: RFC_8949.Value) -> RFC_8949.Value? {
        map?.first { $0.key == key }?.value
    }
}

extension RFC_8949.Value: Equatable {

    /// Items are equal when they are the same kind with equal contents. Floats are equal when their bits are, so
    /// 0.0 and -0.0 differ and a NaN equals itself.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.unsigned(let a), .unsigned(let b)): a == b
        case (.negative(let a), .negative(let b)): a == b
        case (.bytes(let a), .bytes(let b)): a == b
        case (.text(let a), .text(let b)): a == b
        case (.array(let a), .array(let b)): a == b
        case (.map(let a), .map(let b)): a == b
        case (.tagged(let t, let a), .tagged(let u, let b)): t == u && a == b
        case (.bool(let a), .bool(let b)): a == b
        case (.null, .null), (.undefined, .undefined): true
        case (.simple(let a), .simple(let b)): a == b
        case (.float(let a), .float(let b)): a.bitPattern == b.bitPattern
        default: false
        }
    }
}

extension RFC_8949.Value: Hashable {

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .unsigned(let n): hasher.combine(0); hasher.combine(n)
        case .negative(let n): hasher.combine(1); hasher.combine(n)
        case .bytes(let b): hasher.combine(2); hasher.combine(b)
        case .text(let t): hasher.combine(3); hasher.combine(t)
        case .array(let items): hasher.combine(4); hasher.combine(items)
        case .map(let pairs): hasher.combine(5); hasher.combine(pairs)
        case .tagged(let tag, let item): hasher.combine(6); hasher.combine(tag); hasher.combine(item)
        case .bool(let b): hasher.combine(7); hasher.combine(b)
        case .null: hasher.combine(8)
        case .undefined: hasher.combine(9)
        case .simple(let s): hasher.combine(10); hasher.combine(s)
        case .float(let f): hasher.combine(11); hasher.combine(f.bitPattern)
        }
    }
}

extension RFC_8949.Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) { self.init(value) }
}

extension RFC_8949.Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .text(value) }
}

extension RFC_8949.Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension RFC_8949.Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .float(value) }
}

extension RFC_8949.Value: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RFC_8949.Value...) { self = .array(elements) }
}

extension RFC_8949.Value: ExpressibleByDictionaryLiteral {
    /// A map with the pairs in the order written.
    public init(dictionaryLiteral elements: (RFC_8949.Value, RFC_8949.Value)...) {
        self = .map(elements.map { RFC_8949.Pair(key: $0.0, value: $0.1) })
    }
}
