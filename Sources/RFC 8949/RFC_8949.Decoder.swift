extension RFC_8949 {

    /// Reads CBOR data items one after another from a byte buffer.
    ///
    /// Every item read is well-formed (section 3 and Appendix F) and valid in the generic sense of section 5.3:
    /// text strings are UTF-8, and no map repeats a key. Tag contents are not checked against what their tag
    /// requires.
    public struct Decoder: Sendable {

        /// The bytes being read.
        public let bytes: [UInt8]

        /// The offset of the next byte to read.
        public private(set) var position: Int

        /// How deep arrays, maps and tags may nest.
        public let maximumDepth: Int

        public init(_ bytes: [UInt8], position: Int = 0, maximumDepth: Int = 64) {
            precondition(position >= 0 && position <= bytes.count)
            self.bytes = bytes
            self.position = position
            self.maximumDepth = maximumDepth
        }

        /// Whether every byte has been read.
        public var isAtEnd: Bool { position == bytes.count }
    }
}

extension RFC_8949 {

    /// The one data item `bytes` holds, with nothing after it.
    public static func decode(_ bytes: [UInt8], maximumDepth: Int = 64) throws(RFC_8949.Error) -> Value {
        var decoder = Decoder(bytes, maximumDepth: maximumDepth)
        let value = try decoder.decode()
        guard decoder.isAtEnd else { throw .trailingBytes(at: decoder.position) }
        return value
    }
}

extension RFC_8949.Decoder {

    /// The next data item; `position` moves past it.
    ///
    /// When it throws, `position` is unchanged.
    public mutating func decode() throws(RFC_8949.Error) -> RFC_8949.Value {
        var cursor = position
        let value = try item(at: &cursor, depth: 0)
        position = cursor
        return value
    }
}

extension RFC_8949.Decoder {

    private enum Head {
        case definite(major: UInt8, argument: UInt64)
        case indefinite(major: UInt8)
        case stop
    }

    private func byte(at cursor: inout Int) throws(RFC_8949.Error) -> UInt8 {
        guard cursor < bytes.count else { throw .truncated(at: cursor) }
        defer { cursor += 1 }
        return bytes[cursor]
    }

    private func head(at cursor: inout Int) throws(RFC_8949.Error) -> Head {
        let start = cursor
        let initial = try byte(at: &cursor)
        let major = initial >> 5
        let info = initial & 0x1f
        switch info {
        case 0..<24:
            return .definite(major: major, argument: UInt64(info))
        case 24...27:
            let count = 1 << Int(info - 24)
            var argument: UInt64 = 0
            for _ in 0..<count {
                let next = try byte(at: &cursor)
                argument = argument << 8 | UInt64(next)
            }
            if major == 7, info == 24, argument < 32 {
                throw .invalidSimple(UInt8(argument), at: start)
            }
            return .definite(major: major, argument: argument)
        case 28...30:
            throw .reservedAdditionalInformation(Int(info), at: start)
        default:
            switch major {
            case 2, 3, 4, 5: return .indefinite(major: major)
            case 7: return .stop
            default: throw .unexpectedIndefinite(at: start)
            }
        }
    }

    private func length(_ argument: UInt64, at start: Int) throws(RFC_8949.Error) -> Int {
        guard argument <= UInt64(Int.max) else { throw .length(at: start) }
        return Int(argument)
    }

    private func content(_ count: Int, at cursor: inout Int) throws(RFC_8949.Error) -> ArraySlice<UInt8> {
        guard bytes.count - cursor >= count else { throw .truncated(at: bytes.count) }
        defer { cursor += count }
        return bytes[cursor..<(cursor + count)]
    }

    private func text(_ slice: ArraySlice<UInt8>, at start: Int) throws(RFC_8949.Error) -> String {
        guard let text = String(validating: slice, as: UTF8.self) else { throw .invalidUTF8(at: start) }
        return text
    }

