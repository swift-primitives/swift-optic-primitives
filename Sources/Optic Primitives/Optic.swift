// Optic.swift
// Namespace for optical types.

/// Namespace for optical types.
///
/// Optics are composable accessors for focusing on parts of data structures.
/// They form a hierarchy based on the nature of the focus:
///
/// ```
///                      Iso
///                     /   \
///                  Lens   Prism
///                     \   /
///                    Affine
///                       |
///                   Traversal
///                       |
///                     Setter
/// ```
///
/// - **Iso**: Bidirectional, total transformation (1 ↔ 1)
/// - **Lens**: Focus on exactly one field in a product type (1 → 1)
/// - **Prism**: Focus on one case in a sum type (1 → 0-1)
/// - **Affine**: Optional focus (Lens ⊔ Prism) (1 → 0-1)
/// - **Traversal**: Focus on multiple elements (1 → 0-n)
/// - **Setter**: Write-only focus (1 → ∗); the most general optic — every other
///   optic kind is also a Setter, but most Setters cannot be promoted upward
///
/// ## Composition Rules
///
/// | First | Second | Result |
/// |-------|--------|--------|
/// | Iso | Iso | Iso |
/// | Iso | Lens | Lens |
/// | Iso | Prism | Prism |
/// | Lens | Lens | Lens |
/// | Lens | Prism | Affine |
/// | Prism | Prism | Prism |
/// | Prism | Lens | Affine |
/// | Affine | * | Affine |
/// | Traversal | * | Traversal |
/// | Setter | * | Setter |
/// | * | Setter | Setter |
public enum Optic {}
