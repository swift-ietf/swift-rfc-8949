extension RFC_8949 {

    /// Why bytes are not one well-formed, valid CBOR data item.
    public enum Error: Swift.Error, Sendable, Equatable {

        /// The input ends inside an item.
        case truncated(at: Int)

        /// The additional information 28, 29 or 30, which section 3 reserves.
        case reservedAdditionalInformation(Int, at: Int)

        /// Additional information 31 where it means nothing: on major type 0, 1 or 6, or a break code (0xff)
        /// outside an indefinite-length item.
        case unexpectedIndefinite(at: Int)

        /// A chunk of an indefinite-length string that is not a definite-length string of the same major type
        /// (section 3.2.3).
        case invalidChunk(at: Int)

        /// A simple value below 32 written in two bytes (section 3.3).
        case invalidSimple(UInt8, at: Int)

        /// A text string that is not valid UTF-8 (section 5.3.1).
        case invalidUTF8(at: Int)

        /// A map with the same key twice (section 5.6).
        case duplicateKey(at: Int)

        /// A length too large for this platform's memory.
        case length(at: Int)

        /// Arrays, maps and tags nested deeper than the decoder allows.
        case depth(at: Int)

        /// Bytes left after the one item expected.
        case trailingBytes(at: Int)
    }
}
