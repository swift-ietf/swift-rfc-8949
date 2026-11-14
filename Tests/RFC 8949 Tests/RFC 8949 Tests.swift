import RFC_8949
import Testing

@Suite
struct `RFC 8949 Tests` {

    struct Vector: Sendable, CustomTestStringConvertible {
        let hex: String
        /// `nil` for a NaN, which is checked with `isNaN`.
        let expected: RFC_8949.Value?
        let roundtrip: Bool

        var testDescription: String { hex }
    }

    /// Appendix A, as published in the machine-readable form at github.com/cbor/test-vectors, less 0xf818
    /// (simple(24)): that file follows RFC 7049, and RFC 8949 section 3.3 makes the item not well-formed.
    static let appendixA: [Vector] = [
        Vector(hex: "00", expected: .unsigned(0), roundtrip: true),
        Vector(hex: "01", expected: .unsigned(1), roundtrip: true),
        Vector(hex: "0a", expected: .unsigned(10), roundtrip: true),
        Vector(hex: "17", expected: .unsigned(23), roundtrip: true),
        Vector(hex: "1818", expected: .unsigned(24), roundtrip: true),
        Vector(hex: "1819", expected: .unsigned(25), roundtrip: true),
        Vector(hex: "1864", expected: .unsigned(100), roundtrip: true),
        Vector(hex: "1903e8", expected: .unsigned(1000), roundtrip: true),
        Vector(hex: "1a000f4240", expected: .unsigned(1_000_000), roundtrip: true),
        Vector(hex: "1b000000e8d4a51000", expected: .unsigned(1_000_000_000_000), roundtrip: true),
        Vector(hex: "1bffffffffffffffff", expected: .unsigned(18_446_744_073_709_551_615), roundtrip: true),
        Vector(hex: "c249010000000000000000", expected: .tagged(2, .bytes([0x01, 0, 0, 0, 0, 0, 0, 0, 0])), roundtrip: true),
        Vector(hex: "3bffffffffffffffff", expected: .negative(18_446_744_073_709_551_615), roundtrip: true),
        Vector(hex: "c349010000000000000000", expected: .tagged(3, .bytes([0x01, 0, 0, 0, 0, 0, 0, 0, 0])), roundtrip: true),
        Vector(hex: "20", expected: .negative(0), roundtrip: true),
        Vector(hex: "29", expected: .negative(9), roundtrip: true),
        Vector(hex: "3863", expected: .negative(99), roundtrip: true),
        Vector(hex: "3903e7", expected: .negative(999), roundtrip: true),
        Vector(hex: "f90000", expected: .float(0.0), roundtrip: true),
        Vector(hex: "f98000", expected: .float(-0.0), roundtrip: true),
        Vector(hex: "f93c00", expected: .float(1.0), roundtrip: true),
        Vector(hex: "fb3ff199999999999a", expected: .float(1.1), roundtrip: true),
        Vector(hex: "f93e00", expected: .float(1.5), roundtrip: true),
        Vector(hex: "f97bff", expected: .float(65504.0), roundtrip: true),
        Vector(hex: "fa47c35000", expected: .float(100000.0), roundtrip: true),
        Vector(hex: "fa7f7fffff", expected: .float(3.4028234663852886e+38), roundtrip: true),
        Vector(hex: "fb7e37e43c8800759c", expected: .float(1e+300), roundtrip: true),
        Vector(hex: "f90001", expected: .float(5.960464477539063e-08), roundtrip: true),
        Vector(hex: "f90400", expected: .float(6.103515625e-05), roundtrip: true),
        Vector(hex: "f9c400", expected: .float(-4.0), roundtrip: true),
        Vector(hex: "fbc010666666666666", expected: .float(-4.1), roundtrip: true),
        Vector(hex: "f97c00", expected: .float(.infinity), roundtrip: true),
        Vector(hex: "f97e00", expected: nil, roundtrip: true),
        Vector(hex: "f9fc00", expected: .float(-.infinity), roundtrip: true),
        Vector(hex: "fa7f800000", expected: .float(.infinity), roundtrip: false),
        Vector(hex: "fa7fc00000", expected: nil, roundtrip: false),
        Vector(hex: "faff800000", expected: .float(-.infinity), roundtrip: false),
        Vector(hex: "fb7ff0000000000000", expected: .float(.infinity), roundtrip: false),
        Vector(hex: "fb7ff8000000000000", expected: nil, roundtrip: false),
        Vector(hex: "fbfff0000000000000", expected: .float(-.infinity), roundtrip: false),
        Vector(hex: "f4", expected: .bool(false), roundtrip: true),
        Vector(hex: "f5", expected: .bool(true), roundtrip: true),
        Vector(hex: "f6", expected: .null, roundtrip: true),
        Vector(hex: "f7", expected: .undefined, roundtrip: true),
        Vector(hex: "f0", expected: .simple(16), roundtrip: true),
        Vector(hex: "f8ff", expected: .simple(255), roundtrip: true),
        Vector(hex: "c074323031332d30332d32315432303a30343a30305a", expected: .tagged(0, .text("2013-03-21T20:04:00Z")), roundtrip: true),
        Vector(hex: "c11a514b67b0", expected: .tagged(1, .unsigned(1_363_896_240)), roundtrip: true),
        Vector(hex: "c1fb41d452d9ec200000", expected: .tagged(1, .float(1363896240.5)), roundtrip: true),
        Vector(hex: "d74401020304", expected: .tagged(23, .bytes([0x01, 0x02, 0x03, 0x04])), roundtrip: true),
        Vector(hex: "d818456449455446", expected: .tagged(24, .bytes([0x64, 0x49, 0x45, 0x54, 0x46])), roundtrip: true),
        Vector(hex: "d82076687474703a2f2f7777772e6578616d706c652e636f6d", expected: .tagged(32, .text("http://www.example.com")), roundtrip: true),
        Vector(hex: "40", expected: .bytes([]), roundtrip: true),
        Vector(hex: "4401020304", expected: .bytes([0x01, 0x02, 0x03, 0x04]), roundtrip: true),
        Vector(hex: "60", expected: .text(""), roundtrip: true),
        Vector(hex: "6161", expected: .text("a"), roundtrip: true),
        Vector(hex: "6449455446", expected: .text("IETF"), roundtrip: true),
        Vector(hex: "62225c", expected: .text("\"\\"), roundtrip: true),
        Vector(hex: "62c3bc", expected: .text("\u{fc}"), roundtrip: true),
        Vector(hex: "63e6b0b4", expected: .text("\u{6c34}"), roundtrip: true),
        Vector(hex: "64f0908591", expected: .text("\u{10151}"), roundtrip: true),
        Vector(hex: "80", expected: .array([]), roundtrip: true),
        Vector(hex: "83010203", expected: .array([.unsigned(1), .unsigned(2), .unsigned(3)]), roundtrip: true),
        Vector(hex: "8301820203820405", expected: .array([.unsigned(1), .array([.unsigned(2), .unsigned(3)]), .array([.unsigned(4), .unsigned(5)])]), roundtrip: true),
        Vector(
            hex: "98190102030405060708090a0b0c0d0e0f101112131415161718181819",
            expected: .array([
                .unsigned(1), .unsigned(2), .unsigned(3), .unsigned(4), .unsigned(5), .unsigned(6), .unsigned(7), .unsigned(8), .unsigned(9), .unsigned(10), .unsigned(11), .unsigned(12),
                .unsigned(13), .unsigned(14), .unsigned(15), .unsigned(16), .unsigned(17), .unsigned(18), .unsigned(19), .unsigned(20), .unsigned(21), .unsigned(22), .unsigned(23), .unsigned(24),
                .unsigned(25),
            ]),
            roundtrip: true
        ),
        Vector(hex: "a0", expected: .map([]), roundtrip: true),
        Vector(hex: "a201020304", expected: .map([.init(key: .unsigned(1), value: .unsigned(2)), .init(key: .unsigned(3), value: .unsigned(4))]), roundtrip: true),
        Vector(hex: "a26161016162820203", expected: .map([.init(key: .text("a"), value: .unsigned(1)), .init(key: .text("b"), value: .array([.unsigned(2), .unsigned(3)]))]), roundtrip: true),
        Vector(hex: "826161a161626163", expected: .array([.text("a"), .map([.init(key: .text("b"), value: .text("c"))])]), roundtrip: true),
        Vector(
            hex: "a56161614161626142616361436164614461656145",
            expected: .map([
                .init(key: .text("a"), value: .text("A")), .init(key: .text("b"), value: .text("B")), .init(key: .text("c"), value: .text("C")), .init(key: .text("d"), value: .text("D")),
                .init(key: .text("e"), value: .text("E")),
            ]),
            roundtrip: true
        ),
        Vector(hex: "5f42010243030405ff", expected: .bytes([0x01, 0x02, 0x03, 0x04, 0x05]), roundtrip: false),
        Vector(hex: "7f657374726561646d696e67ff", expected: .text("streaming"), roundtrip: false),
        Vector(hex: "9fff", expected: .array([]), roundtrip: false),
        Vector(hex: "9f018202039f0405ffff", expected: .array([.unsigned(1), .array([.unsigned(2), .unsigned(3)]), .array([.unsigned(4), .unsigned(5)])]), roundtrip: false),
        Vector(hex: "9f01820203820405ff", expected: .array([.unsigned(1), .array([.unsigned(2), .unsigned(3)]), .array([.unsigned(4), .unsigned(5)])]), roundtrip: false),
        Vector(hex: "83018202039f0405ff", expected: .array([.unsigned(1), .array([.unsigned(2), .unsigned(3)]), .array([.unsigned(4), .unsigned(5)])]), roundtrip: false),
        Vector(hex: "83019f0203ff820405", expected: .array([.unsigned(1), .array([.unsigned(2), .unsigned(3)]), .array([.unsigned(4), .unsigned(5)])]), roundtrip: false),
        Vector(
            hex: "9f0102030405060708090a0b0c0d0e0f101112131415161718181819ff",
            expected: .array([
                .unsigned(1), .unsigned(2), .unsigned(3), .unsigned(4), .unsigned(5), .unsigned(6), .unsigned(7), .unsigned(8), .unsigned(9), .unsigned(10), .unsigned(11), .unsigned(12),
                .unsigned(13), .unsigned(14), .unsigned(15), .unsigned(16), .unsigned(17), .unsigned(18), .unsigned(19), .unsigned(20), .unsigned(21), .unsigned(22), .unsigned(23), .unsigned(24),
                .unsigned(25),
            ]),
            roundtrip: false
        ),
        Vector(hex: "bf61610161629f0203ffff", expected: .map([.init(key: .text("a"), value: .unsigned(1)), .init(key: .text("b"), value: .array([.unsigned(2), .unsigned(3)]))]), roundtrip: false),
        Vector(hex: "826161bf61626163ff", expected: .array([.text("a"), .map([.init(key: .text("b"), value: .text("c"))])]), roundtrip: false),
        Vector(hex: "bf6346756ef563416d7421ff", expected: .map([.init(key: .text("Fun"), value: .bool(true)), .init(key: .text("Amt"), value: .negative(1))]), roundtrip: false),
    ]