    private func item(at cursor: inout Int, depth: Int) throws(RFC_8949.Error) -> RFC_8949.Value {
        let start = cursor
        switch try head(at: &cursor) {
        case .stop:
            throw .unexpectedIndefinite(at: start)

        case .indefinite(let major):
            switch major {
            case 2, 3:
                var joined: [UInt8] = []
                while true {
                    let chunkStart = cursor
                    let chunk = try head(at: &cursor)
                    if case .stop = chunk { break }
                    guard case .definite(let chunkMajor, let argument) = chunk, chunkMajor == major else {
                        throw .invalidChunk(at: chunkStart)
                    }
                    let count = try length(argument, at: chunkStart)
                    joined += try content(count, at: &cursor)
                }
                if major == 2 { return .bytes(joined) }
                return .text(try text(joined[...], at: start))

            case 4:
                guard depth < maximumDepth else { throw .depth(at: start) }
                var items: [RFC_8949.Value] = []
                while true {
                    if try isBreak(at: &cursor) { break }
                    items.append(try item(at: &cursor, depth: depth + 1))
                }
                return .array(items)

            default:
                guard depth < maximumDepth else { throw .depth(at: start) }
                var pairs: [RFC_8949.Pair] = []
                var keys: Set<RFC_8949.Value> = []
                while true {
                    if try isBreak(at: &cursor) { break }
                    let keyStart = cursor
                    let key = try item(at: &cursor, depth: depth + 1)
                    guard keys.insert(key).inserted else { throw .duplicateKey(at: keyStart) }
                    pairs.append(RFC_8949.Pair(key: key, value: try item(at: &cursor, depth: depth + 1)))
                }
                return .map(pairs)
            }

        case .definite(let major, let argument):
            switch major {
            case 0:
                return .unsigned(argument)
            case 1:
                return .negative(argument)
            case 2:
                return .bytes(Array(try content(try length(argument, at: start), at: &cursor)))
            case 3:
                return .text(try text(try content(try length(argument, at: start), at: &cursor), at: start))
            case 4:
                guard depth < maximumDepth else { throw .depth(at: start) }
                let count = try length(argument, at: start)
                guard count <= bytes.count - cursor else { throw .truncated(at: bytes.count) }
                var items: [RFC_8949.Value] = []
                items.reserveCapacity(count)
                for _ in 0..<count {
                    items.append(try item(at: &cursor, depth: depth + 1))
                }
                return .array(items)
            case 5:
                guard depth < maximumDepth else { throw .depth(at: start) }
                let count = try length(argument, at: start)
                guard count <= (bytes.count - cursor) / 2 else { throw .truncated(at: bytes.count) }
                var pairs: [RFC_8949.Pair] = []
                pairs.reserveCapacity(count)
                var keys: Set<RFC_8949.Value> = []
                for _ in 0..<count {
                    let keyStart = cursor
                    let key = try item(at: &cursor, depth: depth + 1)
                    guard keys.insert(key).inserted else { throw .duplicateKey(at: keyStart) }
                    pairs.append(RFC_8949.Pair(key: key, value: try item(at: &cursor, depth: depth + 1)))
                }
                return .map(pairs)
            case 6:
                guard depth < maximumDepth else { throw .depth(at: start) }
                return .tagged(argument, try item(at: &cursor, depth: depth + 1))
            default:
                let info = bytes[start] & 0x1f
                switch info {
                case 25: return .float(RFC_8949.Half.double(UInt16(argument)))
                case 26: return .float(Double(Float(bitPattern: UInt32(argument))))
                case 27: return .float(Double(bitPattern: argument))
                default:
                    switch argument {
                    case 20: return .bool(false)
                    case 21: return .bool(true)
                    case 22: return .null
                    case 23: return .undefined
                    default: return .simple(UInt8(argument))
                    }
                }
            }
        }
    }

    /// Whether the next byte is a break code, consuming it when it is.
    private func isBreak(at cursor: inout Int) throws(RFC_8949.Error) -> Bool {
        guard cursor < bytes.count else { throw .truncated(at: cursor) }
        guard bytes[cursor] == 0xff else { return false }
        cursor += 1
        return true
    }
}
