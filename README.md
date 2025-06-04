# DefaultCodable

DefaultCodable is a Swift package that provides a macro for automatically generating `Codable` conformance for types with default values. The `@DefaultCodable` macro expands to create the required `CodingKeys` enumeration and an initializer that decodes properties while falling back to their declared defaults when keys are missing.

## Features

- Automatically synthesizes a `CodingKeys` enum for all stored properties.
- Generates an `init(from:)` that decodes each property using `decodeIfPresent`, returning to the property's default value when a key is not present.
- Basic type inference from literal initializers for properties that do not specify an explicit type.

## Installation

Add the package to the dependencies of your `Package.swift` file:

```swift
.package(url: "https://github.com/Kihron/DefaultCodable.git", branch: "main")
```

and include `"DefaultCodable"` as a dependency for any target that should use the macro.

## Usage

Import the library and apply `@DefaultCodable` to your `Codable` struct. All stored properties must provide a default value.

```swift
import DefaultCodable

@DefaultCodable
struct Foo: Codable {
    var x = 42
    var y = "hello"
}
```

During macro expansion the type becomes:

```swift
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
```

Any missing values during decoding fall back to the defaults provided in the property declarations.

## Building and Testing

Use `swift build` to compile the package and `swift test` to run the unit tests. These commands require fetching the SwiftSyntax dependency from the network.

```bash
swift build
swift test
```

## Repository Layout

- `Sources/DefaultCodable` – the public macro definition.
- `Sources/DefaultCodableMacros` – implementation of the macro using SwiftSyntax.
- `Sources/DefaultCodableClient` – small executable target that demonstrates using the package.
- `Tests/DefaultCodableTests` – tests validating macro expansion behavior.

## Contributing

Issues and pull requests are welcome. Feel free to open a discussion for feature requests or questions.

