precedencegroup OpticCompositionPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
    lowerThan: TernaryPrecedence
}

infix operator >>> : OpticCompositionPrecedence

extension Optic.Iso {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Iso<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        Optic.Lens(lhs).appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        Optic.Prism(lhs).appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

extension Optic.Lens {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        lhs.appending(Optic.Lens(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

extension Optic.Prism {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Prism<Whole, Part> {
        lhs.appending(Optic.Prism(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        Optic.Affine(lhs).appending(rhs)
    }
}

extension Optic.Traversal {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Traversal<Whole, Middle>,
        rhs: Optic.Traversal<Middle, Part>
    ) -> Optic.Traversal<Whole, Part> {
        lhs.appending(rhs)
    }
}

extension Optic.Setter {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Setter<Whole, Middle>,
        rhs: Optic.Traversal<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        lhs.appending(Optic.Setter(rhs))
    }
}

extension Optic.Iso {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Iso<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

extension Optic.Lens {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Lens<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

extension Optic.Prism {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Prism<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

extension Optic.Affine {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Affine<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(rhs)
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Iso<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Lens<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Prism<Middle, Part>
    ) -> Optic.Affine<Whole, Part> {
        lhs.appending(Optic.Affine(rhs))
    }

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Affine<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}

extension Optic.Traversal {

    @inlinable
    public static func >>> <Middle>(
        lhs: Optic.Traversal<Whole, Middle>,
        rhs: Optic.Setter<Middle, Part>
    ) -> Optic.Setter<Whole, Part> {
        Optic.Setter(lhs).appending(rhs)
    }
}
