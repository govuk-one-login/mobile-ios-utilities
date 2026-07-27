import Foundation
import Testing
@testable import GDSUtilities

struct GDSErrorTests {
    @Test
    func initialisation() {
        let error = ExampleError(.mock1)
        #expect(error.line == 8)
        #expect(error.function == "initialisation()")

        #expect((error.errorUserInfo["kind"] as? GDSExampleErrorKind) == .mock1)
        #expect(error.errorUserInfo["reason"] == nil)
        #expect(error.errorUserInfo["endpoint"] == nil)
        #expect(error.errorUserInfo["errorCode"] == nil)
        #expect((error.errorUserInfo["file"] as? String) == "GDSErrorTests.swift")
        #expect((error.errorUserInfo["function"] as? String) == "initialisation()")
        #expect((error.errorUserInfo["line"] as? Int) == 8)
        #expect((error.errorUserInfo["resolvable"] as? String) == "false")
        #expect(error.errorUserInfo[NSUnderlyingErrorKey] == nil)
    }

    @Test
    func originalNSErrorIsIncludedAsUnderlyingError() throws {
        let originalError = NSError(domain: "test", code: 1)
        let error = ExampleError(.mock1, originalError: originalError)

        let underlyingError = try #require(
            error.errorUserInfo[NSUnderlyingErrorKey] as? NSError
        )

