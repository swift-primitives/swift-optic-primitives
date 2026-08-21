extension Optic {

    public struct Traversal<Whole, Part>: Sendable {

        public let get: @Sendable (Whole) -> [Part]

        public let modify: @Sendable (Whole, @Sendable (Part) -> Part) -> Whole

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

extension Optic.Traversal {

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

    @inlinable
    public func appending<Next>(_ next: Optic.Traversal<Part, Next>) -> Optic.Traversal<Whole, Next>
    {
        Optic.Traversal<Whole, Next>.composing(self, next)
    }
}

extension Optic.Traversal where Whole == Part {

    @inlinable
    public static var identity: Optic.Traversal<Whole, Part> {
        Optic.Traversal(
            get: { [$0] },
            modify: { whole, transform in transform(whole) }
        )
    }
}

extension Optic.Traversal {

    @inlinable
    public func set(_ whole: Whole, _ value: Part) -> Whole
    where Part: Sendable {
        modify(whole) { _ in value }
    }

    @inlinable
    public func count(_ whole: Whole) -> Int {
        get(whole).count
    }

    @inlinable
    public func isEmpty(_ whole: Whole) -> Bool {
        get(whole).isEmpty
    }
}

extension Optic.Traversal where Whole == [Part] {

    @inlinable
    public static var each: Optic.Traversal<[Part], Part> {
        Optic.Traversal(
            get: { $0 },
            modify: { array, transform in array.map(transform) }
        )
    }
}

extension Optic.Traversal {

    @inlinable
    public init(_ affine: Optic.Affine<Whole, Part>) {
        self.init(
            get: { affine.extract($0).map { [$0] } ?? [] },
            modify: { whole, transform in affine.modify(whole, transform) }
        )
    }
}

extension Optic.Traversal {

    @inlinable
    public init(_ lens: Optic.Lens<Whole, Part>) {
        self.init(
            get: { [lens.get($0)] },
            modify: { whole, transform in lens.modify(whole, transform) }
        )
    }
}

extension Optic.Traversal {

    @inlinable
    public init(_ prism: Optic.Prism<Whole, Part>) {
        self.init(
            get: { prism.extract($0).map { [$0] } ?? [] },
            modify: { whole, transform in prism.modify(whole, transform) }
        )
    }
}

extension Optic.Traversal {

    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(
            get: { [iso.forward($0)] },
            modify: { whole, transform in iso.modify(whole, transform) }
        )
    }
}
