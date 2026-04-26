// Optic.Setter Tests.swift

import Testing
@testable import Optic_Primitives

@Suite("Optic.Setter")
struct SetterTests {

    struct User: Equatable, Sendable {
        var name: String
        var age: Int
    }

    static let nameSetter = Optic.Setter<User, String>(
        modify: { user, f in User(name: f(user.name), age: user.age) }
    )

    static let ageSetter = Optic.Setter<User, Int>(
        modify: { user, f in User(name: user.name, age: f(user.age)) }
    )

    static let eachInArray = Optic.Setter<[Int], Int>(
        modify: { array, f in array.map(f) }
    )

    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite struct Laws {}
    @Suite struct Composition {}
}

extension SetterTests.Unit {

    @Test
    func `over applies transform to focused part`() {
        let alice = SetterTests.User(name: "Alice", age: 30)
        let upper = SetterTests.nameSetter.over(alice) { $0.uppercased() }
        #expect(upper == SetterTests.User(name: "ALICE", age: 30))
    }

    @Test
    func `set replaces focused part with constant`() {
        let alice = SetterTests.User(name: "Alice", age: 30)
        let bob = SetterTests.nameSetter.set(alice, to: "Bob")
        #expect(bob == SetterTests.User(name: "Bob", age: 30))
    }

    @Test
    func `over with inout mutates in place`() {
        var alice = SetterTests.User(name: "Alice", age: 30)
        SetterTests.nameSetter.over(&alice) { $0.uppercased() }
        #expect(alice == SetterTests.User(name: "ALICE", age: 30))
    }

    @Test
    func `set with inout mutates in place`() {
        var alice = SetterTests.User(name: "Alice", age: 30)
        SetterTests.ageSetter.set(&alice, to: 99)
        #expect(alice == SetterTests.User(name: "Alice", age: 99))
    }
}

extension SetterTests.`Edge Case` {

    @Test
    func `setter on empty array is identity-shape`() {
        let result = SetterTests.eachInArray.over([]) { $0 + 1 }
        #expect(result == [])
    }

    @Test
    func `setter on multi-element array transforms each`() {
        let result = SetterTests.eachInArray.over([1, 2, 3]) { $0 * 10 }
        #expect(result == [10, 20, 30])
    }

    @Test
    func `setter on single-element behaves like singleton transform`() {
        let result = SetterTests.eachInArray.over([42]) { $0 - 42 }
        #expect(result == [0])
    }
}

extension SetterTests.Laws {

    @Test
    func `identity law: over with id is identity`() {
        // Setter law 1: over(whole, id) == whole
        let alice = SetterTests.User(name: "Alice", age: 30)
        #expect(SetterTests.nameSetter.over(alice) { $0 } == alice)
        #expect(SetterTests.ageSetter.over(alice) { $0 } == alice)

        let array = [1, 2, 3]
        #expect(SetterTests.eachInArray.over(array) { $0 } == array)
    }

    @Test
    func `composition law: sequential over equals composed transform`() {
        // Setter law 2: over(over(whole, f), g) == over(whole, { g(f($0)) })
        let alice = SetterTests.User(name: "alice", age: 30)
        let f: @Sendable (String) -> String = { $0.uppercased() }
        let g: @Sendable (String) -> String = { $0 + "!" }

        let sequential = SetterTests.nameSetter.over(SetterTests.nameSetter.over(alice, f), g)
        let composed = SetterTests.nameSetter.over(alice) { g(f($0)) }
        #expect(sequential == composed)
    }

    @Test
    func `identity setter law on Whole == Part`() {
        let identity = Optic.Setter<Int, Int>.identity
        #expect(identity.over(42) { $0 + 1 } == 43)
        #expect(identity.over(42) { $0 } == 42)
    }
}

extension SetterTests.Integration {

