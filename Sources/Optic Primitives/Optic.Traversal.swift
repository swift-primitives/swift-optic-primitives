// Optic.Traversal.swift
// A focus on zero or more elements within a structure.

extension Optic {
    /// A focus on zero or more elements within a structure.
    ///
    /// A traversal represents a transformation where:
    /// - `get` extracts all focused `Part` values from `Whole`
    /// - `modify` transforms all focused values within `Whole`
    ///
    /// Traversals generalize affines to multiple foci. They're useful for
    /// operating on all elements of a collection, all matching cases of an enum,
    /// or any other "multi-focus" scenario.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Focus on all elements of an array
    /// let each = Optic.Traversal<[Int], Int>.each
    ///
    /// each.get([1, 2, 3])                  // [1, 2, 3]
    /// each.modify([1, 2, 3]) { $0 * 2 }    // [2, 4, 6]
    /// ```
    public struct Traversal<Whole, Part>: Sendable {
        /// Extracts all focused `Part` values from `Whole`.
        public let get: @Sendable (Whole) -> [Part]

        /// Transforms all focused values within `Whole`.
        public let modify: @Sendable (Whole, @Sendable (Part) -> Part) -> Whole

        /// Creates a traversal with the given get and modify functions.
        ///
        /// - Parameters:
        ///   - get: A function that extracts all focused values.
        ///   - modify: A function that transforms all focused values.
        @inlinable
        public init(
            get: @escaping @Sendable (Whole) -> [Part],
            modify: @escaping @Sendable (Whole, @Sendable (Part) -> Part) -> Whole
        ) {
            self.get = get
            self.modify = modify
        }
    }
}

// MARK: - Composition

extension Optic.Traversal {
    /// Composes two traversals: `Whole → Middle → Part`.
    ///
    /// The composed traversal:
    /// - Get: gets all middles, then gets all parts from each middle
    /// - Modify: modifies all parts within all middles
    ///
    /// - Parameters:
    ///   - first: The outer traversal from `Whole` to `Middle`.
    ///   - second: The inner traversal from `Middle` to `Part`.
    /// - Returns: A composed traversal from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Traversal<Whole, Middle>,
        _ second: Optic.Traversal<Middle, Part>
    ) -> Optic.Traversal<Whole, Part> {
        Optic.Traversal(
            get: { first.get($0).flatMap(second.get) },
            modify: { whole, transform in
                first.modify(whole) { middle in
                    second.modify(middle, transform)
                }
            }
        )
    }

    /// Appends another traversal, composing `self` with `next`.
    ///
    /// - Parameter next: The traversal to append.
    /// - Returns: A composed traversal from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Traversal<Part, Next>) -> Optic.Traversal<Whole, Next> {
        Optic.Traversal<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Traversal where Whole == Part {
    /// The identity traversal that focuses on the single whole value.
    @inlinable
    public static var identity: Optic.Traversal<Whole, Part> {
        Optic.Traversal(
            get: { [$0] },
            modify: { whole, transform in transform(whole) }
        )
    }
}

// MARK: - Convenience

extension Optic.Traversal {
    /// Sets all focused values to the same value.
    ///
    /// - Parameters:
    ///   - whole: The value containing elements to set.
    ///   - value: The value to set all focused elements to.
    /// - Returns: A new whole with all focused elements set to the given value.
    @inlinable
    public func set(_ whole: Whole, _ value: Part) -> Whole
    where Part: Sendable {
        modify(whole) { _ in value }
    }

    /// Returns the number of focused elements.
    ///
    /// - Parameter whole: The value to count focused elements in.
    /// - Returns: The number of focused elements.
    @inlinable
    public func count(_ whole: Whole) -> Int {
        get(whole).count
    }

    /// Checks if there are any focused elements.
    ///
    /// - Parameter whole: The value to check.
    /// - Returns: `true` if there is at least one focused element.
    @inlinable
    public func isEmpty(_ whole: Whole) -> Bool {
        get(whole).isEmpty
    }
}

// MARK: - Array Traversal

extension Optic.Traversal where Whole == [Part] {
    /// A traversal that focuses on each element of an array.
    @inlinable
    public static var each: Optic.Traversal<[Part], Part> {
        Optic.Traversal(
            get: { $0 },
            modify: { array, transform in array.map(transform) }
        )
    }
}

// MARK: - Construction from Affine

extension Optic.Traversal {
    /// Creates a traversal from an affine.
    ///
    /// An affine is a special case of traversal with 0 or 1 focus.
    ///
    /// - Parameter affine: The affine to convert.
    @inlinable
    public init(_ affine: Optic.Affine<Whole, Part>) {
        self.init(
            get: { affine.extract($0).map { [$0] } ?? [] },
            modify: { whole, transform in affine.modify(whole, transform) }
        )
    }
}

// MARK: - Construction from Lens

extension Optic.Traversal {
    /// Creates a traversal from a lens.
    ///
    /// A lens is a special case of traversal with exactly 1 focus.
    ///
    /// - Parameter lens: The lens to convert.
    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(
            get: { [lens.get($0)] },
            modify: { whole, transform in lens.modify(whole, transform) }
        )
    }
}

// MARK: - Construction from Prism

extension Optic.Traversal {
    /// Creates a traversal from a prism.
    ///
    /// A prism is a special case of traversal with 0 or 1 focus.
    ///
    /// - Parameter prism: The prism to convert.
    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(
            get: { prism.extract($0).map { [$0] } ?? [] },
            modify: { whole, transform in prism.modify(whole, transform) }
        )
    }
}

// MARK: - Construction from Iso

extension Optic.Traversal {
    /// Creates a traversal from an isomorphism.
    ///
    /// An iso is a special case of traversal with exactly 1 focus.
    ///
    /// - Parameter iso: The isomorphism to convert.
    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(
            get: { [iso.forward($0)] },
            modify: { whole, transform in iso.modify(whole, transform) }
        )
    }
}
