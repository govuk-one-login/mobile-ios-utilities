import CryptoKit
import Foundation

public protocol GDSError:
    Equatable,
    CustomNSError,
    CustomDebugStringConvertible
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
    var originalError: Error? { get }
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
        var originalErrorString: String? = self.originalError?.localizedDescription
        var originalKind: String?

        if let originalError {
            if let original = originalError as? (any GDSError) {
                originalErrorString = original.debugDescription
                originalKind = String(describing: type(of: original.kind)) + "." + String(describing: original.kind)
            } else {
                originalKind = String(describing: originalError)
            }
        }

        let params: [String: Any?] = [
            "kind": self.kind,
            "reason": self.reason,
            "endpoint": self.endpoint,
            "statusCode": self.statusCode,
            "file": self.file.components(separatedBy: "/").last,
            "function": self.function,
            "line": self.line,
            "resolvable": String(self.resolvable),
            "originalErrorKind": originalKind,
            "originalError": originalErrorString
        ]

        let paramsToLog = params.merging(additionalParameters) { lhs, _ in
            lhs
        }

        return paramsToLog.compactMapValues { $0 }
    }

    public var errorCode: Int {
        // NOTE: This is not perfect but will help group errors better.
        statusCode ?? self.line
    }
}

/// CustomDebugStringConvertable properties
extension GDSError {
    public var debugDescription: String {
        var description: String = ""
        description.append(self.reason ?? self.kind.rawValue)

        if let originalError = self.originalError as? any GDSError {
            description.append(" - (\(originalError.debugDescription))")
        }

        return description
    }
}

extension GDSError where Kind.RawValue == String {
    public var localizedDescription: String {
        kind.rawValue
    }
}
