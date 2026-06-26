# Optic Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Composable functional optics for Swift — `Iso`, `Lens`, `Prism`, `Affine`, `Traversal`, and `Setter` as plain value types with no dependencies.

---

## Quick Start

An optic is a first-class, composable accessor that focuses on one part of a larger value. A `Lens` focuses on a stored field; composing lenses with `>>>` lets you read and immutably update a deeply nested field without rebuilding every enclosing struct by hand.

```swift
import Optic_Primitives

struct Address { var street: String; var city: String }
struct Company { var name: String; var address: Address }
struct User { var name: String; var employer: Company }

let employer = Optic.Lens<User, Company>(
    get: { $0.employer },
    set: { user, value in User(name: user.name, employer: value) }
)
let address = Optic.Lens<Company, Address>(
    get: { $0.address },
    set: { company, value in Company(name: company.name, address: value) }
)
let street = Optic.Lens<Address, String>(
    get: { $0.street },
    set: { address, value in Address(street: value, city: address.city) }
)

// Compose three lenses into one User → String focus.
let userStreet = employer >>> address >>> street

let user = User(
    name: "Alice",
    employer: Company(name: "Acme", address: Address(street: "1 Main St", city: "Portland"))
)

userStreet.get(user)                          // "1 Main St"
let moved = userStreet.set(user, "2 Oak Ave") // User with only the nested street replaced
userStreet.modify(user) { $0.uppercased() }   // "1 MAIN ST" focused, rest untouched
```

The same `>>>` operator composes across optic kinds. Composing a `Lens` with a `Prism` yields an `Affine` (optional focus); any composition involving a `Setter` yields a `Setter`. Stdlib `Optional` and `Result` ship prism accessors out of the box:

```swift
import Optic_Primitives

enum LoadError: Error { case timedOut }

let someValue = Int?.prisms.some
someValue.extract(42)   // Optional(42)
someValue.extract(nil)  // nil

let success = Result<Int, LoadError>.prisms.success
success.embed(42)                       // .success(42)
success.extract(.failure(.timedOut))    // nil
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-optic-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Optic Primitives", package: "swift-optic-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Key Features

- **Six optic kinds** — `Iso`, `Lens`, `Prism`, `Affine`, `Traversal`, and `Setter`, each a small `Sendable` value type holding closures.
- **Type-directed composition** — the `>>>` operator (and `appending`) returns the correct optic kind for each pair: `Lens >>> Prism` is an `Affine`, anything `>>>` a `Setter` is a `Setter`.
- **Lawful by construction** — each optic documents the algebraic laws it must satisfy (roundtrip, get/set, set/get, set/set).
- **Stdlib prisms** — `Optional` and `Result` conform to the prism-accessor protocol, exposing `.prisms.some`, `.prisms.none`, `.prisms.success`, and `.prisms.failure`.
- **Ergonomic chaining** — `@dynamicMemberLookup` lets conforming sum types chain nested prisms through dot syntax.
- **Pattern matching** — prisms implement `~=`, so a prism can be used directly as a `case` in a `switch`.
- **Zero dependencies** — no imports beyond the Swift standard library; Foundation-free.

---

## Architecture

One library product, zero external dependencies.

| Product | Target | Purpose |
|---------|--------|---------|
| `Optic Primitives` | `Sources/Optic Primitives/` | The `Optic` namespace and its six optic kinds, the `>>>` composition operator with its `OpticCompositionPrecedence` group, and stdlib `Optional` / `Result` prism accessors. |

The `Optic` enum is a namespace; each optic kind is a nested generic struct over `<Whole, Part>`:

| Type | Focus | Operations |
|------|-------|------------|
| `Optic.Iso<Whole, Part>` | Total, bidirectional (1 ↔ 1) | `forward`, `backward`, `reversed`, `modify` |
| `Optic.Lens<Whole, Part>` | One field of a product type (1 → 1) | `get`, `set`, `modify` |
| `Optic.Prism<Whole, Part>` | One case of a sum type (1 → 0-1) | `embed`, `extract`, `matches`, `modify`, `~=` |
| `Optic.Affine<Whole, Part>` | Optional focus, Lens ⊔ Prism (1 → 0-1) | `extract`, `set`, `isPresent`, `modify` |
| `Optic.Traversal<Whole, Part>` | Zero or more elements (1 → 0-n) | `get`, `modify`, `count`, `isEmpty`, `each` |
| `Optic.Setter<Whole, Part>` | Write-only, the most general optic (1 → *) | `over`, `set`, `modify` |

Optics form a lattice: every stronger optic embeds into a weaker one via a corresponding initializer (e.g. `Optic.Setter(someLens)`, `Optic.Affine(somePrism)`). `Iso` is the strongest; `Setter` is the weakest and absorbs every other kind under composition.

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
