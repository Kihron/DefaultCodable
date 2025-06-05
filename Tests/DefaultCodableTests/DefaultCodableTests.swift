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

    func testLiteralTypeInference() throws {
        #if canImport(DefaultCodableMacros)
            assertMacroExpansion(
                """
                @DefaultCodable
                struct Foo: Codable {
                    var flag = true
                    var count = 5
                    var ratio = 1.5
                    var message = "hi"
                }
                """,
                expandedSource: """
                struct Foo: Codable {
                    var flag = true
                    var count = 5
                    var ratio = 1.5
                    var message = "hi"

                    enum CodingKeys: String, CodingKey {
                        case flag
                        case count
                        case ratio
                        case message
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.flag = try container.decodeIfPresent(Bool.self, forKey: .flag) ?? true
                        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 5
                        self.ratio = try container.decodeIfPresent(Double.self, forKey: .ratio) ?? 1.5
                        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? "hi"
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitTypeAnnotations() throws {
        #if canImport(DefaultCodableMacros)
            assertMacroExpansion(
                """
                @DefaultCodable
                struct Foo: Codable {
                    var numbers: [Int] = [1, 2, 3]
                    var mapping: [String: Int] = [:]
                }
                """,
                expandedSource: """
                struct Foo: Codable {
                    var numbers: [Int] = [1, 2, 3]
                    var mapping: [String: Int] = [:]

                    enum CodingKeys: String, CodingKey {
                        case numbers
                        case mapping
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.numbers = try container.decodeIfPresent([Int].self, forKey: .numbers) ?? [1, 2, 3]
                        self.mapping = try container.decodeIfPresent([String: Int].self, forKey: .mapping) ?? [:]
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testObservedProperty() throws {
        #if canImport(DefaultCodableMacros)
            assertMacroExpansion(
                """
                @DefaultCodable
                struct Foo: Codable {
                    var value = 0 {
                        didSet { print("changed") }
                    }
                }
                """,
                expandedSource: """
                struct Foo: Codable {
                    var value = 0 {
                        didSet { print("changed") }
                    }

                    enum CodingKeys: String, CodingKey {
                        case value
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decodeIfPresent(Int.self, forKey: .value) ?? 0
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
