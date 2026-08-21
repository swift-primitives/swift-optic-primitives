extension Optic {

    public struct Lens<Whole, Part>: Sendable {

        public let get: @Sendable (Whole) -> Part

        public let set: @Sendable (Whole, Part) -> Whole

        @inlinable
        public init(
            get: @escaping @Sendable (Whole) -> Part,
            set: @escaping @Sendable (Whole, Part) -> Whole
        ) {
            self.get = get
            self.set = set
        }
    }
}

extension Optic.Lens {

    @inlinable
    public static func composing<Middle>(
        _ first: Optic.Lens<Whole, Middle>,
        _ second: Optic.Lens<Middle, Part>
    ) -> Optic.Lens<Whole, Part> {
        Optic.Lens(
            get: { second.get(first.get($0)) },
            set: { whole, part in
                let middle = first.get(whole)
                let newMiddle = second.set(middle, part)
                return first.set(whole, newMiddle)
            }
        )
    }

    @inlinable
    public func appending<Next>(_ next: Optic.Lens<Part, Next>) -> Optic.Lens<Whole, Next> {
        Optic.Lens<Whole, Next>.composing(self, next)
    }
}

extension Optic.Lens where Whole == Part {

    @inlinable
    public static var identity: Optic.Lens<Whole, Part> {
        Optic.Lens(get: { $0 }, set: { _, part in part })
    }
}

extension Optic.Lens {

    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        set(whole, transform(get(whole)))
    }

    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (Part) -> Part) {
        whole = set(whole, transform(get(whole)))
    }
}

extension Optic.Lens {

    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(get: iso.forward, set: { _, part in iso.backward(part) })
    }
}
