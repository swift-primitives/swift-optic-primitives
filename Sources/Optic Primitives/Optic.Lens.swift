// Optic.Lens.swift
// A focus on exactly one field within a product type.

extension Optic {
    /// A focus on exactly one field within a product type.
    ///
    /// A lens represents a bidirectional transformation where:
    /// - `get` extracts `Part` from `Whole` (total function)
    /// - `set` replaces the `Part` within `Whole` (total function)
    ///
    /// Lenses are the dual of prisms: where prisms focus on sum types (enums),
    /// lenses focus on product types (structs). They're useful for accessing
    /// and modifying nested struct fields immutably.
    ///
    /// ## Laws
    ///
    /// A valid lens must satisfy these laws:
    /// - `get(set(whole, part)) == part` (GetSet: what you set is what you get)
    /// - `set(whole, get(whole)) == whole` (SetGet: setting with current value is identity)
    /// - `set(set(whole, a), b) == set(whole, b)` (SetSet: second set wins)
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct User {
    ///     var name: String
    ///     var age: Int
    /// }
    ///
    /// let nameLens = Optic.Lens<User, String>(
    ///     get: { $0.name },
    ///     set: { user, name in User(name: name, age: user.age) }
    /// )
    ///
    /// let user = User(name: "Alice", age: 30)
    /// nameLens.get(user)                    // "Alice"
    /// nameLens.set(user, "Bob")             // User(name: "Bob", age: 30)
    /// ```
    public struct Lens<Whole, Part>: Sendable {
        /// Extracts `Part` from `Whole`.
        public let get: @Sendable (Whole) -> Part

        /// Replaces the `Part` within `Whole`.
        public let set: @Sendable (Whole, Part) -> Whole

        /// Creates a lens with the given get and set functions.
        ///
        /// - Parameters:
        ///   - get: A function that extracts `Part` from `Whole`.
        ///   - set: A function that replaces `Part` within `Whole`.
        @inlinable
        public init(
            get: @escaping @Sendable (Whole) -> Part,
            set: @escaping @Sendable (Whole, Part) -> Whole
        ) {
            self.get = get
            self.set = set
        }
    }
}

// MARK: - Composition

extension Optic.Lens {
    /// Composes two lenses: `Whole → Middle → Part`.
    ///
    /// The composed lens:
    /// - Get: applies first's get, then second's get
    /// - Set: extracts the middle, sets the part in it, then sets the middle back
    ///
    /// - Parameters:
    ///   - first: The outer lens from `Whole` to `Middle`.
    ///   - second: The inner lens from `Middle` to `Part`.
    /// - Returns: A composed lens from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Lens<Whole, Middle>,
        _ second: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        Optic.Lens(
            get: { second.get(first.get($0)) },
            set: { whole, part in
                let middle = first.get(whole)
                let newMiddle = second.set(middle, part)
                return first.set(whole, newMiddle)
            }
        )
    }

    /// Appends another lens, composing `self` with `next`.
    ///
    /// - Parameter next: The lens to append.
    /// - Returns: A composed lens from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Lens<Part, Next>) -> Optic.Lens<Whole, Next> {
        Optic.Lens<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Lens where Whole == Part {
    /// The identity lens that focuses on the whole value.
    @inlinable
    public static var identity: Optic.Lens<Whole, Part> {
        Optic.Lens(get: { $0 }, set: { _, part in part })
    }
}

// MARK: - Modification

extension Optic.Lens {
    /// Modifies the focused part within a whole value.
    ///
    /// - Parameters:
    ///   - whole: The value containing the part to modify.
    ///   - transform: A transformation to apply to the focused part.
    /// - Returns: A new whole with the transformed part.
    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        set(whole, transform(get(whole)))
    }

    /// Modifies the focused part within a whole value, in place.
    ///
    /// - Parameters:
    ///   - whole: The value to modify in place.
    ///   - transform: A transformation to apply to the focused part.
    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (Part) -> Part) {
        whole = set(whole, transform(get(whole)))
    }
}

// MARK: - Construction from Iso

extension Optic.Lens {
    /// Creates a lens from an isomorphism.
    ///
    /// An iso is a special case of lens where the "set" operation
    /// completely replaces the whole with the embedded part.
    ///
    /// - Parameter iso: The isomorphism to convert.
    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(get: iso.forward, set: { _, part in iso.backward(part) })
    }
}
