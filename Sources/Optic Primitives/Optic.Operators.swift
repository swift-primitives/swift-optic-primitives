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
infix operator >>> : OpticCompositionPrecedence

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

// MARK: - Traversal Composition

extension Optic.Traversal {
    /// Composes two traversals: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Traversal<Whole, Middle>,
        rhs: Optic.Traversal<Middle, Part>
    ) -> Optic.Traversal<Whole, Part> {
        lhs.appending(rhs)
    }
}

// MARK: - Setter Composition

// Setter is the bottom of the lattice — every other optic kind embeds into a
// Setter, and any composition involving a Setter on either side yields a Setter.

extension Optic.Setter {
    /// Composes two setters: `Whole → Middle → Part`.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(rhs)
    }

    /// Composes a setter with an iso, lifting the iso to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    /// Composes a setter with a lens, lifting the lens to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    /// Composes a setter with a prism, lifting the prism to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    /// Composes a setter with an affine, lifting the affine to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    /// Composes a setter with a traversal, lifting the traversal to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Traversal<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }
}

// MARK: - Iso → Setter Composition

extension Optic.Iso {
    /// Composes an iso with a setter, lifting the iso to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

// MARK: - Lens → Setter Composition

extension Optic.Lens {
    /// Composes a lens with a setter, lifting the lens to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

// MARK: - Prism → Setter Composition

extension Optic.Prism {
    /// Composes a prism with a setter, lifting the prism to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
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

    /// Composes an affine with a setter, lifting the affine to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

// MARK: - Traversal → Setter Composition

extension Optic.Traversal {
    /// Composes a traversal with a setter, lifting the traversal to a setter first.
    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Traversal<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}
