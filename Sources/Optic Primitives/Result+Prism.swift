// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

extension Result: Optic.Prism.Accessible {
    /// Prisms for accessing Result cases.
    public struct Prisms: Sendable {
        /// Creates a new Prisms instance.
        @inlinable
        public init() {}

        /// Prism for the `.success` case.
        ///
        /// - `embed`: Wraps the value in `.success`
        /// - `extract`: Returns the success value if `.success`, otherwise `nil`
        public var success: Optic.Prism<Result, Success> {
            Optic.Prism(
                embed: Result.success,
                extract: {
                    guard case .success(let value) = $0 else { return nil }
                    return value
                }
            )
        }

        /// Prism for the `.failure` case.
        ///
        /// - `embed`: Wraps the error in `.failure`
        /// - `extract`: Returns the failure value if `.failure`, otherwise `nil`
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

    /// Static accessor for Result's prisms.
    public static var prisms: Prisms { Prisms() }
}
