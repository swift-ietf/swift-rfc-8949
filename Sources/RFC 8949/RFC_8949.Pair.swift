extension RFC_8949 {

    /// One key and value of a map.
    public struct Pair: Sendable, Hashable {
        public var key: Value
        public var value: Value

        public init(key: Value, value: Value) {
            self.key = key
            self.value = value
        }
    }
}
