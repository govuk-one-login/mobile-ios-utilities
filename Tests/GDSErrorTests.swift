import Foundation
import Testing
@testable import GDSUtilities

struct GDSErrorTests {
    @Test
    func initialisation() {
        let error = ExampleError(.mock1)
        #expect(error.line == 8)
        #expect(error.function == "initialisation()")

        #expect((error.errorUserInfo["kind"] as? ExampleErrorKind) == .mock1)
        #expect(error.errorUserInfo["reason"] == nil)
        #expect(error.errorUserInfo["endpoint"] == nil)
        #expect(error.errorUserInfo["errorCode"] == nil)
        #expect((error.errorUserInfo["file"] as? String) == "GDSErrorTests.swift")
        #expect((error.errorUserInfo["function"] as? String) == "initialisation()")
        #expect((error.errorUserInfo["line"] as? Int) == 8)
        #expect((error.errorUserInfo["resolvable"] as? String) == "false")
        #expect(error.errorUserInfo["originalError"] == nil)
        #expect(error.errorUserInfo["originalErrorKind"] == nil)
    }

    @Test
    func originalErrorIsOtherError() {
        let error = ExampleError(
            .mock1,
            originalError: NSError(domain: "test", code: 1)
        )
        // swiftlint:disable line_length
        #expect(error.errorUserInfo["originalError"] as? String == "The operation couldn’t be completed. (test error 1.)")
        // swiftlint:enable line_length
        #expect(error.errorUserInfo["originalErrorKind"] as? String == "Error Domain=test Code=1 \"(null)\"")
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
        #expect(ExampleError(.mock1).errorCode == 59)
    }

    @Test
    func error_debugDescription() {
        #expect(ExampleError(.mock1).debugDescription == "This is a mock error")
    }

    @Test
    func error_hash() {
        #expect(ExampleError(.mock1, statusCode: 400).hash == "811ce6bfad80ed8a9ff40934ea60241d")
    }

    @Test
    func error_logToCrashlytics() {
        #expect(ExampleError(.mock1, statusCode: 400).logToCrashlytics == true)
    }

    @Test
    func error_localizedDesecription() {
        #expect(ExampleError(.mock1, statusCode: 400).localizedDescription == "This is a mock error")
    }

    @Test
    func test_errorKind() {
        #expect(ExampleErrorKind.mock1.localizedDescription == "This is a mock error")
        #expect(ExampleErrorKind.mock1.description == "mock1 - This is a mock error")
    }
}

typealias ExampleError = GDSError<ExampleErrorKind>

enum ExampleErrorKind: String, AnyErrorKind {
    case mock1 = "This is a mock error"
}

extension ExampleError {
    init(
        _ kind: ExampleErrorKind,
        reason: String? = nil,
        endpoint: String? = nil,
        statusCode: Int? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        resolvable: Bool = false,
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
