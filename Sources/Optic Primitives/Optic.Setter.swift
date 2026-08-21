extension Optic {

    public struct Setter<Whole, Part>: Sendable {

        public let modify: @Sendable (Whole, @Sendable (Part) -> Part) -> Whole

        @inlinable
        public init(
            modify: @escaping @Sendable (Whole, @Sendable (Part) -> Part) -> Whole
        ) {
            self.modify = modify
        }
    }
}

extension Optic.Setter {

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

    @inlinable
    public func appending<Next>(_ next: Optic.Setter<Part, Next>) -> Optic.Setter<Whole, Next> {
        Optic.Setter<Whole, Next>.composing(self, next)
    }
}

extension Optic.Setter where Whole == Part {

    @inlinable
    public static var identity: Optic.Setter<Whole, Part> {
        Optic.Setter(modify: { whole, transform in transform(whole) })
    }
}

extension Optic.Setter {

    @inlinable
    public func over(_ whole: Whole, _ transform: @Sendable (Part) -> Part) -> Whole {
        modify(whole, transform)
    }

    @inlinable
    public func over(_ whole: inout Whole, _ transform: @Sendable (Part) -> Part) {
        whole = modify(whole, transform)
    }

    @inlinable
    public func set(_ whole: Whole, to part: Part) -> Whole where Part: Sendable {
        modify(whole) { _ in part }
    }

    @inlinable
    public func set(_ whole: inout Whole, to part: Part) where Part: Sendable {
        whole = modify(whole) { _ in part }
    }
}

extension Optic.Setter {

    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(modify: { whole, transform in iso.backward(transform(iso.forward(whole))) })
    }

    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(modify: { whole, transform in lens.modify(whole, transform) })
    }

    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(modify: { whole, transform in
            guard let part = prism.extract(whole) else { return whole }
            return prism.embed(transform(part))
        })
    }

    @inlinable
    public init(_ affine: Optic.Affine<Whole, Part>) {
        self.init(modify: { whole, transform in affine.modify(whole, transform) })
    }

    @inlinable
    public init(_ traversal: Optic.Traversal<Whole, Part>) {
        self.init(modify: { whole, transform in traversal.modify(whole, transform) })
    }
}
