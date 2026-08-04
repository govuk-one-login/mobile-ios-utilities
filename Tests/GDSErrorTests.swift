// swiftlint:disable file_length
import Foundation
import Testing
@testable import GDSUtilities

// swiftlint:disable type_body_length
struct GDSErrorTests {
    @Test
    func initialisation() {
        let error = ExampleError(.mock1)
        #expect(error.line == 10)
        #expect(error.function == "initialisation()")

        let nsError = error as NSError

        #expect(nsError.domain == ExampleError.errorDomain)
        #expect(nsError.code == error.errorCode)
        #expect(error.errorUserInfo[NSLocalizedFailureReasonErrorKey] == nil)
        #expect(error.errorUserInfo[NSURLErrorKey] == nil)
        #expect(error.errorUserInfo["kind"] as? String == "mock1")
        #expect(error.errorUserInfo["errorCode"] == nil)
        #expect((error.errorUserInfo["file"] as? String) == "GDSErrorTests.swift")
        #expect((error.errorUserInfo["function"] as? String) == "initialisation()")
        #expect((error.errorUserInfo["line"] as? Int) == 10)
        #expect((error.errorUserInfo["resolvable"] as? String) == "false")
        #expect(error.errorUserInfo[NSUnderlyingErrorKey] == nil)
    }

    @Test
    func endpointIsIncludedAsURL() throws {
        let endpoint = "https://example.com/path"
        let error = ExampleError(.mock1, endpoint: endpoint)
        let url = try #require(error.errorUserInfo[NSURLErrorKey] as? URL)
        let nsError = error as NSError

        #expect(error.endpoint == endpoint)
        #expect(url.absoluteString == endpoint)
        #expect(error.errorUserInfo["endpoint"] == nil)
        #expect(nsError.userInfo[NSURLErrorKey] as? URL == url)
    }

    @Test
    func invalidEndpointIsIncludedAsString() {
        let endpoint = "https://exa mple.com"
        let error = ExampleError(.mock1, endpoint: endpoint)

        #expect(error.endpoint == endpoint)
        #expect(error.errorUserInfo[NSURLErrorKey] == nil)
        #expect(error.errorUserInfo["endpoint"] as? String == endpoint)
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
                NSLocalizedDescriptionKey: "additional description",
                NSLocalizedFailureReasonErrorKey: "additional reason",
                "filesExist": "true"
            ]
        )

        #expect(
            error.errorUserInfo[NSLocalizedDescriptionKey] as? String ==
                error.errorDescription
        )
        #expect(
            error.errorUserInfo[NSLocalizedFailureReasonErrorKey] as? String ==
                "this is the reason"
        )
        #expect(error.errorUserInfo["filesExist"] as? String == "true")
        #expect(error == ExampleError(.mock1))
    }

    @Test
    func error_reason() {
        #expect(ExampleError(.mock1, reason: "This is a mock error").reason == "This is a mock error")
    }

    @Test
    func error_failureReason() {
        let reason = "This is a mock error"
        let error = ExampleError(.mock1, reason: reason)
        let nsError = error as NSError

        #expect(error.failureReason == reason)
        #expect(error.errorUserInfo[NSLocalizedFailureReasonErrorKey] as? String == reason)
        #expect(nsError.localizedFailureReason == reason)
        #expect(nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String == reason)
    }

    @Test
    func errorUserInfoUsesFailureReasonWitness() {
        let error = OverriddenFailureReasonError()
        let nsError = error as NSError

        #expect(error.reason == "Original reason")
        #expect(error.failureReason == "Localized failure reason")
        #expect(
            error.errorUserInfo[NSLocalizedFailureReasonErrorKey] as? String ==
                error.failureReason
        )
        #expect(nsError.localizedFailureReason == error.failureReason)
        #expect(
            nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ==
                error.failureReason
        )
    }

    @Test
    func missingFailureReasonCannotBeInjectedByAdditionalParameters() {
        let error = MissingDescriptionError()
        let nsError = error as NSError

        #expect(error.failureReason == nil)
        #expect(error.errorUserInfo[NSLocalizedFailureReasonErrorKey] == nil)
        #expect(nsError.userInfo[NSLocalizedFailureReasonErrorKey] == nil)
    }

    @Test
    func error_errorCode() {
        #expect(ExampleError(.mock1).errorCode == 1)
    }

    @Test
    func error_reflectingDescription() {
        #expect(
            String(reflecting: ExampleError(.mock1)) ==
                "Error Domain=GDSExampleErrorKind Code=1 \"This is a mock error\""
        )
    }

    @Test
    func error_hash() {
        #expect(ExampleError(.mock1, statusCode: 400).hash == "811ce6bfad80ed8a9ff40934ea60241d")
    }

    @Test
    func error_localizedDescription() {
        let error = ExampleError(.mock1, statusCode: 400)
        let nsError = error as NSError

        #expect(error.errorDescription == "This is a mock error")
        #expect(error.localizedDescription == error.errorDescription)
        #expect(
            error.errorUserInfo[NSLocalizedDescriptionKey] as? String ==
                error.errorDescription
        )
        #expect(nsError.localizedDescription == error.errorDescription)
        #expect(
            nsError.userInfo[NSLocalizedDescriptionKey] as? String ==
                error.errorDescription
        )
    }

    @Test
    func missingErrorDescriptionIsNotIncludedInUserInfo() {
        let error = MissingDescriptionError()
        let nsError = error as NSError
        let expectedDebugDescription =
            "Error Domain=GDSExampleErrorKind Code=1 \"(null)\""

        #expect(error.errorDescription == nil)
        #expect(error.errorUserInfo[NSLocalizedDescriptionKey] == nil)
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] == nil)
        #expect(error.debugDescription == expectedDebugDescription)
        #expect(String(reflecting: error) == expectedDebugDescription)
        #expect(String(reflecting: nsError) == expectedDebugDescription)
    }

    @Test
    func test_errorKind() {
        #expect(GDSExampleErrorKind.mock1.localizedDescription == "This is a mock error")
        #expect(GDSExampleErrorKind.mock1.description == "mock1 - This is a mock error")
        #expect(DescriptionOnlyErrorKind.mock1.localizedDescription == "mock1")
        #expect(GDSExampleErrorKind.mock1.stringValue == "mock1")
        #expect(GDSExampleErrorKind.mock1.intValue == 1)
        #expect(GDSExampleErrorKind(intValue: 1) == .mock1)
        #expect(GDSExampleErrorKind(stringValue: "mock1") == .mock1)
    }
    
    @Test
    func test_multipleCaseErrorKind() {
        #expect(MultipleCaseErrorKind.mock1.stringValue == "mock1")
        #expect(MultipleCaseErrorKind.mock1.description == "mock1")
        #expect(MultipleCaseErrorKind.mock2.stringValue == "mock2")
        #expect(MultipleCaseErrorKind.mock2.description == "mock2")
        #expect(MultipleCaseErrorKind.mock3.stringValue == "mock3")
        #expect(MultipleCaseErrorKind.mock3.description == "mock3")
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

        #expect(
            String(reflecting: error) ==
                "Error Domain=GDSExampleErrorKind Code=1 \"This is a mock error\""
        )
    }

    @Test
    func test_nonGDSError_debugDescription() {
        let anyDebugDescription = "any"
        let nonGDSError = ErrorStub(_debugDescription: anyDebugDescription)

        let error = ExampleError(
            .mock1,
            originalError: nonGDSError
        )

        #expect(
            String(reflecting: error) ==
                "Error Domain=GDSExampleErrorKind Code=1 \"This is a mock error\""
        )
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

        #expect(
            String(reflecting: error) ==
                "Error Domain=GDSExampleErrorKind Code=1 \"This is a mock error\""
        )
    }
}
// swiftlint:enable type_body_length

