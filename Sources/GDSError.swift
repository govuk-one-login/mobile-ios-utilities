import CryptoKit
import Foundation

/// A `GDSError` type is a Swift `Error` implementation that closely mirrors an `NSError` type.
///
/// Specifically, a `GDSError`:
/// * has an associated `domain` and a `code` as a stable identity when used in Objective-C.
/// * makes use of standardised user info keys to pass associated data for better interopability.
/// * matches the debug description of `NSError` for easier diagnostics.
///
/// All the above make `GDSError` a good candidate where `NSError` is expected. e.g. when logging analytics
/// via Firebase[1].
///
/// `GDSError` is therefore meant to be used whenever certain behavioral traits (e.g. like the domain and code
/// offered by the `CustomNSError` protocol) are required and/or expected [2].
/// It's worth noting that even though "every type that conforms to the Error protocol is implicitly bridged to
/// "NSError", this does not automagically bring domain, code and other `NSError` type functionality over. These
/// are opt in via the adoption of NSError related protocols.
///
/// `GDSError` is therefore meant to be used whenever certain behavioral traits (e.g. like the domain and code
/// offered by the `CustomNSError` protocol) are required and/or expected [2].
///
/// Conform to  `GDSError` when you need to:
/// * Make use of `typed` errors
/// * Bridge to `NSError` when you require a domain/error code
///
/// [1]: Crashlytics uses the domain, the error code, and other platform or error type characteristics to group events
/// (e.g. errors) into issues.
/// [2]: The main use case for adopting `GDSError` is in case your code uses a service like `Crashlytics` to
/// log errors. Another use case is when interacting with Objective-C where `NSError` instances are typically
/// expected to have an associated domain and code.
///
/// - SeeAlso: https://developer.apple.com/documentation/foundation/nserror/userinfokey
/// // swiftlint:disable line_length
/// - SeeAlso: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0112-nserror-bridging.md
/// // swiftlint:enable line_length
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

    /// You should not rely on any of the contents `userInfo`  `NSError` type other than the keys supported by
    /// `NSError` like:
    ///
    /// * `NSUnderlyingErrorKey` which holds the underlying error, if presnet
    /// * `NSLocalizedDescriptionKey` a localised string representation of the error that, if present,
    /// will be returned by ``localizedDescription``.
    /// * `NSLocalizedFailureReasonErrorKey` for localised string representation containing the reason for
    /// the failure that, if present, will be returned by ``localizedFailureReason``.
    ///
    /// Any other observes `keys` and types of `values` are subject to change and not considered part of
    /// `GDSError` public contract. Including removed and/or have their value types change over time.
    public var errorUserInfo: [String: Any] {
        var params: [String: Any?] = [
            "kind": self.kind.stringValue,
            "statusCode": self.statusCode,
            "file": self.file.components(separatedBy: "/").last,
            "function": self.function,
            "line": self.line,
            "resolvable": String(self.resolvable),
            NSUnderlyingErrorKey: self.originalError,
            NSLocalizedDescriptionKey: self.errorDescription,
            NSLocalizedFailureReasonErrorKey: self.failureReason
        ]

        if let endpoint {
            if let url = URL(string: endpoint) {
                params[NSURLErrorKey] = url
            } else {
                params["endpoint"] = endpoint
            }
        }

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
        localizedDescription
    }

    @available(*, deprecated, message: "Use #errorDescription()")
    public var localizedDescription: String {
        kind.localizedDescription
    }

    public var failureReason: String? {
        reason
    }
}
