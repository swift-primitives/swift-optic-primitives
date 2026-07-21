// PrismsMacroError.swift
// Errors thrown during @Prisms expansion.

/// Errors raised while expanding the `@Prisms` macro.
enum PrismsMacroError: Swift.Error, CustomStringConvertible {
    /// The macro was attached to a declaration that is not an enum.
    case onlyApplicableToEnum

    var description: String {
        switch self {
        case .onlyApplicableToEnum:
            "@Prisms can only be applied to enums. Structs, classes, and actors are not supported."
        }
    }
}
