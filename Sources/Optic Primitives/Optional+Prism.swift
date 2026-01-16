//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-optic-primitives open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp and the swift-optic-primitives
// project authors.
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension Optional: Optic.Prism.Accessible {
    /// Prisms for accessing Optional cases.
    @dynamicMemberLookup
    public struct Prisms: Sendable {
        /// Creates a new Prisms instance.
        @inlinable
        public init() {}

        /// Prism for the `.none` case.
        ///
        /// - `embed`: Ignores input and returns `nil`
        /// - `extract`: Returns `Void` if `nil`, otherwise `nil`
        public var none: Optic.Prism<Optional, Void> {
            Optic.Prism(
                embed: { .none },
                extract: {
                    guard case .none = $0 else { return nil }
                    return ()
                }
            )
        }

        /// Prism for the `.some` case.
        ///
        /// - `embed`: Wraps the value in `.some`
        /// - `extract`: Returns the wrapped value if `.some`, otherwise `nil`
        public var some: Optic.Prism<Optional, Wrapped> {
            Optic.Prism(
                embed: Optional.some,
                extract: { $0 }
            )
        }

        /// Enables chaining through Optional values to access nested case paths.
        ///
        /// When `Wrapped` conforms to `Optic.Prism.Accessible`, this subscript allows
        /// accessing nested prisms through the optional, wrapping the result in `Optional`.
        ///
        /// Example:
        /// ```swift
        /// enum Action: Optic.Prism.Accessible {
        ///     case load
        ///     case setName(String)
        ///     // ... Prisms struct ...
        /// }
        ///
        /// let optionalAction: Action? = .setName("Hello")
        /// // Access nested prism: Optional<Action>.Prisms.setName returns Prism<Action?, String?>
        /// ```
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
                    guard case let .some(wrapped) = $0, let member = extract(wrapped)
                    else { return .none }
                    return member
                }
            )
        }
    }

    /// Static accessor for Optional's prisms.
    public static var prisms: Prisms { Prisms() }
}
