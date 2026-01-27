// does not conform to `CustomStringConvertable` or `CustomDebugStringConvertable` to avoid infinite loop
public protocol GDSErrorKind: Sendable,
                              RawRepresentable,
                              Equatable where RawValue == String { }

extension GDSErrorKind {
    public var description: String {
        rawValue == "\(self)" ?
            "\(self)" :
            "\(self) - \(rawValue)"
    }
}

extension GDSErrorKind where Self.RawValue == String {
    public var localizedDescription: String {
        self.rawValue
    }
}
