// PrismsMacro.swift
// Derives an Optic.Prism per enum case.

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Prisms` macro.
///
/// Generates a nested `Prisms` struct with one computed prism property per
/// enum case, a static `prisms` accessor, and an `Optic.Prism.Accessible`
/// conformance.
public struct PrismsMacro {}

// MARK: - Member Macro

extension PrismsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw PrismsMacroError.onlyApplicableToEnum
        }

        let access = accessModifier(of: enumDecl)
        let wholeName = enumDecl.name.text

        let collector = CaseCollector(viewMode: .sourceAccurate)
        collector.walk(enumDecl.memberBlock)

        var properties: [String] = []
        for element in collector.elements {
            properties.append(prismProperty(for: element, whole: wholeName, access: access))
        }

        let prismsStruct = """
            /// Prisms for accessing \(wholeName) cases.
            \(access)struct Prisms: Sendable {
                /// Creates a new Prisms instance.
                @inlinable
                \(access)init() {}
            \(properties.joined(separator: "\n\n"))
            }
            """

        let prismsAccessor = """
            /// Static accessor for \(wholeName)'s prisms.
            \(access)static var prisms: Prisms { Prisms() }
            """

        return [
            DeclSyntax(stringLiteral: prismsStruct),
            DeclSyntax(stringLiteral: prismsAccessor),
        ]
    }
}

// MARK: - Extension Macro

extension PrismsMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            throw PrismsMacroError.onlyApplicableToEnum
        }
        // The compiler passes an empty protocol list when the conformance
        // already exists; emit nothing in that case.
        guard !protocols.isEmpty else { return [] }

        let ext = try ExtensionDeclSyntax(
            "extension \(type.trimmed): Optic.Prism.Accessible {}"
        )
        return [ext]
    }
}

// MARK: - Code Generation

extension PrismsMacro {
    /// The access-level prefix derived from the enum's own modifiers.
    ///
    /// `open` is impossible on enums; `public` and `package` propagate, all
    /// other levels fall back to the default (internal) spelling.
    static func accessModifier(of enumDecl: EnumDeclSyntax) -> String {
        for modifier in enumDecl.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public): return "public "
            case .keyword(.package): return "package "
            default: continue
            }
        }
        return ""
    }

    /// Generates the computed prism property for one enum case element.
    static func prismProperty(
        for element: EnumCaseElementSyntax,
        whole: String,
        access: String
    ) -> String {
        let name = element.name.text
        let parameters = element.parameterClause?.parameters ?? []

        let partType: String
        let embed: String
        let extract: String

        if parameters.isEmpty {
            partType = "Void"
            embed = "{ .\(name) }"
            extract = """
                {
                            guard case .\(name) = $0 else { return nil }
                            return ()
                        }
                """
        } else if parameters.count == 1 {
            let parameter = parameters[parameters.startIndex]
            partType = parameter.type.trimmedDescription
            if let label = label(of: parameter) {
                embed = "{ .\(name)(\(label): $0) }"
            } else {
                embed = "{ .\(name)($0) }"
            }
            extract = """
                {
                            guard case .\(name)(let value) = $0 else { return nil }
                            return value
                        }
                """
        } else {
            var tupleElements: [String] = []
            var embedArguments: [String] = []
            var bindings: [String] = []
            var tupleValues: [String] = []
            for (offset, parameter) in parameters.enumerated() {
                let type = parameter.type.trimmedDescription
                if let label = label(of: parameter) {
                    tupleElements.append("\(label): \(type)")
                    embedArguments.append("\(label): $0.\(offset)")
                    tupleValues.append("\(label): value\(offset)")
                } else {
                    tupleElements.append(type)
                    embedArguments.append("$0.\(offset)")
                    tupleValues.append("value\(offset)")
                }
                bindings.append("let value\(offset)")
            }
            partType = "(\(tupleElements.joined(separator: ", ")))"
            embed = "{ .\(name)(\(embedArguments.joined(separator: ", "))) }"
            extract = """
                {
                            guard case .\(name)(\(bindings.joined(separator: ", "))) = $0 else { return nil }
                            return (\(tupleValues.joined(separator: ", ")))
                        }
                """
        }

        return """
                /// Prism for the `.\(name)` case.
                \(access)var \(name): Optic.Prism<\(whole), \(partType)> {
                    Optic.Prism(
                        embed: \(embed),
                        extract: \(extract)
                    )
                }
            """
    }

    /// The external payload label of a parameter, if it has a usable one.
    static func label(of parameter: EnumCaseParameterSyntax) -> String? {
        guard let firstName = parameter.firstName,
            firstName.tokenKind != .wildcard
        else { return nil }
        return firstName.text
    }
}
