extension RFC_8949 {

    /// IEEE 754 half precision, converted by hand so that it works where `Float16` is unavailable (Appendix D).
    enum Half {}
}

extension RFC_8949.Half {

    /// The value of the half-precision bits `half`.
    static func double(_ half: UInt16) -> Double {
        let exponent = Int(half >> 10 & 0x1f)
        let mantissa = Double(half & 0x3ff)
        let sign: FloatingPointSign = half & 0x8000 == 0 ? .plus : .minus
        switch exponent {
        case 0:
            return Double(sign: sign, exponent: -24, significand: mantissa)
        case 31:
            guard half & 0x3ff == 0 else {
                let bits: UInt64 =
                    (sign == .minus ? 1 << 63 : 0) | 0x7ff0_0000_0000_0000
                    | UInt64(half & 0x3ff) << 42
                return Double(bitPattern: bits)
            }
            return sign == .minus ? -.infinity : .infinity
        default:
            return Double(sign: sign, exponent: exponent - 25, significand: mantissa + 1024)
        }
    }

    /// The half-precision bits that hold `value` exactly, or `nil` when none do. NaN is not handled here.
    static func bits(_ value: Double) -> UInt16? {
        let sign: UInt16 = value.sign == .minus ? 0x8000 : 0
        let magnitude = value.magnitude
        let candidate: UInt16
        if magnitude == 0 {
            candidate = sign
        } else if magnitude == .infinity {
            candidate = sign | 0x7c00
        } else if magnitude.exponent > 15 {
            return nil
        } else if magnitude.exponent >= -14 {
            let mantissa = (magnitude.significand - 1) * 1024
            guard mantissa == mantissa.rounded(.towardZero) else { return nil }
            candidate = sign | UInt16(magnitude.exponent + 15) << 10 | UInt16(mantissa)
        } else {
            let mantissa = magnitude * 0x1p24
            guard mantissa == mantissa.rounded(.towardZero), mantissa >= 1 else { return nil }
            candidate = sign | UInt16(mantissa)
        }
        return double(candidate).bitPattern == value.bitPattern ? candidate : nil
    }
}
