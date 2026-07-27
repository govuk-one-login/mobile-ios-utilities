public protocol GDSErrorKind: Sendable,
                              CustomStringConvertible,
                              RawRepresentable,
                              Equatable where RawValue == Int {
    var localizedDescription: String { get }
}

extension GDSErrorKind {
    public var localizedDescription: String {
        description
    }
}
