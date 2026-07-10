public protocol GDSErrorKind: Sendable,
                              CustomStringConvertible,
                              RawRepresentable,
                              Equatable where RawValue == Int { }
