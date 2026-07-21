// Plugin.swift
// Compiler plugin entry point

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OpticPrimitivesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PrismsMacro.self
    ]
}