    @Test(arguments: appendixA)
    func `Appendix A decodes`(_ vector: Vector) throws {
        let value = try RFC_8949.decode(hex(vector.hex))
        if let expected = vector.expected {
            #expect(value == expected)
        } else {
            guard case .float(let number) = value else {
                Issue.record("not a float: \(value)")
                return
            }
            #expect(number.isNaN)
        }
    }

    @Test(arguments: appendixA.filter(\.roundtrip))
    func `Appendix A encodes in preferred serialization`(_ vector: Vector) {
        let value = vector.expected ?? .float(.nan)
        #expect(RFC_8949.encode(value) == hex(vector.hex))
    }

    @Test(arguments: [
        ("18", RFC_8949.Error.truncated(at: 1)),
        ("1901", .truncated(at: 2)),
        ("44010203", .truncated(at: 4)),
        ("8301", .truncated(at: 2)),
        ("1c", .reservedAdditionalInformation(28, at: 0)),
        ("5d", .reservedAdditionalInformation(29, at: 0)),
        ("1f", .unexpectedIndefinite(at: 0)),
        ("3f", .unexpectedIndefinite(at: 0)),
        ("df00", .unexpectedIndefinite(at: 0)),
        ("ff", .unexpectedIndefinite(at: 0)),
        ("8100ff", .trailingBytes(at: 2)),
        ("5f00ff", .invalidChunk(at: 1)),
        ("5f6100ff", .invalidChunk(at: 1)),
        ("5f5f4000ffff", .invalidChunk(at: 1)),
        ("f800", .invalidSimple(0, at: 0)),
        ("f81f", .invalidSimple(31, at: 0)),
        ("f818", .invalidSimple(24, at: 0)),
        ("62c328", .invalidUTF8(at: 0)),
        ("a201020103", .duplicateKey(at: 3)),
        ("0000", .trailingBytes(at: 1)),
        ("9f01", .truncated(at: 2)),
    ])
    func `bytes that are not one well-formed, valid item are refused`(_ input: String, _ error: RFC_8949.Error) {
        #expect(throws: error) { try RFC_8949.decode(hex(input)) }
    }

