public struct GDSError<Kind: AnyErrorKind>: BaseError {
    public let kind: Kind
    public let reason: String?
    public let endpoint: String?
    public let statusCode: Int?
    public let file: String
    public let function: String
    public let line: Int
    public let resolvable: Bool
    public let originalError: Error?
    public let additionalParameters: [String: any Sendable]

    public init(
        kind: Kind,
        reason: String?,
        endpoint: String?,
        statusCode: Int?,
        file: String,
        function: String,
        line: Int,
        resolvable: Bool,
        originalError: Error?,
        additionalParameters: [String: any Sendable]
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

extension GDSError where Kind.RawValue == String {
    public var localizedDescription: String {
        kind.rawValue
    }
}

extension AnyErrorKind where Self.RawValue == String {
    public var localizedDescription: String {
        self.rawValue
    }
}

public typealias OneLoginError = GDSError<ErrorKind.OneLogin>

// should be in OL ?
extension OneLoginError where Kind == ErrorKind.OneLogin {
    public init(
        _ kind: ErrorKind.OneLogin,
        reason: String? = nil,
        endpoint: String? = nil,
        statusCode: Int? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        resolvable: Bool = true,
        originalError: Error? = nil,
        additionalParameters: [String: any Sendable] = [:]
    ) {
        self.init(
            kind: kind,
            reason: reason,
            endpoint: endpoint,
            statusCode: statusCode,
            file: file,
            function: function,
            line: line,
            resolvable: resolvable,
            originalError: originalError,
            additionalParameters: additionalParameters
        )
    }
}
