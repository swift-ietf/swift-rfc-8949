extension RFC_8949 {

    /// How an item is written.
    public enum Serialization: Sendable, Hashable {

        /// Preferred serialization (section 4.1): every argument in its shortest head, every float in the shortest
        /// of half, single and double precision that keeps its value, NaN as 0xf97e00, and everything of definite
        /// length. Map pairs keep their order.
        case preferred

        /// Core deterministic encoding (section 4.2.1): preferred serialization, with every map's pairs sorted by
        /// the bytewise lexicographic order of their keys' encodings.
        case deterministic
    }
}

extension RFC_8949 {

    /// The encoding of `value`.
    public static func encode(_ value: Value, serialization: Serialization = .preferred) -> [UInt8] {
        var bytes: [UInt8] = []
        append(value, to: &bytes, serialization: serialization)
        return bytes
    }

    /// Appends the encoding of `value` to `bytes`.
    public static func append(_ value: Value, to bytes: inout [UInt8], serialization: Serialization = .preferred) {
        switch value {
        case .unsigned(let n):
            head(major: 0, argument: n, to: &bytes)
        case .negative(let n):
            head(major: 1, argument: n, to: &bytes)
        case .bytes(let content):
            head(major: 2, argument: UInt64(content.count), to: &bytes)
            bytes += content
        case .text(let text):
            let content = Array(text.utf8)
            head(major: 3, argument: UInt64(content.count), to: &bytes)
            bytes += content
        case .array(let items):
            head(major: 4, argument: UInt64(items.count), to: &bytes)
            for item in items {
                append(item, to: &bytes, serialization: serialization)
            }
        case .map(let pairs):
            head(major: 5, argument: UInt64(pairs.count), to: &bytes)
            switch serialization {
            case .preferred:
                for pair in pairs {
                    append(pair.key, to: &bytes, serialization: serialization)
                    append(pair.value, to: &bytes, serialization: serialization)
                }
            case .deterministic:
                let encoded = pairs.map { pair in
                    (key: encode(pair.key, serialization: serialization), value: pair.value)
                }
                for pair in encoded.sorted(by: { $0.key.lexicographicallyPrecedes($1.key) }) {
                    bytes += pair.key
                    append(pair.value, to: &bytes, serialization: serialization)
                }
            }
        case .tagged(let tag, let item):
            head(major: 6, argument: tag, to: &bytes)
            append(item, to: &bytes, serialization: serialization)
        case .bool(let flag):
            bytes.append(flag ? 0xf5 : 0xf4)
        case .null:
            bytes.append(0xf6)
        case .undefined:
            bytes.append(0xf7)
        case .simple(let simple):
            if simple < 24 {
                bytes.append(0xe0 | simple)
            } else {
                bytes += [0xf8, simple]
            }
        case .float(let number):
            float(number, to: &bytes)
        }
    }

    private static func head(major: UInt8, argument: UInt64, to bytes: inout [UInt8]) {
        let type = major << 5
        switch argument {
        case 0..<24:
            bytes.append(type | UInt8(argument))
        case 24...0xff:
            bytes += [type | 24, UInt8(argument)]
        case 0x100...0xffff:
            bytes.append(type | 25)
            bigEndian(argument, count: 2, to: &bytes)
        case 0x1_0000...0xffff_ffff:
            bytes.append(type | 26)
            bigEndian(argument, count: 4, to: &bytes)
        default:
            bytes.append(type | 27)
            bigEndian(argument, count: 8, to: &bytes)
        }
    }

    private static func bigEndian(_ value: UInt64, count: Int, to bytes: inout [UInt8]) {
        for index in (0..<count).reversed() {
            bytes.append(UInt8(truncatingIfNeeded: value >> (8 * UInt64(index))))
        }
    }

    private static func float(_ number: Double, to bytes: inout [UInt8]) {
        if number.isNaN {
            bytes += [0xf9, 0x7e, 0x00]
        } else if let half = Half.bits(number) {
            bytes.append(0xf9)
            bigEndian(UInt64(half), count: 2, to: &bytes)
        } else if Double(Float(number)).bitPattern == number.bitPattern {
            bytes.append(0xfa)
            bigEndian(UInt64(Float(number).bitPattern), count: 4, to: &bytes)
        } else {
            bytes.append(0xfb)
            bigEndian(number.bitPattern, count: 8, to: &bytes)
        }
    }
}