    @Test
    func `nesting deeper than the maximum depth is refused`() throws {
        let nested = [UInt8](repeating: 0x81, count: 64) + [0x00]
        #expect(throws: Never.self) { try RFC_8949.decode(nested) }
        #expect(throws: RFC_8949.Error.depth(at: 64)) { try RFC_8949.decode([0x81] + nested) }
        #expect(throws: RFC_8949.Error.depth(at: 2)) { try RFC_8949.decode(nested, maximumDepth: 2) }
    }

    @Test
    func `a length beyond the input is refused before anything is allocated`() {
        #expect(throws: RFC_8949.Error.truncated(at: 9)) { try RFC_8949.decode(hex("9b7fffffffffffffff")) }
        #expect(throws: RFC_8949.Error.truncated(at: 9)) { try RFC_8949.decode(hex("5b7fffffffffffffff")) }
        #expect(throws: RFC_8949.Error.truncated(at: 9)) { try RFC_8949.decode(hex("bb7fffffffffffffff")) }
        #expect(throws: RFC_8949.Error.length(at: 0)) { try RFC_8949.decode(hex("9bffffffffffffffff")) }
    }

    @Test
    func `the decoder reads items one after another`() throws {
        var decoder = RFC_8949.Decoder(hex("a1010243010203f6"))
        #expect(try decoder.decode() == [1: 2])
        #expect(decoder.position == 3)
        #expect(try decoder.decode() == .bytes([1, 2, 3]))
        #expect(try decoder.decode() == .null)
        #expect(decoder.isAtEnd)
        #expect(throws: RFC_8949.Error.truncated(at: 8)) { try decoder.decode() }
        #expect(decoder.position == 8)
    }

