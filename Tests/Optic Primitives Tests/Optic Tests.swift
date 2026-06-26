// Optic Tests.swift

import Testing

@testable import Optic_Primitives

extension Optic {
    @Suite struct Tests {
        @Test func `namespace is available`() {
            // Minimal smoke test — the real suite is authored during flip-prep.
            #expect(Bool(true))
        }
    }
}
