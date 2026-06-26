// Optic.Setter.swift
// A write-only focus on parts within a structure.

extension Optic {
    /// A write-only focus on zero or more parts within a structure.
    ///
    /// A setter represents a transformation where:
    /// - `modify` applies a function uniformly to all focused parts within a whole
    ///
    /// Setters are the most general optic in the family: every other optic kind
    /// (Iso, Lens, Prism, Affine, Traversal) is also a Setter, but most Setters
    /// cannot be promoted to a Lens (no single focused value to extract) or a
    /// Prism (no extract/embed bidirectional pair).
    ///
    /// Use a Setter when you need to push a transformation through a structure
    /// without needing to read the focused parts back. Setters categorically
    /// occupy the "Mapping profunctor" slot in the profunctor-optics lattice
    /// (Pickering, Gibbons & Wu, *Profunctor optics: Modular data accessors*,
    /// 2017) — a write-only mutation surface, distinct from Lens (`Strong`),
    /// Prism (`Choice`), and Traversal (`Wandering`).
    ///
    /// ## Laws
    ///
    /// A valid setter must satisfy these laws:
    /// - `over(whole, id) == whole` (Identity: applying the identity transformation does not modify the whole)
    /// - `over(over(whole, f), g) == over(whole, { g(f($0)) })` (Composition: applying transformations sequentially is the same as applying their composition)
    ///
    /// Setter laws are *strictly weaker* than Lens laws (PutGet/GetPut/PutPut)
    /// because a setter does not commit to the existence of a single focused
    /// value, so no round-trip property applies.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Setter that doubles every Int in an array
    /// let eachDouble = Optic.Setter<[Int], Int>(
    ///     modify: { whole, f in whole.map(f) }
    /// )
    ///
    /// eachDouble.over([1, 2, 3]) { $0 * 2 }   // [2, 4, 6]
    /// eachDouble.over([1, 2, 3]) { _ in 0 }   // [0, 0, 0]
    /// ```
    ///
    /// Every existing optic kind embeds into a Setter via the corresponding
    /// initializer:
    ///
    /// ```swift
    /// let nameLens = Optic.Lens<User, String>(get: { $0.name }, set: { User(name: $1, age: $0.age) })
    /// let nameSetter = Optic.Setter(nameLens)
    /// nameSetter.over(user) { $0.uppercased() }
    /// ```
    public struct Setter<Whole, Part>: Sendable {
        /// Applies a transformation uniformly to all focused parts within a whole.
        public let modify: @Sendable (Whole, @Sendable (Part) -> Part) -> Whole

        /// Creates a setter with the given modify function.
        ///
        /// - Parameter modify: A function that applies a transformation to all
        ///   focused parts within the whole.
        @inlinable
        public init(
            modify: @escaping @Sendable (Whole, @Sendable (Part) -> Part) -> Whole
        ) {
            self.modify = modify
        }
    }
}

// MARK: - Composition

extension Optic.Setter {
    /// Composes two setters: `Whole → Middle → Part`.
    ///
    /// The composed setter applies its transformation through the outer
    /// setter, threading the inner setter's modification at the middle level.
    ///
    /// - Parameters:
    ///   - first: The outer setter from `Whole` to `Middle`.
    ///   - second: The inner setter from `Middle` to `Part`.
    /// - Returns: A composed setter from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Setter<Whole, Middle>,
        _ second: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(modify: { whole, transform in
            first.modify(whole) { middle in
                second.modify(middle, transform)
            }
        })
    }

    /// Appends another setter, composing `self` with `next`.
    ///
    /// - Parameter next: The setter to append.
    /// - Returns: A composed setter from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Setter<Part, Next>) -> Optic.Setter<Whole, Next> {
        Optic.Setter<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Setter where Whole == Part {
    /// The identity setter that applies the transformation directly to the whole.
    @inlinable
    public static var identity: Optic.Setter<Whole, Part> {
        Optic.Setter(modify: { whole, transform in transform(whole) })
    }
}

// MARK: - Modification

extension Optic.Setter {
    /// Applies a transformation to all focused parts within a whole.
    ///
    /// This is the canonical "over" operation from the lens literature — apply
    /// a function `f` over every focused part. Equivalent to calling `modify`
    /// directly, but reads more naturally at use sites.
    ///
    /// - Parameters:
    ///   - whole: The value to transform.
    ///   - transform: A transformation to apply to each focused part.
    /// - Returns: A new whole with all focused parts transformed.
    @inlinable
    public func over(_ whole: Whole, _ transform: @Sendable (Part) -> Part) -> Whole {
        modify(whole, transform)
    }

    /// Applies a transformation to all focused parts within a whole, in place.
    ///
    /// - Parameters:
    ///   - whole: The value to transform in place.
    ///   - transform: A transformation to apply to each focused part.
    @inlinable
    public func over(_ whole: inout Whole, _ transform: @Sendable (Part) -> Part) {
        whole = modify(whole, transform)
    }

    /// Replaces all focused parts within a whole with a constant value.
    ///
    /// Equivalent to `over(whole) { _ in part }`.
    ///
    /// - Parameters:
    ///   - whole: The value to transform.
    ///   - part: The constant value to write into all focused positions.
    /// - Returns: A new whole with all focused parts set to `part`.
    @inlinable
    public func set(_ whole: Whole, to part: Part) -> Whole where Part: Sendable {
        modify(whole) { _ in part }
    }

    /// Replaces all focused parts within a whole with a constant value, in place.
    ///
    /// - Parameters:
    ///   - whole: The value to transform in place.
    ///   - part: The constant value to write into all focused positions.
    @inlinable
    public func set(_ whole: inout Whole, to part: Part) where Part: Sendable {
        whole = modify(whole) { _ in part }
    }
}

// MARK: - Construction from other optics

extension Optic.Setter {
    /// Creates a setter from an isomorphism.
    ///
    /// Every iso is a setter — apply the transformation in the `Part` domain
    /// and round-trip back to `Whole`.
    ///
    /// - Parameter iso: The isomorphism to convert.
    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(modify: { whole, transform in iso.backward(transform(iso.forward(whole))) })
    }

    /// Creates a setter from a lens.
    ///
    /// Every lens is a setter — apply the transformation to the focused part
    /// and write it back via the lens's `set`.
    ///
    /// - Parameter lens: The lens to convert.
    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(modify: { whole, transform in lens.modify(whole, transform) })
    }

    /// Creates a setter from a prism.
    ///
    /// Every prism is a setter — apply the transformation only when the prism
    /// extracts a value; otherwise return the whole unchanged.
    ///
    /// - Parameter prism: The prism to convert.
    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(modify: { whole, transform in
            guard let part = prism.extract(whole) else { return whole }
            return prism.embed(transform(part))
        })
    }

    /// Creates a setter from an affine.
    ///
    /// Every affine is a setter — apply the transformation to the optionally-
    /// focused part; if no focus, return the whole unchanged.
    ///
    /// - Parameter affine: The affine to convert.
    @inlinable
    public init(_ affine: Optic.Affine<Whole, Part>) {
        self.init(modify: { whole, transform in affine.modify(whole, transform) })
    }

    /// Creates a setter from a traversal.
    ///
    /// Every traversal is a setter — apply the transformation to all focused
    /// parts.
    ///
    /// - Parameter traversal: The traversal to convert.
    @inlinable
    public init(_ traversal: Optic.Traversal<Whole, Part>) {
        self.init(modify: { whole, transform in traversal.modify(whole, transform) })
    }
}
