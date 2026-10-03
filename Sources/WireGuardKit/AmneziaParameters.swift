// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

/// AmneziaWG obfuscation settings (the v1 keys Jc, Jmin, Jmax, S1, S2, H1-H4). They go to
/// amneziawg-go in the same UAPI `set` as the private key; a configuration without them is
/// plain WireGuard.
public struct AmneziaParameters: Equatable {
    public let jc: UInt32
    public let jmin: UInt32
    public let jmax: UInt32
    public let s1: UInt32
    public let s2: UInt32
    public let h1: UInt32
    public let h2: UInt32
    public let h3: UInt32
    public let h4: UInt32

    /// The wg-quick keys, lower-cased, in the order amneziawg-go reads them.
    public static let keys = ["jc", "jmin", "jmax", "s1", "s2", "h1", "h2", "h3", "h4"]

    /// From wg-quick values keyed by lower-cased name. Nil unless all nine are there, digits
    /// only, inside amneziawg-go's limits and consistent (the same rules as the desktop app).
    public init?(_ values: [String: String]) {
        func number(_ key: String, _ range: ClosedRange<UInt32>) -> UInt32? {
            guard let text = values[key], !text.isEmpty, text.count <= 10,
                  text.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let value = UInt32(text), range.contains(value) else { return nil }
            return value
        }
        let header: ClosedRange<UInt32> = 5...UInt32.max
        guard let jc = number("jc", 0...128),
              let jmin = number("jmin", 0...1280), let jmax = number("jmax", 0...1280),
              let s1 = number("s1", 0...1132), let s2 = number("s2", 0...1132),
              let h1 = number("h1", header), let h2 = number("h2", header),
              let h3 = number("h3", header), let h4 = number("h4", header),
              jmin <= jmax, s1 + 56 != s2, Set([h1, h2, h3, h4]).count == 4 else { return nil }
        (self.jc, self.jmin, self.jmax, self.s1, self.s2) = (jc, jmin, jmax, s1, s2)
        (self.h1, self.h2, self.h3, self.h4) = (h1, h2, h3, h4)
    }

    private var ordered: [UInt32] { [jc, jmin, jmax, s1, s2, h1, h2, h3, h4] }

    /// `jc=5\n` ... for the UAPI `set`.
    public var uapiLines: String {
        zip(Self.keys, ordered).map { "\($0)=\($1)\n" }.joined()
    }

    /// `Jc = 5\n` ... for a wg-quick file.
    public var wgQuickLines: String {
        let names = ["Jc", "Jmin", "Jmax", "S1", "S2", "H1", "H2", "H3", "H4"]
        return zip(names, ordered).map { "\($0) = \($1)\n" }.joined()
    }
}
