// Prisms Macro Tests.swift

import Testing

@testable import Optic_Primitives

// MARK: - Fixtures

@Prisms
private enum Route: Equatable, Sendable {
    case home
    case detail(Int)
    case search(query: String, page: Int)
    case redirect(String, permanent: Bool)
}

@Prisms
private enum Box<Value: Equatable & Sendable>: Equatable, Sendable {
    case empty
    case full(Value)
}

@Prisms
private enum Outer: Equatable, Sendable {
    case inner(Route)

    @Prisms
    enum Nested: Equatable, Sendable {
        case leaf(Int)
    }
}

@Prisms
private enum Escaped: Equatable, Sendable {
    case `default`
    case `case`(Int)
}

// MARK: - Test Suite Structure

@Suite
struct `Prisms Macro` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Unit Tests

extension `Prisms Macro`.Unit {
    @Test
    func `payload-free case derives a Void prism`() {
        let prism = Route.prisms.home

        #expect(prism.embed(()) == .home)
        #expect(prism.extract(.home) != nil)
        #expect(prism.extract(.detail(1)) == nil)
    }

    @Test
    func `single-payload case derives an embed and extract pair`() {
        let prism = Route.prisms.detail

        #expect(prism.embed(42) == .detail(42))
        #expect(prism.extract(.detail(42)) == 42)
        #expect(prism.extract(.home) == nil)
    }

    @Test
    func `multi-payload case derives a labeled tuple prism`() {
        let prism = Route.prisms.search

        #expect(prism.embed((query: "swift", page: 2)) == .search(query: "swift", page: 2))

        let extracted = prism.extract(.search(query: "swift", page: 2))
        #expect(extracted?.query == "swift")
        #expect(extracted?.page == 2)
        #expect(prism.extract(.home) == nil)
    }

    @Test
    func `mixed labeled and unlabeled payloads preserve their labels`() {
        let prism = Route.prisms.redirect

        #expect(
            prism.embed(("https://example.com", permanent: true))
                == .redirect("https://example.com", permanent: true)
        )

        let extracted = prism.extract(.redirect("https://example.com", permanent: false))
        #expect(extracted?.0 == "https://example.com")
        #expect(extracted?.permanent == false)
    }

    @Test
    func `derived prisms satisfy the roundtrip law`() {
        #expect(Route.prisms.detail.extract(Route.prisms.detail.embed(7)) == 7)

        let whole: Route = .search(query: "optics", page: 3)
        if let part = Route.prisms.search.extract(whole) {
            #expect(Route.prisms.search.embed(part) == whole)
        }
    }

    @Test
    func `macro conforms the enum to Optic.Prism.Accessible`() {
        func requiresAccessible<T: Optic.Prism.Accessible>(_: T.Type) -> Bool { true }

        #expect(requiresAccessible(Route.self))
        #expect(requiresAccessible(Box<Int>.self))
    }
}

// MARK: - Edge Case Tests

extension `Prisms Macro`.`Edge Case` {
    @Test
    func `generic enum derives prisms over its generic payload`() {
        let prism = Box<Int>.prisms.full

        #expect(prism.embed(42) == .full(42))
        #expect(prism.extract(.full(42)) == 42)
        #expect(prism.extract(.empty) == nil)
    }

    @Test
    func `nested enum derives its own prisms without leaking into the outer enum`() {
        let outer = Outer.prisms.inner
        let nested = Outer.Nested.prisms.leaf

        #expect(outer.extract(.inner(.home)) == .home)
        #expect(nested.embed(1) == .leaf(1))
        #expect(nested.extract(.leaf(1)) == 1)
    }

    @Test
    func `escaped case names derive working prisms`() {
        #expect(Escaped.prisms.`default`.embed(()) == .default)
        #expect(Escaped.prisms.`default`.extract(.case(1)) == nil)
        #expect(Escaped.prisms.`case`.extract(.case(9)) == 9)
    }
}

// MARK: - Integration Tests

extension `Prisms Macro`.Integration {
    @Test
    func `derived prisms compose via appending`() {
        let composed = Outer.prisms.inner.appending(Route.prisms.detail)

        #expect(composed.extract(.inner(.detail(5))) == 5)
        #expect(composed.embed(5) == .inner(.detail(5)))
        #expect(composed.extract(.inner(.home)) == nil)
    }

    @Test
    func `derived prisms compose via dynamic member lookup`() {
        let composed = Outer.prisms.inner.detail

        #expect(composed.extract(.inner(.detail(5))) == 5)
        #expect(composed.embed(5) == .inner(.detail(5)))
    }

    @Test
    func `derived prisms support switch pattern matching`() {
        let route: Route = .detail(1)

        switch route {
        case Route.prisms.detail:
            #expect(Bool(true))
        default:
            Issue.record("expected the detail prism to match")
        }
    }
}
