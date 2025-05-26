// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(CodingKeys), named(init))
public macro DefaultCodable() = #externalMacro(module: "DefaultCodableMacros", type: "DefaultCodable")
