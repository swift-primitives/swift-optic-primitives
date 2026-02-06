// Optic.Iso.swift
// A bidirectional, total isomorphism between two types.

extension Optic {
    /// A bidirectional, total isomorphism between `Whole` and `Part`.
    ///
    /// An isomorphism represents a lossless transformation where both directions are total:
    /// - `forward` transforms `Whole` to `Part` (total function)
    /// - `backward` transforms `Part` to `Whole` (total function)
    ///
    /// Isos are the strongest optic: they witness that two types are equivalent.
    /// Every iso can be converted to a weaker optic (lens, prism, affine, traversal).
    ///
    /// ## Laws
    ///
    /// A valid isomorphism must satisfy these roundtrip laws:
    /// - `forward(backward(part)) == part` for all `part`
    /// - `backward(forward(whole)) == whole` for all `whole`
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Celsius ↔ Fahrenheit conversion
    /// let celsiusToFahrenheit = Optic.Iso<Double, Double>(
    ///     forward: { $0 * 9/5 + 32 },
    ///     backward: { ($0 - 32) * 5/9 }
    /// )
    ///
    /// celsiusToFahrenheit.forward(100)   // 212.0
    /// celsiusToFahrenheit.backward(212)  // 100.0
    /// ```
    public struct Iso<Whole, Part>: Sendable {
        /// Transforms `Whole` to `Part`.
        public let forward: @Sendable (Whole) -> Part

        /// Transforms `Part` to `Whole`.
        public let backward: @Sendable (Part) -> Whole

        /// Creates an isomorphism with the given forward and backward functions.
        ///
        /// - Parameters:
        ///   - forward: A function that transforms `Whole` to `Part`.
        ///   - backward: A function that transforms `Part` to `Whole`.
        @inlinable
        public init(
            forward: @escaping @Sendable (Whole) -> Part,
            backward: @escaping @Sendable (Part) -> Whole
        ) {
            self.forward = forward
            self.backward = backward
        }
    }
}

// MARK: - Reversal

extension Optic.Iso {
    /// Returns the reversed isomorphism.
    ///
    /// The reversed iso swaps the direction:
    /// - Original: `Whole → Part`
    /// - Reversed: `Part → Whole`
    @inlinable
    public var reversed: Optic.Iso<Part, Whole> {
        Optic.Iso<Part, Whole>(forward: backward, backward: forward)
    }
}

// MARK: - Composition

extension Optic.Iso {
    /// Composes two isos: `Whole → Middle → Part`.
    ///
    /// The composed iso:
    /// - Forward: applies first's forward, then second's forward
    /// - Backward: applies second's backward, then first's backward
    ///
    /// - Parameters:
    ///   - first: The outer iso from `Whole` to `Middle`.
    ///   - second: The inner iso from `Middle` to `Part`.
    /// - Returns: A composed iso from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Iso<Whole, Middle>,
        _ second: Optic.Iso<Middle, Part>
    ) -> Optic.Iso<Whole, Part> {
        Optic.Iso(
            forward: { second.forward(first.forward($0)) },
            backward: { first.backward(second.backward($0)) }
        )
    }

    /// Appends another iso, composing `self` with `next`.
    ///
    /// - Parameter next: The iso to append.
    /// - Returns: A composed iso from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Iso<Part, Next>) -> Optic.Iso<Whole, Next> {
        Optic.Iso<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Iso where Whole == Part {
    /// The identity isomorphism that passes values through unchanged.
    @inlinable
    public static var identity: Optic.Iso<Whole, Part> {
        Optic.Iso(forward: { $0 }, backward: { $0 })
    }
}

// MARK: - Modification

extension Optic.Iso {
    /// Applies a transformation via the isomorphism.
    ///
    /// This is equivalent to `backward(transform(forward(whole)))`.
    ///
    /// - Parameters:
    ///   - whole: The value to transform.
    ///   - transform: A transformation to apply in the `Part` domain.
    /// - Returns: The transformed value in the `Whole` domain.
    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        backward(transform(forward(whole)))
    }

    /// Applies a transformation via the isomorphism, modifying in place.
    ///
    /// - Parameters:
    ///   - whole: The value to transform in place.
    ///   - transform: A transformation to apply in the `Part` domain.
    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (Part) -> Part) {
        whole = backward(transform(forward(whole)))
    }
}

