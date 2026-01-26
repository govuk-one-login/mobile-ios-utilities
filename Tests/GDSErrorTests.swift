import Foundation
import Testing
@testable import GDSUtilities

struct GDSErrorTests {
    @Test
    func initialisation() {
        let error = OneLoginError(.accountIntervention)
        #expect(error.line == 8)
        #expect(error.function == "initialisation()")

        #expect((error.errorUserInfo["kind"] as? ErrorKind.OneLogin) == .accountIntervention)
        #expect(error.errorUserInfo["reason"] == nil)
        #expect(error.errorUserInfo["endpoint"] == nil)
        #expect(error.errorUserInfo["errorCode"] == nil)
        #expect((error.errorUserInfo["file"] as? String) == "GDSErrorTests.swift")
        #expect((error.errorUserInfo["function"] as? String) == "initialisation()")
        #expect((error.errorUserInfo["line"] as? Int) == 8)
        #expect((error.errorUserInfo["resolvable"] as? String) == "true")
        #expect(error.errorUserInfo["originalError"] == nil)
        #expect(error.errorUserInfo["originalErrorKind"] == nil)
    }

    @Test
    func originalErrorIsBaseError() {
        let error = GDSError(
            .accountIntervention,
            originalError: ExampleError(.mock1)
        )
        #expect(error.errorUserInfo["originalError"] as? String == "This is a mock error")
        #expect(error.errorUserInfo["originalErrorKind"] as? String == "ExampleErrorKind.mock1")
    }

    @Test
    func originalErrorIsOtherError() {
        let error = GDSError(
            .accountIntervention,
            originalError: NSError(domain: "test", code: 1)
        )
        #expect(error.errorUserInfo["originalError"] as? String == "The operation couldn’t be completed. (test error 1.)")
        #expect(error.errorUserInfo["originalErrorKind"] as? String == "Error Domain=test Code=1 \"(null)\"")
    }

    @Test("Error parameters cannot be overridden by additional parameters")
    func additionParametersPriority() {
        let error = GDSError(
            .accountIntervention,
            reason: "this is the reason",
            additionalParameters: [
                "reason": "additional reason",
                "filesExist": "true"
            ]
        )

        #expect(error.errorUserInfo["reason"] as? String == "this is the reason")
        #expect(error.errorUserInfo["filesExist"] as? String == "true")
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