        #expect(underlyingError.localizedDescription == originalError.localizedDescription)
        #expect(String(reflecting: underlyingError) == String(reflecting: originalError))
        #expect(
            underlyingError.localizedDescription ==
                "The operation couldn’t be completed. (test error 1.)"
        )
        #expect(
            String(reflecting: underlyingError) ==
                "Error Domain=test Code=1 \"(null)\""
        )
    }

    @Test
    func missingOriginalErrorCannotBeInjectedByAdditionalParameters() {
        let error = ExampleError(
            .mock1,
            additionalParameters: [
                NSUnderlyingErrorKey: NSError(domain: "additional", code: 1)
            ]
        )

        #expect(error.originalError == nil)
        #expect(error.errorUserInfo[NSUnderlyingErrorKey] == nil)
        #expect((error as NSError).underlyingErrors.isEmpty)
    }

    @Test
    func originalNSErrorFailureReasonIsIncludedInUnderlyingErrorDescription() throws {
        let originalError = NSError(
            domain: "test",
            code: 1,
            userInfo: [
                NSLocalizedFailureReasonErrorKey: "API request error"
            ]
        )
        let error = ExampleError(.mock1, originalError: originalError)

        let underlyingError = try #require(
            error.errorUserInfo[NSUnderlyingErrorKey] as? NSError
        )

        #expect(
            String(reflecting: underlyingError) ==
                """
                Error Domain=test Code=1 "API request error" \
                UserInfo={NSLocalizedFailureReason=API request error}
                """
        )
    }

    @Test
    func customNSErrorIsIncludedAsUnderlyingError() throws {
        let originalError = TestCustomError()
        let error = ExampleError(.mock1, originalError: originalError)

        let underlyingError = try #require(error.errorUserInfo[NSUnderlyingErrorKey] as? NSError)
        #expect(underlyingError.domain == TestCustomError.errorDomain)
        #expect(underlyingError.code == originalError.errorCode)
    }

    @Test
    func originalGDSErrorIsIncludedInTheUnderlyingErrorTree() throws {
        let originalError = ExampleError(.mock1)
        let error = ExampleError(.mock1, originalError: originalError)
        let nsError = error as NSError

        #expect(nsError.underlyingErrors.count == 1)
        let underlyingError = try #require(
            nsError.underlyingErrors.first as? NSError
        )
        #expect(underlyingError.domain == ExampleError.errorDomain)
        #expect(underlyingError.code == originalError.errorCode)
    }

    @Test
    func nestedGDSErrorsFormAnUnderlyingErrorTree() throws {
        let leafError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedFailureReasonErrorKey: "API request error"]
        )
        let middleError = ExampleError(.mock1, originalError: leafError)
        let rootError = ExampleError(.mock1, originalError: middleError)
        let rootNSError = rootError as NSError

        #expect(rootNSError.underlyingErrors.count == 1)
        let middleUnderlyingError = try #require(
            rootNSError.underlyingErrors.first as? NSError
        )
        #expect(middleUnderlyingError.domain == ExampleError.errorDomain)
        #expect(middleUnderlyingError.code == middleError.errorCode)

        #expect(middleUnderlyingError.underlyingErrors.count == 1)
        let leafUnderlyingError = try #require(
            middleUnderlyingError.underlyingErrors.first as? NSError
        )
        #expect(leafUnderlyingError.domain == leafError.domain)
        #expect(leafUnderlyingError.code == leafError.code)
    }

    @Test("Error parameters cannot be overridden by additional parameters")
    func additionParametersPriority() {
        let error = ExampleError(
            .mock1,
            reason: "this is the reason",
            additionalParameters: [
                "reason": "additional reason",
                "filesExist": "true"
            ]
        )

        #expect(error.errorUserInfo["reason"] as? String == "this is the reason")
        #expect(error.errorUserInfo["filesExist"] as? String == "true")
        #expect(error == ExampleError(.mock1))
    }

    @Test
    func error_reason() {
        #expect(ExampleError(.mock1, reason: "This is a mock error").reason == "This is a mock error")
    }

    @Test
    func error_errorCode() {
        #expect(ExampleError(.mock1).errorCode == 1)
    }

    @Test
    func error_reflectingDescription() {
        #expect(String(reflecting: ExampleError(.mock1)) == "mock1 - This is a mock error")
    }

    @Test
    func error_hash() {
        #expect(ExampleError(.mock1, statusCode: 400).hash == "811ce6bfad80ed8a9ff40934ea60241d")
    }

    @Test
    func error_localizedDesecription() {
        #expect(ExampleError(.mock1, statusCode: 400).localizedDescription == "mock1 - This is a mock error")
    }

    @Test
    func test_errorKind() {
        #expect(GDSExampleErrorKind.mock1.localizedDescription == "This is a mock error")
        #expect(GDSExampleErrorKind.mock1.description == "mock1 - This is a mock error")
    }

    @Test
    func test_domain() async throws {
        #expect(ExampleError.errorDomain == "GDSExampleErrorKind")
    }

    @Test
    func test_anyGDSError_debugDescription() {
        let anyGDSError = ExampleError(
            .mock1
        )

        let error = GDSExampleError(
            GDSExampleErrorKind.mock1,
            originalError: anyGDSError
        )

        #expect(String(reflecting: error) == "mock1 - This is a mock error - (mock1 - This is a mock error)")
    }

    @Test
    func test_nonGDSError_debugDescription() {
        let anyDebugDescription = "any"
        let nonGDSError = ErrorStub(_debugDescription: anyDebugDescription)

        let error = ExampleError(
            .mock1,
            originalError: nonGDSError
        )

        #expect(String(reflecting: error) == "mock1 - This is a mock error - (any)")
    }

    @Test
    func test_anyGDSError_with_reason_debugDescription() {
        let anyReason = "any"
        let anyGDSError = ExampleError(
            .mock1,
            reason: anyReason
        )

        let error = ExampleError(
            .mock1,
            originalError: anyGDSError)

        #expect(String(reflecting: error) == "mock1 - This is a mock error - (any)")
    }
}

typealias ExampleError = GDSExampleError<GDSExampleErrorKind>

enum GDSExampleErrorKind: Int, GDSErrorKind {
    case mock1 = 1

    var description: String {
        "mock1 - This is a mock error"
    }

    var localizedDescription: String {
        "This is a mock error"
    }
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

struct ErrorStub: Error, CustomDebugStringConvertible {

    // swiftlint:disable identifier_name
    let _debugDescription: String
    // swiftlint:enable identifier_name

    var debugDescription: String {
        return _debugDescription
    }
}

private struct TestCustomError: Error, CustomNSError {
    static let errorDomain = "uk.gov.one-login.test"
    let errorCode = 1
    let errorUserInfo: [String: Any] = [:]
}
