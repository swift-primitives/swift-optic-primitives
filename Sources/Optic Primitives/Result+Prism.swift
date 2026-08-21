extension Result: Optic.Prism.Accessible {

    public struct Prisms: Sendable {

        @inlinable
        public init() {}

        public var success: Optic.Prism<Result, Success> {
            Optic.Prism(
                embed: Result.success,
                extract: {
                    guard case .success(let value) = $0 else { return nil }
                    return value
                }
            )
        }

        public var failure: Optic.Prism<Result, Failure> {
            Optic.Prism(
                embed: Result.failure,
                extract: {
                    guard case .failure(let error) = $0 else { return nil }
                    return error
                }
            )
        }
    }

    public static var prisms: Prisms { Prisms() }
}
