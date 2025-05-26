import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DefaultCodableMacros)
import DefaultCodableMacros

let testMacros: [String: Macro.Type] = [
    "DefaultCodable": DefaultCodable.self
]
#endif

final class DefaultCodableTests: XCTestCase {
    func testDefaultDecodableExpansion() throws {
        #if canImport(DefaultCodableMacros)
            assertMacroExpansion(
                """
                @DefaultCodable
                struct Foo: Codable {
                    var x = 42
                    var y = "hello"
                }
                """,
                expandedSource: """
                struct Foo: Codable {
                    var x = 42
                    var y = "hello"
                
                    enum CodingKeys: String, CodingKey {
                        case x
                        case y
                    }
                
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.x = try container.decodeIfPresent(Int.self, forKey: .x) ?? 42
                        self.y = try container.decodeIfPresent(String.self, forKey: .y) ?? "hello"
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testObjectDefault() throws {
        #if canImport(DefaultCodableMacros)
            assertMacroExpansion(
                """
                @DefaultCodable
                struct Foo: Codable {
                    var profile: ProfileSection = .init()
                    var behavior: BehaviorSection = .init()
                }
                """,
                expandedSource: """
                struct Foo: Codable {
                    var profile: ProfileSection = .init()
                    var behavior: BehaviorSection = .init()
                
                    enum CodingKeys: String, CodingKey {
                        case profile
                        case behavior
                    }
                
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.profile = try container.decodeIfPresent(ProfileSection.self, forKey: .profile) ?? .init()
                        self.behavior = try container.decodeIfPresent(BehaviorSection.self, forKey: .behavior) ?? .init()
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
