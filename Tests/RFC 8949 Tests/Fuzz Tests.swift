import RFC_8949
import Testing

struct Fuzzing: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    mutating func bytes(upTo limit: Int) -> [UInt8] {
        (0..<Int.random(in: 0...limit, using: &self)).map { _ in UInt8.random(in: .min ... .max, using: &self) }
    }
}

@Suite(.timeLimit(.minutes(1)))
struct `Fuzz Tests` {
    @Test
    func `random bytes are decoded or refused, never crash`() {
        var random = Fuzzing(state: 0x5eed)
        for _ in 0..<50_000 {
            _ = try? IETF.RFC.`8949`.decode(random.bytes(upTo: 64))
        }
    }

    @Test
    func `nesting past the limit is refused, not followed`() {
        let deep = [UInt8](repeating: 0x81, count: 100_000) + [0x00]
        #expect(throws: IETF.RFC.`8949`.Error.self) { try IETF.RFC.`8949`.decode(deep) }
        let tags = [UInt8](repeating: 0xc6, count: 100_000) + [0x00]
        #expect(throws: IETF.RFC.`8949`.Error.self) { try IETF.RFC.`8949`.decode(tags) }
    }

    @Test
    func `a length larger than the input is refused without reserving it`() {
        for head: UInt8 in [0x5b, 0x7b, 0x9b, 0xbb] {
            #expect(throws: IETF.RFC.`8949`.Error.self) { try IETF.RFC.`8949`.decode([head, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]) }
            #expect(throws: IETF.RFC.`8949`.Error.self) { try IETF.RFC.`8949`.decode([head, 0x00, 0x00, 0x00, 0x00, 0x7f, 0xff, 0xff, 0xff, 0x01]) }
        }
    }
}
