import Testing

@testable import Optic_Primitives

@Suite("Optic.Iso")
struct IsoTests {

    @Test
    func `forward transforms Whole to Part`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        #expect(iso.forward(42) == "42")
        #expect(iso.forward(0) == "0")
        #expect(iso.forward(-1) == "-1")
    }

    @Test
    func `backward transforms Part to Whole`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        #expect(iso.backward("42") == 42)
        #expect(iso.backward("0") == 0)
        #expect(iso.backward("-1") == -1)
    }

    @Test
    func `roundtrip law: backward(forward(whole)) == whole`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        for value in [0, 1, -1, 42, 100, -999] {
            #expect(iso.backward(iso.forward(value)) == value)
        }
    }

    @Test
    func `roundtrip law: forward(backward(part)) == part`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        for value in ["0", "1", "-1", "42", "100", "-999"] {
            #expect(iso.forward(iso.backward(value)) == value)
        }
    }

    @Test
    func `reversed swaps forward and backward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let reversed = iso.reversed

        #expect(reversed.forward("42") == 42)
        #expect(reversed.backward(42) == "42")
    }

    @Test
    func `composing chains two isos`() {
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

    @Test
    func `appending chains isos`() {
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

    @Test
    func `identity passes values through unchanged`() {
        let id: Optic.Iso<Int, Int> = .identity

        #expect(id.forward(42) == 42)
        #expect(id.backward(42) == 42)
    }

    @Test
    func `modify applies transformation via iso`() {
        let iso = Optic.Iso<[Int], [Int]>(
            forward: { $0.reversed() },
            backward: { $0.reversed() }
        )

        let result = iso.modify([1, 2, 3]) { $0.map { $0 * 2 } }
        #expect(result == [2, 4, 6])
    }

    @Test
    func `modify in place`() {
        let iso = Optic.Iso<[Int], [Int]>(
            forward: { $0.reversed() },
            backward: { $0.reversed() }
        )

        var value = [1, 2, 3]
        iso.modify(&value) { $0.map { $0 * 2 } }

        #expect(value == [2, 4, 6])
    }
}

@Suite
struct `Iso - Basic Operations` {
    @Test
    func `forward transforms value`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        #expect(iso.forward(42) == "42")
    }

    @Test
    func `backward transforms value`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        #expect(iso.backward("42") == 42)
    }

    @Test
    func `roundtrip forward then backward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let original = 42
        let result = iso.backward(iso.forward(original))
        #expect(result == original)
    }

    @Test
    func `roundtrip backward then forward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let original = "42"
        let result = iso.forward(iso.backward(original))
        #expect(result == original)
    }
}

@Suite
struct `Iso - Reversal` {
    @Test
    func `reversed swaps forward and backward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let reversed = iso.reversed

        #expect(reversed.forward("42") == 42)
        #expect(reversed.backward(42) == "42")
    }

    @Test
    func `double reversal equals original`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let doubleReversed = iso.reversed.reversed

        #expect(doubleReversed.forward(42) == iso.forward(42))
        #expect(doubleReversed.backward("42") == iso.backward("42"))
    }
}

@Suite
struct `Iso - Composition` {
    @Test
    func `composing two isos forward works correctly`() {
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
    }

    @Test
    func `composing two isos backward works correctly`() {
        let intToString = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let stringToArray = Optic.Iso<String, [Character]>(
            forward: { Array($0) },
            backward: { String($0) }
        )

        let composed = Optic.Iso.composing(intToString, stringToArray)
        #expect(composed.backward(["4", "2"]) == 42)
    }

    @Test
    func `appending is equivalent to composing`() {
        let intToString = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let stringToArray = Optic.Iso<String, [Character]>(
            forward: { Array($0) },
            backward: { String($0) }
        )

        let composed = Optic.Iso.composing(intToString, stringToArray)
        let appended = intToString.appending(stringToArray)

        #expect(composed.forward(42) == appended.forward(42))
        #expect(composed.backward(["4", "2"]) == appended.backward(["4", "2"]))
    }
}

@Suite
struct `Iso - Identity` {
    @Test
    func `identity forward returns same value`() {
        let iso = Optic.Iso<Int, Int>.identity
        #expect(iso.forward(42) == 42)
    }

    @Test
    func `identity backward returns same value`() {
        let iso = Optic.Iso<Int, Int>.identity
        #expect(iso.backward(42) == 42)
    }
}

@Suite
struct `Iso - Modification` {
    @Test
    func `modify applies transformation via iso`() {
        let celsiusToFahrenheit = Optic.Iso<Double, Double>(
            forward: { $0 * 9 / 5 + 32 },
            backward: { ($0 - 32) * 5 / 9 }
        )

        let result = celsiusToFahrenheit.modify(0) { $0 + 18 }
        #expect(result == 10)
    }

    @Test
    func `modify inout applies transformation in place`() {
        let iso = Optic.Iso<Int, Int>(
            forward: { $0 * 2 },
            backward: { $0 / 2 }
        )

        var value = 10
        iso.modify(&value) { $0 + 4 }
        #expect(value == 12)
    }
}

@Suite
struct `Iso - Conversion to Lens` {
    @Test
    func `lens from iso get equals forward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let lens = Optic.Lens(iso)

        #expect(lens.get(42) == "42")
    }

    @Test
    func `lens from iso set ignores original whole`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let lens = Optic.Lens(iso)

        let result = lens.set(999, "42")
        #expect(result == 42)
    }
}

@Suite
struct `Iso - Conversion to Prism` {
    @Test
    func `prism from iso embed equals backward`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let prism = Optic.Prism(iso)

        #expect(prism.embed("42") == 42)
    }

    @Test
    func `prism from iso extract always succeeds`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )
        let prism = Optic.Prism(iso)

        #expect(prism.extract(42) == "42")
    }
}
