import CryptoKit
import Foundation

public protocol GDSError:
    Equatable,
    CustomNSError,
    CustomDebugStringConvertible,
    LocalizedError
    where Kind: GDSErrorKind {
    associatedtype Kind
    var kind: Kind { get }
    var reason: String? { get }
    var endpoint: String? { get }
    var statusCode: Int? { get }
    var file: String { get }
    var function: String { get }
    var line: Int { get }
    var resolvable: Bool { get }
    var originalError: (any Error)? { get }
    var additionalParameters: [String: any Sendable] { get }
}

extension GDSError {
    public var hash: String? {
        var string: String = ""
        if let statusCode {
            string += String(statusCode)
        }
        string += "_\(endpoint ?? file)"
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

/// Implementation for `Equatable` and pattern matching
extension GDSError {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
    }

    public static func ~= (rhs: Self, lhs: Error) -> Bool {
        (lhs as? Self) == rhs
    }
}

/// CustomNSError properties
extension GDSError {
    public static var errorDomain: String {
        String(describing: self.Kind)
    }

    public var errorUserInfo: [String: Any] {
        let params: [String: Any?] = [
            "kind": self.kind,
            "endpoint": self.endpoint,
            "statusCode": self.statusCode,
            "file": self.file.components(separatedBy: "/").last,
            "function": self.function,
            "line": self.line,
            "resolvable": String(self.resolvable),
            NSUnderlyingErrorKey: self.originalError,
            NSLocalizedDescriptionKey: self.errorDescription,
            NSLocalizedFailureReasonErrorKey: self.failureReason
        ]

        let paramsToLog = params.merging(additionalParameters) { lhs, _ in
            lhs
        }

        return paramsToLog.compactMapValues { $0 }
    }

    public var errorCode: Int {
        self.kind.rawValue
    }
}

/// Error description properties
extension GDSError {
    public var debugDescription: String {
        let localizedDescription = errorDescription ?? "(null)"

        return "Error Domain=\(Self.errorDomain) Code=\(errorCode) \"\(localizedDescription)\""
    }

    public var errorDescription: String? {
        kind.localizedDescription
    }

    public var failureReason: String? {
        reason
    }
}
