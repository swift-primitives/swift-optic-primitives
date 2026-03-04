// Optic.Prism.swift
// A partial isomorphism between Whole and Part.

public import Witness_Primitives

extension Optic {
    /// A partial isomorphism between `Whole` and `Part`.
    ///
    /// A prism represents a bidirectional transformation where:
    /// - `embed` unconditionally constructs `Whole` from `Part` (total function)
    /// - `extract` optionally extracts `Part` from `Whole` (partial function)
    ///
    /// Prisms are the dual of lenses: where lenses focus on product types (structs),
    /// prisms focus on sum types (enums). They're useful for working with enum cases
    /// and their associated values.
    ///
    /// ## Laws
    ///
    /// A valid prism must satisfy:
    /// - `extract(embed(part)) == part` for all `part` (roundtrip)
    /// - `embed(extract(whole)) == whole` when `extract(whole) != nil`
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Result<T> {
    ///     case success(T)
    ///     case failure(Error)
    /// }
    ///
    /// let successPrism = Optic.Prism<Result<Int>, Int>(
    ///     embed: { .success($0) },
    ///     extract: { if case .success(let v) = $0 { return v } else { return nil } }
    /// )
    ///
    /// successPrism.embed(42)                    // .success(42)
    /// successPrism.extract(.success(42))        // Optional(42)
    /// successPrism.extract(.failure(someError)) // nil
    /// ```
    @dynamicMemberLookup
    public struct Prism<Whole, Part>: Sendable, Witness.`Protocol` {
        /// Unconditionally constructs `Whole` from `Part`.
        public let embed: @Sendable (Part) -> Whole

        /// Optionally extracts `Part` from `Whole`.
        public let extract: @Sendable (Whole) -> Part?

        /// Creates a prism with the given embed and extract functions.
        ///
        /// - Parameters:
        ///   - embed: A function that constructs `Whole` from `Part`.
        ///   - extract: A function that optionally extracts `Part` from `Whole`.
        @inlinable
        public init(
            embed: @escaping @Sendable (Part) -> Whole,
            extract: @escaping @Sendable (Whole) -> Part?
        ) {
            self.embed = embed
            self.extract = extract
        }
    }
}

// MARK: - Composition

extension Optic.Prism {
    /// Composes two prisms: `Whole → Middle → Part`.
    ///
    /// The composed prism:
    /// - Embeds by applying the second prism's embed, then the first's
    /// - Extracts by applying the first prism's extract, then the second's
    ///
    /// - Parameters:
    ///   - first: The outer prism from `Whole` to `Middle`.
    ///   - second: The inner prism from `Middle` to `Part`.
    /// - Returns: A composed prism from `Whole` to `Part`.
    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Prism<Whole, Middle>,
        _ second: Optic.Prism<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        Optic.Prism(
            embed: { first.embed(second.embed($0)) },
            extract: { first.extract($0).flatMap(second.extract) }
        )
    }

    /// Appends another prism, composing `self` with `next`.
    ///
    /// - Parameter next: The prism to append.
    /// - Returns: A composed prism from `Whole` to `Next`.
    @inlinable
    public func appending<Next>(_ next: Optic.Prism<Part, Next>) -> Optic.Prism<Whole, Next> {
        Optic.Prism<Whole, Next>.composing(self, next)
    }
}

// MARK: - Identity

extension Optic.Prism where Whole == Part {
    /// The identity prism that passes values through unchanged.
    @inlinable
    public static var identity: Optic.Prism<Whole, Part> {
        Optic.Prism(embed: { $0 }, extract: { $0 })
    }
}

// MARK: - Convenience

extension Optic.Prism {
    /// Checks if the given value matches this prism's case.
    ///
    /// - Parameter whole: The value to check.
    /// - Returns: `true` if extraction succeeds, `false` otherwise.
    @inlinable
    public func matches(_ whole: Whole) -> Bool {
        extract(whole) != nil
    }

    /// Modifies the part within a whole value, if it exists.
    ///
    /// - Parameters:
    ///   - whole: The value to modify.
    ///   - transform: A transformation to apply to the extracted part.
    /// - Returns: A new whole with the transformed part, or the original if extraction fails.
    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        guard let part = extract(whole) else { return whole }
        return embed(transform(part))
    }

    /// Modifies the part within a whole value in place, if it exists.
    ///
    /// - Parameters:
    ///   - whole: The value to modify in place.
    ///   - transform: A transformation to apply to the extracted part in place.
    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (inout Part) -> Void)
    where Part: Copyable {
        guard var part = extract(whole) else { return }
        transform(&part)
        whole = embed(part)
    }
}

// MARK: - Construction from Iso

extension Optic.Prism {
    /// Creates a prism from an isomorphism.
    ///
    /// An iso is a special case of prism where extraction always succeeds.
    ///
    /// - Parameter iso: The isomorphism to convert.
    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(embed: iso.backward, extract: { .some(iso.forward($0)) })
    }
}

// MARK: - Accessible Protocol (Hoisted)

/// Hoisted protocol for `Optic.Prism.Accessible`. Prefer using `Optic.Prism.Accessible` in all contexts.
///
/// This protocol is intentionally not constrained to `Sendable` to allow unconditional
/// conformance for generic stdlib types like `Optional` and `Result`. Individual prism
/// properties within the `Prisms` struct can add `Sendable` constraints as needed.
///
/// This exists because Swift doesn't yet support protocols nested in generic types.
public protocol __OpticPrismAccessible {
    associatedtype Prisms
    static var prisms: Prisms { get }
}

extension Optic.Prism {
    /// Protocol for types that provide prism-based case access.
    ///
    /// Types conforming to this protocol have a nested `Prisms` struct and a static
    /// `prisms` property, enabling ergonomic composition via `@dynamicMemberLookup`.
    public typealias Accessible = __OpticPrismAccessible
}

// MARK: - Dynamic Member Lookup for Composition

extension Optic.Prism where Part: Optic.Prism.Accessible {
    /// Enables ergonomic prism composition via dot syntax.
    ///
    /// When the `Part` type conforms to `Optic.Prism.Accessible`, you can chain
    /// prism access through nested types:
    ///
    /// ```swift
    /// // Instead of:
    /// Outer.prisms.inner.appending(Inner.prisms.value)
    ///
    /// // Write:
    /// Outer.prisms.inner.value
    /// ```
    ///
    /// - Parameter keyPath: A key path to a prism on the `Part` type's `Prisms`.
    /// - Returns: A composed prism from `Whole` to `Next`.
    @inlinable
    public subscript<Next>(
        dynamicMember keyPath: KeyPath<Part.Prisms, Optic.Prism<Part, Next>>
    ) -> Optic.Prism<Whole, Next> {
        appending(Part.prisms[keyPath: keyPath])
    }
}

// MARK: - Pattern Matching

extension Optic.Prism {
    /// Enables pattern matching syntax in switch statements.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let prism = Optional<Int>.prisms.some
    /// let value: Int? = 42
    ///
    /// switch value {
    /// case prism:
    ///     print("Has a value")
    /// default:
    ///     print("Is nil")
    /// }
    /// ```
    @inlinable
    public static func ~= (pattern: Optic.Prism<Whole, Part>, value: Whole) -> Bool {
        pattern.matches(value)
    }
}
