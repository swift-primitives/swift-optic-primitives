// Prisms.swift
// Case-path derivation macro for enums.

/// Derives an `Optic.Prism` for every case of the attached enum.
///
/// Attached to an enum, `@Prisms` generates:
/// - a nested `Prisms` struct with one computed prism property per case,
/// - a static `prisms` accessor, and
/// - a conformance to `Optic.Prism.Accessible`.
///
/// Each derived prism pairs the case's constructor (`embed`) with a
/// pattern-matching extractor (`extract`):
/// - a payload-free case derives `Optic.Prism<Self, Void>`,
/// - a single-payload case derives `Optic.Prism<Self, Payload>`,
/// - a multi-payload case derives `Optic.Prism<Self, (A, B, ...)>`,
///   preserving payload labels in the tuple.
///
/// ## Example
///
/// ```swift
/// @Prisms
/// enum Route {
///     case home
///     case detail(Int)
///     case search(query: String, page: Int)
/// }
///
/// Route.prisms.detail.embed(42)              // .detail(42)
/// Route.prisms.detail.extract(.detail(42))   // Optional(42)
/// Route.prisms.detail.extract(.home)         // nil
/// Route.prisms.search.extract(.search(query: "swift", page: 1))?.query
/// ```
///
/// Because the enum conforms to `Optic.Prism.Accessible`, derived prisms
/// compose with nested accessible types via `@dynamicMemberLookup` on
/// `Optic.Prism`.
@attached(member, names: named(Prisms), named(prisms))
@attached(extension, conformances: Optic.Prism.Accessible)
public macro Prisms() = #externalMacro(module: "Optic_Primitives_Macros", type: "PrismsMacro")
