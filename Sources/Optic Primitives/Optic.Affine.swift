extension Optic {

    public struct Affine<Whole, Part>: Sendable {

        public let extract: @Sendable (Whole) -> Part?

        public let set: @Sendable (Whole, Part) -> Whole

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

extension Optic.Affine {

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

    @inlinable
    public func appending<Next>(_ next: Optic.Affine<Part, Next>) -> Optic.Affine<Whole, Next> {
        Optic.Affine<Whole, Next>.composing(self, next)
    }
}

extension Optic.Affine where Whole == Part {

    @inlinable
    public static var identity: Optic.Affine<Whole, Part> {
        Optic.Affine(extract: { $0 }, set: { _, part in part })
    }
}

extension Optic.Affine {

    @inlinable
    public func isPresent(_ whole: Whole) -> Bool {
        extract(whole) != nil
    }

    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        guard let part = extract(whole) else { return whole }
        return set(whole, transform(part))
    }

    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (inout Part) -> Void)
    where Part: Copyable {
        guard var part = extract(whole) else { return }
        transform(&part)
        whole = set(whole, part)
    }
}

extension Optic.Affine {

    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(extract: { .some(lens.get($0)) }, set: lens.set)
    }
}

extension Optic.Affine {

    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(
            extract: prism.extract,
            set: { _, part in prism.embed(part) }
        )
    }
}

extension Optic.Affine {

    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(extract: { .some(iso.forward($0)) }, set: { _, part in iso.backward(part) })
    }
}

extension Optic.Lens {

    @inlinable
    public func appending<Next>(_ prism: Optic.Prism<Part, Next>) -> Optic.Affine<Whole, Next> {
        Optic.Affine(
            extract: { prism.extract(self.get($0)) },
            set: { whole, next in self.set(whole, prism.embed(next)) }
        )
    }
}

extension Optic.Prism {

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
