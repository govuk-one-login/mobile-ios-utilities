# mobile-ios-utilities

A Swift Package for shared utilities.

## Installation

To use this GDSUtilities package in a project using Swift Package Manager:

1. Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/govuk-one-login/mobile-ios-utilities", from: "0.0.0"),
```

2. Add any of `GDSUtilities` as a dependency for your target:

```swift
.target(name: "MyTarget", dependencies: [
  .product(name: "GDSUtilities", package: "mobile-ios-utilities")
]),
```

3. Add `GDSUtilities` into your source code where necessary.

## Package description

This package will house a common adoption for errors in the GDS One Login iOS codebases.
This amounts to the `GDSError` and `GDSErrorType` protocols for constructing errors which can exist within a module's codebase or cross module boundaries through the agreed protocol contract.

Consumers should conform types to the protocols to construct errors. The error functionality within this package deliberately does not provide concrete types to avoid regular changes.

## Example implementation

The below example is for where we do not want to create cyclical dependencies but we do want errors to cross module boundaries.

### Top-level app code

```swift
typealias ExampleError = GDSExampleError<GDSExampleErrorKind>

enum GDSExampleErrorKind: String, GDSErrorKind {
    case example1 = "This is an example error"
}

struct GDSExampleError<Kind: GDSErrorKind>: GDSError {
    let kind: Kind
    let reason: String?
    let endpoint: String?
    let statusCode: Int?
    let file: String
    let function: String
    let line: Int
    let resolvable: Bool
    let originalError: (any Error)?
    let additionalParameters: [String: any Sendable]

    init(
        _ kind: Kind,
        reason: String? = nil,
        endpoint: String? = nil,
        statusCode: Int? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        resolvable: Bool = false,
        originalError: (any Error)? = nil,
        additionalParameters: [String: any Sendable] = [:]
    ) {
        self.kind = kind
        self.reason = reason
        self.endpoint = endpoint
        self.statusCode = statusCode
        self.file = file
        self.function = function
        self.line = line
        self.resolvable = resolvable
        self.originalError = originalError
        self.additionalParameters = additionalParameters
    }
}

AppObject {
    func nonTypedThrowingFunction() throws { 
        throw ExampleError(.example1)
    }
    
    func typedThrowingFunction() throws(GDSError) {
        throw ExampleError(.example1)
    }
}
```

### Consumer code

```swift
enum GDSExampleErrorKind: String, GDSErrorKind {
    case example1 = "This is an example error"
}

do {
    try nonTypedThrowingFunction()
} catch let error as GDSError {
    if error.kind.rawValue == GDSExampleErrorKind.example1.rawValue {
        // handle error
    }
}

do {
    try typedThrowingFunction()
} catch where error.kind.rawValue == GDSExampleErrorKind.example1.rawValue {
    // handle error
}
```

N.B.
A typed throw of `GDSError` allows us to bypass casting the error and provides a cleaner syntax, consider this using this functionality creating your APIs.

The above example includes a `GDSExampleErrorKind` in both the top-level app code and the consumer code.
This is to facilitate matching on the error where no shared implementations of `GDSErrorKind` exist in the package, it is required to match the `kind` based on it's `String` `rawValue`; much like the `domain` property of `NSError`.