typealias ExampleError = GDSExampleError<GDSExampleErrorKind>

enum MultipleCaseErrorKind: Int, GDSErrorKind {
    case mock1 = 1
    case mock2 = 2
    case mock3 = 3
}

enum GDSExampleErrorKind: Int, GDSErrorKind {
    case mock1 = 1

    var description: String {
        "mock1 - This is a mock error"
    }

    var localizedDescription: String {
        "This is a mock error"
    }
}

private enum DescriptionOnlyErrorKind: Int, GDSErrorKind {
    case mock1 = 1

    var description: String {
        "mock1"
    }
}

private struct MissingDescriptionError: GDSError {
    let kind: GDSExampleErrorKind = .mock1
    let reason: String? = nil
    let endpoint: String? = nil
    let statusCode: Int? = nil
    let file = "GDSErrorTests.swift"
    let function = "missingErrorDescriptionIsNotIncludedInUserInfo()"
    let line = 1
    let resolvable = false
    let originalError: (any Error)? = nil
    let additionalParameters: [String: any Sendable] = [
        NSLocalizedDescriptionKey: "Additional description",
        NSLocalizedFailureReasonErrorKey: "Additional failure reason"
    ]

    var errorDescription: String? {
        nil
    }
}

private struct OverriddenFailureReasonError: GDSError {
    let kind: GDSExampleErrorKind = .mock1
    let reason: String? = "Original reason"
    let endpoint: String? = nil
    let statusCode: Int? = nil
    let file = "GDSErrorTests.swift"
    let function = "errorUserInfoUsesFailureReasonWitness()"
    let line = 1
    let resolvable = false
    let originalError: (any Error)? = nil
    let additionalParameters: [String: any Sendable] = [:]

    var failureReason: String? {
        "Localized failure reason"
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
    let errorUserInfo: [String: Sendable] = [:]
}
