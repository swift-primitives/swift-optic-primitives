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
        extract: {
            guard case .success(let v) = $0 else { return nil }
            return v
        }
    )

    static let failurePrism = Optic.Prism<Result<Int>, String>(
        embed: { .failure($0) },
        extract: {
            guard case .failure(let e) = $0 else { return nil }
            return e
        }
    )

    // MARK: - Basic Operations

    @Test
    func `embed constructs Whole from Part`() {
        #expect(Self.successPrism.embed(42) == .success(42))
        #expect(Self.failurePrism.embed("error") == .failure("error"))
    }

    @Test
    func `extract optionally extracts Part from Whole`() {
        #expect(Self.successPrism.extract(.success(42)) == 42)
        #expect(Self.successPrism.extract(.failure("error")) == nil)
        #expect(Self.failurePrism.extract(.failure("error")) == "error")
        #expect(Self.failurePrism.extract(.success(42)) == nil)
    }

    // MARK: - Laws

    @Test
    func `roundtrip law: extract(embed(part)) == part`() {
        let part = 42
        #expect(Self.successPrism.extract(Self.successPrism.embed(part)) == part)
    }

    @Test
    func `embed after extract: embed(extract(whole)) == whole when extract succeeds`() {
        let whole: Result<Int> = .success(42)
        if let extracted = Self.successPrism.extract(whole) {
            #expect(Self.successPrism.embed(extracted) == whole)
        }
    }

    // MARK: - Composition

    @Test
    func `composing chains two prisms`() {
        let outerPrism = Optic.Prism<Result<Result<Int>>, Result<Int>>(
            embed: { .success($0) },
            extract: {
                guard case .success(let v) = $0 else { return nil }
                return v
            }
        )

        let composed = Optic.Prism.composing(outerPrism, Self.successPrism)

        let nested: Result<Result<Int>> = .success(.success(42))
        #expect(composed.extract(nested) == 42)
        #expect(composed.embed(42) == .success(.success(42)))
    }

    @Test
    func `appending chains prisms`() {
        let outerPrism = Optic.Prism<Result<Result<Int>>, Result<Int>>(
            embed: { .success($0) },
            extract: {
                guard case .success(let v) = $0 else { return nil }
                return v
            }
        )

        let composed = outerPrism.appending(Self.successPrism)

        let nested: Result<Result<Int>> = .success(.success(42))
        #expect(composed.extract(nested) == 42)
        #expect(composed.embed(42) == .success(.success(42)))
    }

    // MARK: - Identity

    @Test
    func `identity passes values through unchanged`() {
        let id: Optic.Prism<Int, Int> = .identity

        #expect(id.embed(42) == 42)
        #expect(id.extract(42) == 42)
    }

    // MARK: - Convenience

    @Test
    func `matches returns true when extraction succeeds`() {
        #expect(Self.successPrism.matches(.success(42)) == true)
        #expect(Self.successPrism.matches(.failure("error")) == false)
    }

    @Test
    func `modify transforms the part if present`() {
        let whole: Result<Int> = .success(42)
        let result = Self.successPrism.modify(whole) { $0 * 2 }
        #expect(result == .success(84))
    }

    @Test
    func `modify returns whole unchanged when extraction fails`() {
        let whole: Result<Int> = .failure("error")
        let result = Self.successPrism.modify(whole) { $0 * 2 }
        #expect(result == .failure("error"))
    }

    @Test
    func `modify in place`() {
        var whole: Result<Int> = .success(42)
        Self.successPrism.modify(&whole) { $0 *= 2 }
        #expect(whole == .success(84))
    }

    // MARK: - Construction from Iso

    @Test
    func `init from Iso`() {
        let iso = Optic.Iso<Int, String>(
            forward: { String($0) },
            backward: { Int($0)! }
        )

        let prism = Optic.Prism(iso)

        #expect(prism.embed("42") == 42)
        #expect(prism.extract(42) == "42")
    }

    // MARK: - Pattern Matching

    @Test
    func `pattern matching operator`() {
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

// MARK: - Test Helpers

enum TestEnum: Hashable, Sendable {
    case intCase(Int)
    case stringCase(String)
    case voidCase
}

extension TestEnum {
    static var intCasePrism: Optic.Prism<TestEnum, Int> {
        Optic.Prism(
            embed: { .intCase($0) },
            extract: {
                guard case .intCase(let v) = $0 else { return nil }
                return v
            }
        )
    }

    static var stringCasePrism: Optic.Prism<TestEnum, String> {
        Optic.Prism(
            embed: { .stringCase($0) },
            extract: {
                guard case .stringCase(let v) = $0 else { return nil }
                return v
            }
        )
    }

    static var voidCasePrism: Optic.Prism<TestEnum, Void> {
        Optic.Prism(
            embed: { .voidCase },
            extract: {
                guard case .voidCase = $0 else { return nil }
                return ()
            }
        )
    }
}

// MARK: - Prism Basic Tests

@Suite
struct `Prism - Basic Operations` {
    @Test
    func `embed creates correct value`() {
        let prism = TestEnum.intCasePrism
        let result = prism.embed(42)
        #expect(result == .intCase(42))
    }

    @Test
    func `extract returns value for matching case`() {
        let prism = TestEnum.intCasePrism
        let result = prism.extract(.intCase(42))
        #expect(result == 42)
    }

    @Test
    func `extract returns nil for non-matching case`() {
        let prism = TestEnum.intCasePrism
        let result = prism.extract(.stringCase("hello"))
        #expect(result == nil)
    }

    @Test
    func `roundtrip preserves value`() {
        let prism = TestEnum.intCasePrism
        let original = 42
        let embedded = prism.embed(original)
        let extracted = prism.extract(embedded)
        #expect(extracted == original)
    }
}

// MARK: - Prism Convenience Tests

@Suite
struct `Prism - Convenience Methods` {
    @Test
    func `matches returns true for matching case`() {
        let prism = TestEnum.intCasePrism
        #expect(prism.matches(.intCase(42)))
    }

    @Test
    func `matches returns false for non-matching case`() {
        let prism = TestEnum.intCasePrism
        #expect(!prism.matches(.stringCase("hello")))
    }

    @Test
    func `modify transforms matching case`() {
        let prism = TestEnum.intCasePrism
        let result = prism.modify(.intCase(10)) { $0 * 2 }
        #expect(result == .intCase(20))
    }

    @Test
    func `modify returns original for non-matching case`() {
        let prism = TestEnum.intCasePrism
        let original = TestEnum.stringCase("hello")
        let result = prism.modify(original) { $0 * 2 }
        #expect(result == original)
    }

    @Test
    func `modify inout transforms matching case in place`() {
        let prism = TestEnum.intCasePrism
        var value = TestEnum.intCase(10)
        prism.modify(&value) { $0 *= 2 }
        #expect(value == .intCase(20))
    }

    @Test
    func `modify inout does nothing for non-matching case`() {
        let prism = TestEnum.intCasePrism
        var value = TestEnum.stringCase("hello")
        let original = value
        prism.modify(&value) { $0 *= 2 }
        #expect(value == original)
    }

    @Test
    func `modify inout allows complex in-place mutation`() {
        let prism = TestEnum.stringCasePrism
        var value = TestEnum.stringCase("hello")
        prism.modify(&value) { str in
            str.append(" world")
        }
        #expect(value == .stringCase("hello world"))
    }
}

// MARK: - Prism Identity Tests

@Suite
struct `Prism - Identity` {
    @Test
    func `identity embed returns same value`() {
        let prism = Optic.Prism<Int, Int>.identity
        #expect(prism.embed(42) == 42)
    }

    @Test
    func `identity extract returns same value`() {
        let prism = Optic.Prism<Int, Int>.identity
        #expect(prism.extract(42) == 42)
    }
}

// MARK: - Prism Composition Tests

@Suite
struct `Prism - Composition` {
    @Test
    func `composing two prisms embeds correctly`() {
        // Compose Optional<Result<Int, Error>> prisms
        let optionalPrism = Result<Int, TestError>?.prisms.some
        let resultPrism = Result<Int, TestError>.prisms.success

        let composed = Optic.Prism.composing(optionalPrism, resultPrism)
        let result = composed.embed(42)
        #expect(result == .some(.success(42)))
    }

    @Test
    func `composing two prisms extracts correctly`() {
        let optionalPrism = Result<Int, TestError>?.prisms.some
        let resultPrism = Result<Int, TestError>.prisms.success

        let composed = Optic.Prism.composing(optionalPrism, resultPrism)
        let result = composed.extract(.some(.success(42)))
        #expect(result == 42)
    }

    @Test
    func `composing two prisms returns nil when outer fails`() {
        let optionalPrism = Result<Int, TestError>?.prisms.some
        let resultPrism = Result<Int, TestError>.prisms.success

        let composed = Optic.Prism.composing(optionalPrism, resultPrism)
        let result = composed.extract(nil)
        #expect(result == nil)
    }

    @Test
    func `composing two prisms returns nil when inner fails`() {
        let optionalPrism = Result<Int, TestError>?.prisms.some
        let resultPrism = Result<Int, TestError>.prisms.success

        let composed = Optic.Prism.composing(optionalPrism, resultPrism)
        let result = composed.extract(.some(.failure(.test)))
        #expect(result == nil)
    }

    @Test
    func `appending is equivalent to composing`() {
        let optionalPrism = Result<Int, TestError>?.prisms.some
        let resultPrism = Result<Int, TestError>.prisms.success

        let composed = Optic.Prism.composing(optionalPrism, resultPrism)
        let appended = optionalPrism.appending(resultPrism)

        let testValue: Result<Int, TestError>? = .some(.success(42))
        #expect(composed.extract(testValue) == appended.extract(testValue))
        #expect(composed.embed(42) == appended.embed(42))
    }
}

// MARK: - Optional Prism Tests

@Suite
struct `Optional - Prism` {
    @Test
    func `somePrism embed creates optional`() {
        let prism = Int?.prisms.some
        let result = prism.embed(42)
        #expect(result == .some(42))
    }

    @Test
    func `somePrism extract returns value from some`() {
        let prism = Int?.prisms.some
        let result = prism.extract(.some(42))
        #expect(result == 42)
    }

    @Test
    func `somePrism extract returns nil from none`() {
        let prism = Int?.prisms.some
        let result = prism.extract(nil)
        #expect(result == nil)
    }
}

// MARK: - Pattern Matching Tests

@Suite
struct `Prism - Pattern Matching` {
    @Test
    func `pattern matching with prism returns true for matching case`() {
        let prism = TestEnum.intCasePrism
        let value = TestEnum.intCase(42)

        #expect(prism ~= value)
    }

    @Test
    func `pattern matching with prism returns false for non-matching case`() {
        let prism = TestEnum.intCasePrism
        let value = TestEnum.stringCase("hello")

        #expect(!(prism ~= value))
    }

    @Test
    func `pattern matching works in switch statement`() {
        let prism = TestEnum.intCasePrism
        let value = TestEnum.intCase(42)

        var matched = false
        switch value {
        case prism:
            matched = true

        default:
            break
        }

        #expect(matched)
    }

    @Test
    func `pattern matching distinguishes between cases`() {
        let intPrism = TestEnum.intCasePrism
        let stringPrism = TestEnum.stringCasePrism
        let value = TestEnum.stringCase("hello")

        #expect(!(intPrism ~= value))
        #expect(stringPrism ~= value)
    }
}

// MARK: - Result Prism Tests

enum TestError: Swift.Error, Hashable, Sendable {
    case test
    case other
}

@Suite
struct `Result - Prism` {
    @Test
    func `successPrism embed creates success result`() {
        let prism = Result<Int, TestError>.prisms.success
        let result = prism.embed(42)
        #expect(result == .success(42))
    }

    @Test
    func `successPrism extract returns value from success`() {
        let prism = Result<Int, TestError>.prisms.success
        let result = prism.extract(.success(42))
        #expect(result == 42)
    }

    @Test
    func `successPrism extract returns nil from failure`() {
        let prism = Result<Int, TestError>.prisms.success
        let result = prism.extract(.failure(.test))
        #expect(result == nil)
    }

    @Test
    func `failurePrism embed creates failure result`() {
        let prism = Result<Int, TestError>.prisms.failure
        let result = prism.embed(.test)
        #expect(result == .failure(.test))
    }

    @Test
    func `failurePrism extract returns error from failure`() {
        let prism = Result<Int, TestError>.prisms.failure
        let result = prism.extract(.failure(.test))
        #expect(result == .test)
    }

    @Test
    func `failurePrism extract returns nil from success`() {
        let prism = Result<Int, TestError>.prisms.failure
        let result = prism.extract(.success(42))
        #expect(result == nil)
    }
}
