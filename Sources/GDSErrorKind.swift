/// Implement a ``GDSErrorKind`` to create an ``Error`` type that requires:
///
/// * An associated domain;
/// * A code for that domain;
///
/// An example of ``GDSErrorKind`` type:
///
///     ```
///     enum FooErrorKind: Int, GDSErrorKind {
///     case one = 1
///     case two = 2
///     case three = 3
///     }
///     ```
///
/// By using an `enum` you can get the following for free:
/// * Guaranteed unique error codes that you can scope under a domain
/// * A short error description that resolves to the enum case (e.g. "one", "two", "three") and can be used as an identifier (i.e. key)
///
///
/// - SeeAlso ``rawValue`` to return a unique `Int` identifier
/// - SeeAlso: ``stringValue`` to return a unique `String` identifier
/// - SeeAlso: ``description`` to provide a text representation to be used when converting an instance to a string
/// - SeeAlso: ``localizedDescription-4e2z0`` to provide a "user" facing localised description
///     (e.g. when a user needs a text description of the error)
/// - SeeAlso: ``GDSError`` on how both the domain the error code of an error are derived by ``GDSErrorKind``
/// - Remark: It is your responsibility to ensure that the name of your type (i.e. the domain) is unique across
/// the errors reported as well as each of the error codes.
public protocol GDSErrorKind: Sendable,
                              CustomStringConvertible,
                              RawRepresentable,
                              CodingKey,
                              Equatable where RawValue == Int {
    
    /// A string containing the localised description of the error.; evaluates to``description`` by default.
    ///
    /// This string is meant to be "user" facing thus localised.
    /// Who the target user (i.e. audience) may vary per error.
    ///
    /// Override this property to specify a custom description.
    var localizedDescription: String { get }
}

extension GDSErrorKind {

    public var localizedDescription: String {
        description
    }

    public var description: String {
        self.stringValue
    }
}
