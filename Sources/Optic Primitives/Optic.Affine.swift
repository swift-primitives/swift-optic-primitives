// Optic.Affine.swift
// An optional focus on a value that may or may not exist.

extension Optic {
    /// An optional focus on a value that may or may not exist.
    ///
    /// An affine (also called "optional" or "affine traversal") represents a transformation where:
    /// - `extract` optionally extracts `Part` from `Whole` (partial function)
    /// - `set` replaces the `Part` within `Whole` if it exists (total function)
    ///
    /// Affine is the join of Lens and Prism in the optics hierarchy:
    /// - Like Lens: can set a value
    /// - Like Prism: extraction may fail
    ///
    /// Affines are useful for focusing on optional fields, dictionary values,
    /// or array elements at specific indices.
    ///
    /// ## Laws
    ///
    /// A valid affine must satisfy:
    /// - `extract(set(whole, part)) == part` when `extract(whole) != nil` (GetSet when present)
    /// - `set(whole, part) == whole` when `extract(whole) == nil` (SetNoop when absent)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Focus on first element of array (may not exist)
    /// let first = Optic.Affine<[Int], Int>(
    ///     extract: { $0.first },
    ///     set: { array, value in
    ///         guard !array.isEmpty else { return array }
    ///         var copy = array
    ///         copy[0] = value
    ///         return copy
    ///     }
    /// )
    ///
    /// first.extract([1, 2, 3])     // Optional(1)
    /// first.extract([])            // nil
    /// first.set([1, 2, 3], 99)    // [99, 2, 3]
    /// first.set([], 99)           // []
    /// ```
    public struct Affine<Whole, Part>: Sendable {
        /// Optionally extracts `Part` from `Whole`.
        public let extract: @Sendable (Whole) -> Part?

        /// Replaces the `Part` within `Whole`, or returns `Whole` unchanged if not present.
        public let set: @Sendable (Whole, Part) -> Whole

        /// Creates an affine with the given extract and set functions.
        ///
        /// - Parameters:
        ///   - extract: A function that optionally extracts `Part` from `Whole`.
        ///   - set: A function that replaces `Part` within `Whole`.
        @inlinable
        public init(
            extract: @escaping @Sendable (Whole) -> Part?,
            set: @escaping @Sendable (Whole, Part) -> Whole
        ) {
            self.extract = extract
            self.set = set
        }
    }
}

// MARK: - Composition

extension Optic.Affine {
    /// Composes two affines: `Whole → Middle → Part`.
    ///
    /// The composed affine:
    /// - Extract: applies first's extract, then second's extract if present
    /// - Set: extracts middle, sets part in it, then sets middle back
    ///
    /// - Parameters:
    ///   - first: The outer affine from `Whole` to `Middle`.
    ///   - second: The inner affine from `Middle` to `Part`.
    /// - Returns: A composed affine from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Affine<Whole, Middle>,
        _ second: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(
            extract: { first.extract($0).flatMap(second.extract) },
            set: { whole, part in
                guard let middle = first.extract(whole) else { return whole }
                let newMiddle = second.set(middle, part)
                return first.set(whole, newMiddle)
            }
        )
    }

    /// Appends another affine, composing `self` with `next`.
    ///
    /// - Parameter next: The affine to append.
    /// - Returns: A composed affine from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Affine<Part, Next>) -> Optic.Affine<Whole, Next> {
        Optic.Affine<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Affine where Whole == Part {
    /// The identity affine that focuses on the whole value.
    @inlinable
    public static var identity: Optic.Affine<Whole, Part> {
        Optic.Affine(extract: { $0 }, set: { _, part in part })
    }
}

// MARK: - Convenience

extension Optic.Affine {
    /// Checks if this affine can focus on the given value.
    ///
    /// - Parameter whole: The value to check.
    /// - Returns: `true` if `extract` succeeds, `false` otherwise.
    @inlinable
    public func isPresent(_ whole: Whole) -> Bool {
        extract(whole) != nil
    }

    /// Modifies the part within a whole value, if it exists.
    ///
    /// - Parameters:
    ///   - whole: The value to modify.
    ///   - transform: A transformation to apply to the focused part.
    /// - Returns: A new whole with the transformed part, or the original if not present.
    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        guard let part = extract(whole) else { return whole }
        return set(whole, transform(part))
    }

    /// Modifies the part within a whole value in place, if it exists.
    ///
    /// - Parameters:
    ///   - whole: The value to modify in place.
    ///   - transform: A transformation to apply to the focused part in place.
    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (inout Part) -> Void)
    where Part: Copyable {
        guard var part = extract(whole) else { return }
        transform(&part)
        whole = set(whole, part)
    }
}

// MARK: - Construction from Lens

extension Optic.Affine {
    /// Creates an affine from a lens.
    ///
    /// A lens is a special case of affine where extraction always succeeds.
    ///
    /// - Parameter lens: The lens to convert.
    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(extract: { .some(lens.get($0)) }, set: lens.set)
    }
}

// MARK: - Construction from Prism

extension Optic.Affine {
    /// Creates an affine from a prism.
    ///
    /// A prism is a special case of affine where set always replaces the whole.
    ///
    /// - Parameter prism: The prism to convert.
    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(
            extract: prism.extract,
            set: { _, part in prism.embed(part) }
        )
    }
}

// MARK: - Construction from Iso

extension Optic.Affine {
    /// Creates an affine from an isomorphism.
    ///
    /// An iso is a special case of affine where both operations are total.
    ///
    /// - Parameter iso: The isomorphism to convert.
    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(extract: { .some(iso.forward($0)) }, set: { _, part in iso.backward(part) })
    }
}

// MARK: - Mixed Composition (Lens + Prism = Affine)

extension Optic.Lens {
    /// Composes a lens with a prism, yielding an affine.
    ///
    /// This captures the optics composition rule: Lens ∘ Prism = Affine.
    ///
    /// - Parameter prism: The prism to compose with.
    /// - Returns: An affine from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ prism: Optic.Prism<Part, Next>) -> Optic.Affine<Whole, Next> {
        Optic.Affine(
            extract: { prism.extract(self.get($0)) },
            set: { whole, next in self.set(whole, prism.embed(next)) }
        )
    }
}

extension Optic.Prism {
    /// Composes a prism with a lens, yielding an affine.
    ///
    /// This captures the optics composition rule: Prism ∘ Lens = Affine.
    ///
    /// - Parameter lens: The lens to compose with.
    /// - Returns: An affine from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ lens: Optic.Lens<Part, Next>) -> Optic.Affine<Whole, Next> {
        Optic.Affine(
            extract: { self.extract($0).map(lens.get) },
            set: { whole, next in
                guard let part = self.extract(whole) else { return whole }
                return self.embed(lens.set(part, next))
            }
        )
    }
}
