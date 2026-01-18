// Optic.Prism Tests.swift

import Testing
@testable import Optic_Primitives

@Suite("Optic.Prism")
struct PrismTests {

    enum Result<T: Sendable>: Equatable, Sendable where T: Equatable {
        case success(T)
        case failure(String)
    }

    static let successPrism = Optic.Prism<Result<Int>, Int>(
        embed: { .success($0) },
        extract: { if case .success(let v) = $0 { return v } else { return nil } }
    )

    static let failurePrism = Optic.Prism<Result<Int>, String>(
        embed: { .failure($0) },
        extract: { if case .failure(let e) = $0 { return e } else { return nil } }
    )

    // MARK: - Basic Operations

    @Test("embed constructs Whole from Part")
    func embed() {
        #expect(Self.successPrism.embed(42) == .success(42))
        #expect(Self.failurePrism.embed("error") == .failure("error"))
    }

    @Test("extract optionally extracts Part from Whole")
    func extract() {
        #expect(Self.successPrism.extract(.success(42)) == 42)
        #expect(Self.successPrism.extract(.failure("error")) == nil)
        #expect(Self.failurePrism.extract(.failure("error")) == "error")
        #expect(Self.failurePrism.extract(.success(42)) == nil)
    }

    // MARK: - Laws

    @Test("roundtrip law: extract(embed(part)) == part")
    func roundtripLaw() {
        let part = 42
        #expect(Self.successPrism.extract(Self.successPrism.embed(part)) == part)
    }

    @Test("embed after extract: embed(extract(whole)) == whole when extract succeeds")
    func embedAfterExtract() {
        let whole: Result<Int> = .success(42)
        if let extracted = Self.successPrism.extract(whole) {
            #expect(Self.successPrism.embed(extracted) == whole)
        }
    }

    // MARK: - Composition

    @Test("composing chains two prisms")
    func composing() {
        let outerPrism = Optic.Prism<Result<Result<Int>>, Result<Int>>(
            embed: { .success($0) },
            extract: { if case .success(let v) = $0 { return v } else { return nil } }
        )

        let composed = Optic.Prism.composing(outerPrism, Self.successPrism)

        let nested: Result<Result<Int>> = .success(.success(42))
        #expect(composed.extract(nested) == 42)
        #expect(composed.embed(42) == .success(.success(42)))
    }

    @Test("appending chains prisms")
    func appending() {
        let outerPrism = Optic.Prism<Result<Result<Int>>, Result<Int>>(
            embed: { .success($0) },
            extract: { if case .success(let v) = $0 { return v } else { return nil } }
        )

        let composed = outerPrism.appending(Self.successPrism)

        let nested: Result<Result<Int>> = .success(.success(42))
        #expect(composed.extract(nested) == 42)
        #expect(composed.embed(42) == .success(.success(42)))
    }

    // MARK: - Identity

    @Test("identity passes values through unchanged")
    func identity() {
        let id: Optic.Prism<Int, Int> = .identity

        #expect(id.embed(42) == 42)
        #expect(id.extract(42) == 42)
    }

    // MARK: - Convenience

    @Test("matches returns true when extraction succeeds")
    func matches() {
        #expect(Self.successPrism.matches(.success(42)) == true)
        #expect(Self.successPrism.matches(.failure("error")) == false)
    }

    @Test("modify transforms the part if present")
    func modify() {
        let whole: Result<Int> = .success(42)
        let result = Self.successPrism.modify(whole) { $0 * 2 }
        #expect(result == .success(84))
    }

    @Test("modify returns whole unchanged when extraction fails")
    func modifyNoMatch() {
        let whole: Result<Int> = .failure("error")
        let result = Self.successPrism.modify(whole) { $0 * 2 }
        #expect(result == .failure("error"))
    }

    @Test("modify in place")
    func modifyInPlace() {
        var whole: Result<Int> = .success(42)
        Self.successPrism.modify(&whole) { $0 *= 2 }
        #expect(whole == .success(84))
    }

    // MARK: - Construction from Iso

    @Test("init from Iso")
    func initFromIso() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let prism = Optic.Prism(iso)

        #expect(prism.embed("42") == 42)
        #expect(prism.extract(42) == "42")
    }

    // MARK: - Pattern Matching

    @Test("pattern matching operator")
    func patternMatching() {
        let value: Result<Int> = .success(42)

        switch value {
        case Self.successPrism:
            // Expected
            break
        default:
            Issue.record("Expected success case to match")
        }
    }
}
