# swift-rfc-8949

Use this package to read or write CBOR, the binary data format of RFC 8949 that WebAuthn, COSE and CTAP are built on. Decode with `RFC_8949.decode(_:)` for a buffer that holds one item, or with `RFC_8949.Decoder` to read items one after another and know where each ended. Encode with `RFC_8949.encode(_:serialization:)`. Every item is an `RFC_8949.Value`.

## Laws

- Every item of Appendix A decodes to the value it shows, and every item Appendix A marks as round-tripping encodes back to the same bytes.
- Decoding accepts only well-formed items (section 3 and Appendix F): no reserved additional information, no indefinite length on integers or tags, no stray break code, no indefinite-length string chunk that is not a definite string of the same type, and no simple value below 32 in two bytes.
- Decoding also checks the generic validity of section 5.3: text is UTF-8 and no map repeats a key. What a tag requires of its content is not checked.
- Indefinite-length strings, arrays and maps are joined into definite ones, so they do not round-trip.
- A declared length larger than the remaining input is refused before any storage is reserved. Arrays, maps and tags nest at most 64 deep by default.
- `RFC_8949.decode(_:)` refuses bytes after the item. `RFC_8949.Decoder.decode()` leaves its position unchanged when it throws.
- Encoding always uses preferred serialization: shortest heads, definite lengths, and each float in the shortest of half, single and double precision that keeps its exact value. Every NaN is written as 0xf97e00. `.deterministic` also sorts each map's pairs by their encoded keys, as section 4.2.1 requires.
- Integers keep CBOR's two major types, so every integer from -2^64 to 2^64 - 1 is exact. Bignums stay tags 2 and 3 over byte strings.
- Two floats are equal when their bits are: 0.0 and -0.0 differ, and a NaN equals itself.
