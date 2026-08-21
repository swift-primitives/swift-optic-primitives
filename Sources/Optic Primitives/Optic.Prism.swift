extension Optic {

    @dynamicMemberLookup
    public struct Prism<Whole, Part>: Sendable {

        public let embed: @Sendable (Part) -> Whole

        public let extract: @Sendable (Whole) -> Part?

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

extension Optic.Prism {

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

    @inlinable
    public func appending<Next>(_ next: Optic.Prism<Part, Next>) -> Optic.Prism<Whole, Next> {
        Optic.Prism<Whole, Next>.composing(self, next)
    }
}

extension Optic.Prism where Whole == Part {

    @inlinable
    public static var identity: Optic.Prism<Whole, Part> {
        Optic.Prism(embed: { $0 }, extract: { $0 })
    }
}

extension Optic.Prism {

    @inlinable
    public func matches(_ whole: Whole) -> Bool {
        extract(whole) != nil
    }

    @inlinable
    public func modify(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        guard let part = extract(whole) else { return whole }
        return embed(transform(part))
    }

    @inlinable
    public func modify(_ whole: inout Whole, _ transform: (inout Part) -> Void)
    where Part: Copyable {
        guard var part = extract(whole) else { return }
        transform(&part)
        whole = embed(part)
    }
}

extension Optic.Prism {

    @inlinable
    public init(_ iso: Optic.Iso<Whole, Part>) {
        self.init(embed: iso.backward, extract: { .some(iso.forward($0)) })
    }
}

public protocol __OpticPrismAccessible {
    associatedtype Prisms
    static var prisms: Prisms { get }
}

extension Optic.Prism {

    public typealias Accessible = __OpticPrismAccessible
}

extension Optic.Prism where Part: Self.Accessible {

    @inlinable
    public subscript<Next>(
        dynamicMember keyPath: KeyPath<Part.Prisms, Optic.Prism<Part, Next>>
    ) -> Optic.Prism<Whole, Next> {
        appending(Part.prisms[keyPath: keyPath])
    }
}

extension Optic.Prism {

    @inlinable
    public static func ~= (pattern: Optic.Prism<Whole, Part>, value: Whole) -> Bool {
        pattern.matches(value)
    }
}
