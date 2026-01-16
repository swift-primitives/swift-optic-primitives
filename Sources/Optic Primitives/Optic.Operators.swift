// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-primitives
// project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Precedence Group

/// Precedence for optic composition operators.
///
/// Higher precedence than assignment, lower than most arithmetic.
/// Left associative to enable chaining: `a >>> b >>> c`.
precedencegroup OpticCompositionPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
    lowerThan: TernaryPrecedence
}

// MARK: - Operator Declaration

/// Forward composition operator for optics.
///
/// Composes two optics in left-to-right order:
/// ```swift
/// let addressStreet = userAddress >>> streetLens
/// // Equivalent to: userAddress.appending(streetLens)
/// ```
infix operator >>>: OpticCompositionPrecedence

// MARK: - Iso Composition

extension Optic.Iso {
    /// Composes two isos: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Iso<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes an iso with a lens, yielding a lens.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        Optic.Lens(lhs).appending(rhs)
    }

    /// Composes an iso with a prism, yielding a prism.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        Optic.Prism(lhs).appending(rhs)
    }

    /// Composes an iso with an affine, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

// MARK: - Lens Composition

extension Optic.Lens {
    /// Composes two lenses: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes a lens with an iso, yielding a lens.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        lhs.appending(Optic.Lens(rhs))
    }

    /// Composes a lens with a prism, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes a lens with an affine, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

// MARK: - Prism Composition

extension Optic.Prism {
    /// Composes two prisms: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes a prism with an iso, yielding a prism.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        lhs.appending(Optic.Prism(rhs))
    }

    /// Composes a prism with a lens, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes a prism with an affine, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

// MARK: - Affine Composition

extension Optic.Affine {
    /// Composes two affines: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes an affine with an iso, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }

    /// Composes an affine with a lens, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }

    /// Composes an affine with a prism, yielding an affine.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }
}
