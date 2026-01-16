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
/// ```
///
/// - **Iso**: Bidirectional, total transformation (1 ↔ 1)
/// - **Lens**: Focus on exactly one field in a product type (1 → 1)
/// - **Prism**: Focus on one case in a sum type (1 → 0-1)
/// - **Affine**: Optional focus (Lens ⊔ Prism) (1 → 0-1)
/// - **Traversal**: Focus on multiple elements (1 → 0-n)
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
public enum Optic {}
