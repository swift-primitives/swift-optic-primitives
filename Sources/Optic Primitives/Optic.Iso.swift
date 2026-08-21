extension Optic {

    public struct Iso<Whole, Part>: Sendable {

        public let forward: @Sendable (Whole) -> Part

        public let backward: @Sendable (Part) -> Whole

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

extension Optic.Iso {

    @inlinable
    public var reversed: Optic.Iso<Part, Whole> {
        Optic.Iso<Part, Whole>(forward: backward, backward: forward)
    }
}

extension Optic.Iso {

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

    @inlinable
    public func appending<Next>(_ next: Optic.Iso<Part, Next>) -> Optic.Iso<Whole, Next> {
        Optic.Iso<Whole, Next>.composing(self, next)
    }
}

extension Optic.Iso where Whole == Part {

    @inlinable
    public static var identity: Optic.Iso<Whole, Part> {
        Optic.Iso(forward: { $0 }, backward: { $0 })
    }
}

extension Optic.Iso {

    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        backward(transform(forward(whole)))
    }

    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (Part) -> Part) {
        whole = backward(transform(forward(whole)))
    }
}