    @Test
    func `deterministic encoding sorts map keys by their encoded bytes`() {
        let value: RFC_8949.Value = ["b": 1, "a": 2, 10: 3, -1: 4, 100: 5]
        #expect(RFC_8949.encode(value, serialization: .deterministic) == hex("a50a031864052004616102616201"))
        #expect(RFC_8949.encode(value) == hex("a561620161610" + "20a0320041864" + "05"))
    }

    @Test
    func `floats take the shortest width that keeps their value`() {
        #expect(RFC_8949.encode(.float(0.5)) == hex("f93800"))
        #expect(RFC_8949.encode(.float(65505)) == hex("fa477fe100"))
        #expect(RFC_8949.encode(.float(-0.0)) == hex("f98000"))
        #expect(RFC_8949.encode(.float(0x1p-24)) == hex("f90001"))
        #expect(RFC_8949.encode(.float(0x1p-25)) == hex("fa33000000"))
        #expect(RFC_8949.encode(.float(Double(Float.leastNonzeroMagnitude))) == hex("fa00000001"))
        #expect(RFC_8949.encode(.float(.greatestFiniteMagnitude)) == hex("fb7fefffffffffffff"))
    }

    @Test
    func `integers cover the full range of both major types`() {
        #expect(RFC_8949.Value(Int64.min) == .negative(UInt64(Int64.max)))
        #expect(RFC_8949.Value(Int64.min).integer == Int64.min)
        #expect(RFC_8949.Value.negative(UInt64(Int64.max) + 1).integer == nil)
        #expect(RFC_8949.Value.unsigned(.max).integer == nil)
        #expect(RFC_8949.Value(-500).integer == -500)
    }

    @Test
    func `a map is looked up by key`() throws {
        let value = try RFC_8949.decode(hex("a2616101616282020" + "3"))
        #expect(value["a"] == 1)
        #expect(value["b"] == [2, 3])
        #expect(value["c"] == nil)
    }
}
