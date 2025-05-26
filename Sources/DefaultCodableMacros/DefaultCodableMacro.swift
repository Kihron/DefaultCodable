import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct DefaultCodable: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Collect stored properties (skip computed & static)
        let storedProps: [VariableDeclSyntax] = declaration.memberBlock.members.compactMap { member in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                // ignore computed properties (they have an accessor block)
                varDecl.bindings.first?.accessorBlock == nil
            else { return nil }
            return varDecl
        }

        // Build CodingKeys enum cases ------------------------------------
        let keyCases = storedProps.map { prop -> String in
            let name = prop.bindings.first!
                .pattern.as(IdentifierPatternSyntax.self)!
                .identifier.text
            return "case \(name)"
        }
        .joined(separator: "\n")

        let codingKeysDecl: DeclSyntax = """
        enum CodingKeys: String, CodingKey {
        \(raw: keyCases)
        }
        """

        // Helper to guess a type from a literal --------------------------
        func inferredType(from expr: ExprSyntax?) -> String? {
            guard let expr = expr else { return nil }
            switch expr.kind {
                case .integerLiteralExpr:  return "Int"
                case .floatLiteralExpr:    return "Double"
                case .booleanLiteralExpr:  return "Bool"
                case .stringLiteralExpr:   return "String"
                default:                   return nil
            }
        }

        // Build init(from:) body lines -----------------------------------
        let decodeLines = storedProps.map { prop -> String in
            let binding = prop.bindings.first!
            let name = binding.pattern.as(IdentifierPatternSyntax.self)!.identifier.text

            // Prefer explicit annotation; else try to infer from literal; fallback to String
            let annotatedType = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let guessedType = inferredType(from: binding.initializer?.value)
            let type = annotatedType ?? guessedType ?? "String"

            let defaultExpr = binding.initializer?.value.description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "\(type)()"

            return "self.\(name) = try container.decodeIfPresent(\(type).self, forKey: .\(name)) ?? \(defaultExpr)"
        }
        .joined(separator: "\n")

        let initDecl: DeclSyntax = """
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
        \(raw: decodeLines)
        }
        """

        return [codingKeysDecl, initDecl]
    }
}

@main
struct DefaultCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultCodable.self,
    ]
}
