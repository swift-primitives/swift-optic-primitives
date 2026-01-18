// Optic.Lens Tests.swift

import Testing
@testable import Optic_Primitives

@Suite("Optic.Lens")
struct LensTests {

    struct User: Equatable, Sendable {
        var name: String
        var age: Int
    }

    struct Address: Equatable, Sendable {
        var city: String
        var zip: String
    }

    struct Person: Equatable, Sendable {
        var user: User
        var address: Address
    }

    static let nameLens = Optic.Lens<User, String>(
        get: { $0.name },
        set: { User(name: $1, age: $0.age) }
    )

    static let ageLens = Optic.Lens<User, Int>(
        get: { $0.age },
        set: { User(name: $0.name, age: $1) }
    )

    static let userLens = Optic.Lens<Person, User>(
        get: { $0.user },
        set: { Person(user: $1, address: $0.address) }
    )

    static let cityLens = Optic.Lens<Address, String>(
        get: { $0.city },
        set: { Address(city: $1, zip: $0.zip) }
    )

    // MARK: - Basic Operations

    @Test("get extracts Part from Whole")
    func get() {
        let user = User(name: "Alice", age: 30)
        #expect(Self.nameLens.get(user) == "Alice")
        #expect(Self.ageLens.get(user) == 30)
    }

    @Test("set replaces Part in Whole")
    func set() {
        let user = User(name: "Alice", age: 30)
        let updated = Self.nameLens.set(user, "Bob")

        #expect(updated.name == "Bob")
        #expect(updated.age == 30)
    }

    // MARK: - Laws

    @Test("GetSet law: get(set(whole, part)) == part")
    func getSetLaw() {
        let user = User(name: "Alice", age: 30)
        let newName = "Charlie"

        let result = Self.nameLens.get(Self.nameLens.set(user, newName))
        #expect(result == newName)
    }

    @Test("SetGet law: set(whole, get(whole)) == whole")
    func setGetLaw() {
        let user = User(name: "Alice", age: 30)

        let result = Self.nameLens.set(user, Self.nameLens.get(user))
        #expect(result == user)
    }

    @Test("SetSet law: set(set(whole, a), b) == set(whole, b)")
    func setSetLaw() {
        let user = User(name: "Alice", age: 30)

        let result1 = Self.nameLens.set(Self.nameLens.set(user, "Bob"), "Charlie")
        let result2 = Self.nameLens.set(user, "Charlie")

        #expect(result1 == result2)
    }

    // MARK: - Composition

    @Test("composing chains two lenses")
    func composing() {
        let addressLens = Optic.Lens<Person, Address>(
            get: { $0.address },
            set: { Person(user: $0.user, address: $1) }
        )

        let composed = Optic.Lens.composing(addressLens, Self.cityLens)

        let person = Person(
            user: User(name: "Alice", age: 30),
            address: Address(city: "NYC", zip: "10001")
        )

        #expect(composed.get(person) == "NYC")

        let updated = composed.set(person, "LA")
        #expect(updated.address.city == "LA")
        #expect(updated.user == person.user)
    }

    @Test("appending chains lenses")
    func appending() {
        let composed = Self.userLens.appending(Self.nameLens)

        let person = Person(
            user: User(name: "Alice", age: 30),
            address: Address(city: "NYC", zip: "10001")
        )

        #expect(composed.get(person) == "Alice")

        let updated = composed.set(person, "Bob")
        #expect(updated.user.name == "Bob")
        #expect(updated.address == person.address)
    }

    // MARK: - Identity

    @Test("identity passes values through unchanged")
    func identity() {
        let id: Optic.Lens<Int, Int> = .identity

        #expect(id.get(42) == 42)
        #expect(id.set(42, 100) == 100)
    }

    // MARK: - Modification

    @Test("modify transforms the focused part")
    func modify() {
        let user = User(name: "Alice", age: 30)
        let result = Self.ageLens.modify(user) { $0 + 1 }

        #expect(result.age == 31)
        #expect(result.name == "Alice")
    }

    @Test("modify in place")
    func modifyInPlace() {
        var user = User(name: "Alice", age: 30)
        Self.ageLens.modify(&user) { $0 + 1 }

        #expect(user.age == 31)
        #expect(user.name == "Alice")
    }

    // MARK: - Construction from Iso

    @Test("init from Iso")
    func initFromIso() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let lens = Optic.Lens(iso)

        #expect(lens.get(42) == "42")
        #expect(lens.set(42, "100") == 100)
    }
}
