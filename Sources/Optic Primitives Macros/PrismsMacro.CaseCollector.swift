// PrismsMacro.CaseCollector.swift
// SyntaxVisitor collecting the enum's own case elements.

import SwiftSyntax

extension PrismsMacro {
    /// Collects the case elements declared directly in an enum's member block.
    ///
    /// Nested type declarations are skipped so cases of nested enums are not
    /// mistaken for cases of the attached enum.
    final class CaseCollector: SyntaxVisitor {
        /// The collected case elements, in declaration order.
        var elements: [EnumCaseElementSyntax] = []

        override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
            elements.append(contentsOf: node.elements)
            return .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}
