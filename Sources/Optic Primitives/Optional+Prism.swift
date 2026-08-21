extension Optional: Optic.Prism.Accessible {

    @dynamicMemberLookup
    public struct Prisms: Sendable {

        @inlinable
        public init() {}

        public var none: Optic.Prism<Optional, Void> {
            Optic.Prism(
                embed: { .none },
                extract: {
                    guard case .none = $0 else { return nil }
                    return ()
                }
            )
        }

        public var some: Optic.Prism<Optional, Wrapped> {
            Optic.Prism(
                embed: Optional.some,
                extract: { $0 }
            )
        }

        @_disfavoredOverload
        public subscript<Member>(
            dynamicMember keyPath: KeyPath<Wrapped.Prisms, Optic.Prism<Wrapped, Member>>
        ) -> Optic.Prism<Optional, Member?>
        where Wrapped: Optic.Prism.Accessible & Sendable, Member: Sendable {
            let prism = Wrapped.prisms[keyPath: keyPath]
            let embed = prism.embed
            let extract = prism.extract
            return Optic.Prism(
                embed: { $0.map(embed) },
                extract: {
                    guard case .some(let wrapped) = $0, let member = extract(wrapped)
                    else { return .none }
                    return member
                }
            )
        }
    }

    public static var prisms: Prisms { Prisms() }
}