    @Test
    func `Setter constructed from Lens behaves equivalently`() {
        let nameLens = Optic.Lens<SetterTests.User, String>(
            get: { $0.name },
            set: { SetterTests.User(name: $1, age: $0.age) }
        )
        let setter = Optic.Setter(nameLens)
        let alice = SetterTests.User(name: "Alice", age: 30)
        #expect(setter.over(alice) { $0.lowercased() } == nameLens.modify(alice) { $0.lowercased() })
    }

    @Test
    func `Setter constructed from Iso preserves transformation`() {
        let mirror = Optic.Iso<Int, Int>(
            forward: { -$0 },
            backward: { -$0 }
        )
        let setter = Optic.Setter(mirror)
        // forward then transform then backward: -(-(7) + 1) = -(-7 + 1) = -(-6) = 6
        #expect(setter.over(7) { $0 + 1 } == 6)
    }

    @Test
    func `Setter constructed from Prism applies only when extract succeeds`() {
        enum Either: Equatable, Sendable {
            case left(Int)
            case right(String)
        }
        let leftPrism = Optic.Prism<Either, Int>(
            embed: { .left($0) },
            extract: { if case .left(let v) = $0 { return v } else { return nil } }
        )
        let setter = Optic.Setter(leftPrism)
        #expect(setter.over(.left(5)) { $0 + 1 } == .left(6))
        #expect(setter.over(.right("hi")) { $0 + 1 } == .right("hi"))
    }

    @Test
    func `Setter constructed from Traversal applies to all elements`() {
        let each = Optic.Traversal<[Int], Int>(
            get: { $0 },
            modify: { array, f in array.map(f) }
        )
        let setter = Optic.Setter(each)
        #expect(setter.over([1, 2, 3]) { $0 * 2 } == [2, 4, 6])
    }
}

extension SetterTests.Composition {

    @Test
    func `Setter composes with Setter via appending`() {
        struct Outer: Equatable, Sendable {
            var users: [SetterTests.User]
        }

        let usersSetter = Optic.Setter<Outer, [SetterTests.User]>(
            modify: { outer, f in Outer(users: f(outer.users)) }
        )
        let eachUser = Optic.Setter<[SetterTests.User], SetterTests.User>(
            modify: { array, f in array.map(f) }
        )

        let composed = usersSetter.appending(eachUser)
        let outer = Outer(users: [
            SetterTests.User(name: "Alice", age: 30),
            SetterTests.User(name: "Bob", age: 25)
        ])
        let aged = composed.over(outer) { user in
            SetterTests.User(name: user.name, age: user.age + 1)
        }
        #expect(aged == Outer(users: [
            SetterTests.User(name: "Alice", age: 31),
            SetterTests.User(name: "Bob", age: 26)
        ]))
    }

    @Test
    func `Setter composes with Setter via operator`() {
        struct Outer: Equatable, Sendable {
            var inner: Inner
        }
        struct Inner: Equatable, Sendable {
            var value: Int
        }

        let innerSetter = Optic.Setter<Outer, Inner>(
            modify: { outer, f in Outer(inner: f(outer.inner)) }
        )
        let valueSetter = Optic.Setter<Inner, Int>(
            modify: { inner, f in Inner(value: f(inner.value)) }
        )
        let composed = innerSetter >>> valueSetter

        let outer = Outer(inner: Inner(value: 10))
        #expect(composed.over(outer) { $0 * 2 } == Outer(inner: Inner(value: 20)))
    }

    @Test
    func `Lens composed with Setter via operator yields Setter`() {
        struct Outer: Equatable, Sendable {
            var inner: Int
        }
        let innerLens = Optic.Lens<Outer, Int>(
            get: { $0.inner },
            set: { Outer(inner: $1) }
        )
        let doublingSetter = Optic.Setter<Int, Int>(
            modify: { value, f in f(value) }
        )
        let composed: Optic.Setter<Outer, Int> = innerLens >>> doublingSetter
        #expect(composed.over(Outer(inner: 5)) { $0 * 2 } == Outer(inner: 10))
    }
}
