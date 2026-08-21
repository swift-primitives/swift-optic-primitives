import Testing

@testable import Optic_Primitives

extension Optic {
    @Suite struct Tests {
        @Test func `namespace is available`() {

            #expect(Bool(true))
        }
    }
}
