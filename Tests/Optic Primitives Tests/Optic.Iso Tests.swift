// Optic.Iso Tests.swift

import Testing
@testable import Optic_Primitives

@Suite("Optic.Iso")
struct IsoTests {

    // MARK: - Basic Operations

    @Test("forward transforms Whole to Part")
    func forward() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        #expect(iso.forward(42) == "42")
        #expect(iso.forward(0) == "0")
        #expect(iso.forward(-1) == "-1")
    }

    @Test("backward transforms Part to Whole")
    func backward() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        #expect(iso.backward("42") == 42)
        #expect(iso.backward("0") == 0)
        #expect(iso.backward("-1") == -1)
    }

    // MARK: - Laws

    @Test("roundtrip law: backward(forward(whole)) == whole")
    func roundtripForwardBackward() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        for value in [0, 1, -1, 42, 100, -999] {
            #expect(iso.backward(iso.forward(value)) == value)
        }
    }

    @Test("roundtrip law: forward(backward(part)) == part")
    func roundtripBackwardForward() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        for value in ["0", "1", "-1", "42", "100", "-999"] {
            #expect(iso.forward(iso.backward(value)) == value)
        }
    }

    // MARK: - Reversal

    @Test("reversed swaps forward and backward")
    func reversed() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let reversed = iso.reversed

        #expect(reversed.forward("42") == 42)
        #expect(reversed.backward(42) == "42")
    }

    // MARK: - Composition

    @Test("composing chains two isos")
    func composing() {
        let intToString = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let stringToArray = Optic.Iso<String, [Character]>(
            forward: { Array($0) },
            backward: { String($0) }
        )

        let composed = Optic.Iso.composing(intToString, stringToArray)

        #expect(composed.forward(42) == ["4", "2"])
        #expect(composed.backward(["4", "2"]) == 42)
    }

    @Test("appending chains isos")
    func appending() {
        let intToString = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let stringToArray = Optic.Iso<String, [Character]>(
            forward: { Array($0) },
            backward: { String($0) }
        )

        let composed = intToString.appending(stringToArray)

        #expect(composed.forward(42) == ["4", "2"])
        #expect(composed.backward(["4", "2"]) == 42)
    }

    // MARK: - Identity

    @Test("identity passes values through unchanged")
    func identity() {
        let id: Optic.Iso<Int, Int> = .identity

        #expect(id.forward(42) == 42)
        #expect(id.backward(42) == 42)
    }

    // MARK: - Modification

    @Test("modify applies transformation via iso")
    func modify() {
        let iso = Optic.Iso<[Int], [Int]>(
            forward: { $0.reversed() },
            backward: { $0.reversed() }
        )
        // [1, 2, 3] forward -> [3, 2, 1] -> map *2 -> [6, 4, 2] -> backward -> [2, 4, 6]
        let result = iso.modify([1, 2, 3]) { $0.map { $0 * 2 } }
        #expect(result == [2, 4, 6])
    }

    @Test("modify in place")
    func modifyInPlace() {
        let iso = Optic.Iso<[Int], [Int]>(
            forward: { $0.reversed() },
            backward: { $0.reversed() }
        )
        // [1, 2, 3] forward -> [3, 2, 1] -> map *2 -> [6, 4, 2] -> backward -> [2, 4, 6]
        var value = [1, 2, 3]
        iso.modify(&value) { $0.map { $0 * 2 } }

        #expect(value == [2, 4, 6])
    }
}
