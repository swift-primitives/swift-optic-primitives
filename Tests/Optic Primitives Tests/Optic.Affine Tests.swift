// Optic.Affine Tests.swift

import Testing
@testable import Optic_Primitives

@Suite("Optic.Affine")
struct AffineTests {

    static let firstElement = Optic.Affine<[Int], Int>(
        extract: { $0.first },
        set: { array, value in
            guard !array.isEmpty else { return array }
            var copy = array
            copy[0] = value
            return copy
        }
    )

    static let atIndex2 = Optic.Affine<[Int], Int>(
        extract: { $0.count > 2 ? $0[2] : nil },
        set: { array, value in
            guard array.count > 2 else { return array }
            var copy = array
            copy[2] = value
            return copy
        }
    )

    // MARK: - Basic Operations

    @Test
    func `extract optionally extracts Part from Whole`() {
        #expect(Self.firstElement.extract([1, 2, 3]) == 1)
        #expect(Self.firstElement.extract([]) == nil)
    }

    @Test
    func `set replaces Part in Whole when present`() {
        let result = Self.firstElement.set([1, 2, 3], 99)
        #expect(result == [99, 2, 3])
    }

    @Test
    func `set returns Whole unchanged when absent`() {
        let result = Self.firstElement.set([], 99)
        #expect(result == [])
    }

    // MARK: - Laws

    @Test
    func `GetSet when present: extract(set(whole, part)) == part`() {
        let array = [1, 2, 3]
        let newValue = 99

        let result = Self.firstElement.extract(Self.firstElement.set(array, newValue))
        #expect(result == newValue)
    }

    @Test
    func `SetNoop when absent: set(whole, part) == whole`() {
        let emptyArray: [Int] = []
        let result = Self.firstElement.set(emptyArray, 99)
        #expect(result == emptyArray)
    }

    // MARK: - Composition

    @Test
    func `composing chains two affines`() {
        let outerAffine = Optic.Affine<[[Int]], [Int]>(
            extract: { $0.first },
            set: { outer, inner in
                guard !outer.isEmpty else { return outer }
                var copy = outer
                copy[0] = inner
                return copy
            }
        )

        let composed = Optic.Affine.composing(outerAffine, Self.firstElement)

        let nested = [[1, 2], [3, 4]]
        #expect(composed.extract(nested) == 1)

        let updated = composed.set(nested, 99)
        #expect(updated == [[99, 2], [3, 4]])
    }

    @Test
    func `appending chains affines`() {
        let outerAffine = Optic.Affine<[[Int]], [Int]>(
            extract: { $0.first },
            set: { outer, inner in
                guard !outer.isEmpty else { return outer }
                var copy = outer
                copy[0] = inner
                return copy
            }
        )

        let composed = outerAffine.appending(Self.firstElement)

        let nested = [[1, 2], [3, 4]]
        #expect(composed.extract(nested) == 1)

        let updated = composed.set(nested, 99)
        #expect(updated == [[99, 2], [3, 4]])
    }

    // MARK: - Identity

    @Test
    func `identity focuses on the whole value`() {
        let id: Optic.Affine<Int, Int> = .identity

        #expect(id.extract(42) == 42)
        #expect(id.set(42, 100) == 100)
    }

    // MARK: - Convenience

    @Test
    func `isPresent returns true when extraction succeeds`() {
        #expect(Self.firstElement.isPresent([1, 2, 3]) == true)
        #expect(Self.firstElement.isPresent([]) == false)
    }

    @Test
    func `modify transforms the part if present`() {
        let result = Self.firstElement.modify([1, 2, 3]) { $0 * 10 }
        #expect(result == [10, 2, 3])
    }

    @Test
    func `modify returns whole unchanged when absent`() {
        let result = Self.firstElement.modify([]) { $0 * 10 }
        #expect(result == [])
    }

    @Test
    func `modify in place`() {
        var array = [1, 2, 3]
        Self.firstElement.modify(&array) { $0 *= 10 }
        #expect(array == [10, 2, 3])
    }

    // MARK: - Construction from Lens

    @Test
    func `init from Lens`() {
        let lens = Optic.Lens<[Int], Int>(
            get: { $0.count },
            set: { _, _ in [] } // Just for testing
        )

        let affine = Optic.Affine(lens)

        #expect(affine.extract([1, 2, 3]) == 3)
    }

    // MARK: - Construction from Prism

    @Test
    func `init from Prism`() {
        let prism = Optic.Prism<Int?, Int>(
            embed: { $0 },
            extract: { $0 }
        )

        let affine = Optic.Affine(prism)

        #expect(affine.extract(42) == 42)
        #expect(affine.extract(nil) == nil)
        #expect(affine.set(42, 100) == 100)
    }

    // MARK: - Construction from Iso

    @Test
    func `init from Iso`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let affine = Optic.Affine(iso)

        #expect(affine.extract(42) == "42")
        #expect(affine.set(42, "100") == 100)
    }

    // MARK: - Mixed Composition

    @Test
    func `Lens + Prism = Affine`() {
        struct Container: Equatable, Sendable {
            var value: Int?
        }

        let valueLens = Optic.Lens<Container, Int?>(
            get: { $0.value },
            set: { Container(value: $1) }
        )

        let somePrism = Optic.Prism<Int?, Int>(
            embed: { $0 },
            extract: { $0 }
        )

        let composed = valueLens.appending(somePrism)

        let container = Container(value: 42)
        #expect(composed.extract(container) == 42)

        let updated = composed.set(container, 100)
        #expect(updated == Container(value: 100))

        let emptyContainer = Container(value: nil)
        #expect(composed.extract(emptyContainer) == nil)
    }

    @Test
    func `Prism + Lens = Affine`() {
        enum Wrapper: Equatable, Sendable {
            case value([Int])
            case empty
        }

        let valuePrism = Optic.Prism<Wrapper, [Int]>(
            embed: { .value($0) },
            extract: { if case .value(let arr) = $0 { return arr } else { return nil } }
        )

        let countLens = Optic.Lens<[Int], Int>(
            get: { $0.count },
            set: { _, count in Array(repeating: 0, count: count) }
        )

        let composed = valuePrism.appending(countLens)

        let wrapper: Wrapper = .value([1, 2, 3])
        #expect(composed.extract(wrapper) == 3)

        let empty: Wrapper = .empty
        #expect(composed.extract(empty) == nil)
    }
}
