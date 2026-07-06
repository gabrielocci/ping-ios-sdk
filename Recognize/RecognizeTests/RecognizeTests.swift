//
//  RecognizeTests.swift
//  RecognizeTests
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import PingRecognize

// MARK: - RecognizeErrorTests

final class RecognizeErrorTests: XCTestCase {

    func testInitStoresMessage() {
        let error = RecognizeError("something went wrong")
        XCTAssertEqual(error.message, "something went wrong")
    }

    func testErrorDescriptionMatchesMessage() {
        let error = RecognizeError("network timeout")
        XCTAssertEqual(error.errorDescription, "network timeout")
    }

    func testEmptyMessageIsAllowed() {
        let error = RecognizeError("")
        XCTAssertEqual(error.message, "")
        XCTAssertEqual(error.errorDescription, "")
    }

    func testConformsToLocalizedError() {
        let error: LocalizedError = RecognizeError("test")
        XCTAssertEqual(error.errorDescription, "test")
    }
}

// MARK: - RecognizeMobileSDKOptionsTests + RecognizeCallbackConstantsTests

#if canImport(KeylessSDK)

final class RecognizeMobileSDKOptionsTests: XCTestCase {

    // MARK: Boolean computed properties

    func testBoolTrueReturnsTrueForExactString() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.livenessEnvironmentAware: JourneyConstants.boolTrue,
            JourneyConstants.showSuccessFeedback: JourneyConstants.boolTrue,
            JourneyConstants.shouldRetrieveEnrollmentFrame: JourneyConstants.boolTrue,
            JourneyConstants.showFailureFeedback: JourneyConstants.boolTrue,
            JourneyConstants.showInstructionsScreen: JourneyConstants.boolTrue,
            JourneyConstants.shouldRetrieveSecret: JourneyConstants.boolTrue,
            JourneyConstants.shouldDeleteSecret: JourneyConstants.boolTrue,
            JourneyConstants.shouldRetrieveAuthenticationFrame: JourneyConstants.boolTrue,
            JourneyConstants.shouldRemovePin: JourneyConstants.boolTrue
        ])
        XCTAssertTrue(opts.livenessEnvironmentAware)
        XCTAssertTrue(opts.showSuccessFeedback)
        XCTAssertTrue(opts.shouldRetrieveEnrollmentFrame)
        XCTAssertTrue(opts.showFailureFeedback)
        XCTAssertTrue(opts.showInstructionsScreen)
        XCTAssertTrue(opts.shouldRetrieveSecret)
        XCTAssertTrue(opts.shouldDeleteSecret)
        XCTAssertTrue(opts.shouldRetrieveAuthenticationFrame)
        XCTAssertTrue(opts.shouldRemovePin)
    }

    func testBoolFalseWhenKeyAbsent() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertFalse(opts.livenessEnvironmentAware)
        XCTAssertFalse(opts.showSuccessFeedback)
        XCTAssertFalse(opts.shouldRetrieveEnrollmentFrame)
        XCTAssertFalse(opts.showFailureFeedback)
        XCTAssertFalse(opts.showInstructionsScreen)
        XCTAssertFalse(opts.shouldRetrieveSecret)
        XCTAssertFalse(opts.shouldDeleteSecret)
        XCTAssertFalse(opts.shouldRetrieveAuthenticationFrame)
        XCTAssertFalse(opts.shouldRemovePin)
    }

    func testBoolFalseForNonTrueString() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.livenessEnvironmentAware: "false",
            JourneyConstants.showSuccessFeedback: "1",
            JourneyConstants.shouldRemovePin: "TRUE"   // case-sensitive — must be lowercase "true"
        ])
        XCTAssertFalse(opts.livenessEnvironmentAware)
        XCTAssertFalse(opts.showSuccessFeedback)
        XCTAssertFalse(opts.shouldRemovePin)
    }

    // MARK: Integer coercion

    func testCameraDelaySecondsValidInt() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.cameraDelaySeconds: "3"])
        XCTAssertEqual(opts.cameraDelaySeconds, 3)
    }

    func testCameraDelaySecondsEmptyStringDefaultsToZero() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertEqual(opts.cameraDelaySeconds, 0)
    }

    func testCameraDelaySecondsNonNumericDefaultsToZero() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.cameraDelaySeconds: "abc"])
        XCTAssertEqual(opts.cameraDelaySeconds, 0)
    }

    func testNumberOfEnrollmentCircuitsValidInt() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.numberOfEnrollmentCircuits: "7"])
        XCTAssertEqual(opts.numberOfEnrollmentCircuits, 7)
    }

    func testNumberOfEnrollmentCircuitsAbsentDefaultsFiveViaConstant() {
        // JourneyConstants.defaultNumberOfEnrollmentCircuits == "5"
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertEqual(opts.numberOfEnrollmentCircuits, 5)
    }

    func testNumberOfEnrollmentCircuitsNonNumericDefaultsFive() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.numberOfEnrollmentCircuits: "nope"])
        XCTAssertEqual(opts.numberOfEnrollmentCircuits, 5)
    }

    // MARK: String properties

    func testStringPropertiesPresentReturnsValue() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.livenessConfiguration: "LEVEL_2",
            JourneyConstants.operationInfoId: "op-id-123",
            JourneyConstants.operationInfoPayload: "payload-abc",
            JourneyConstants.operationInfoExternalUserId: "user-xyz",
            JourneyConstants.customSecret: "secret-value",
            JourneyConstants.presentation: "OVERLAY",
            JourneyConstants.presentationStyle: "CAMERA_PREVIEW"
        ])
        XCTAssertEqual(opts.livenessConfiguration, "LEVEL_2")
        XCTAssertEqual(opts.operationInfoId, "op-id-123")
        XCTAssertEqual(opts.operationInfoPayload, "payload-abc")
        XCTAssertEqual(opts.operationInfoExternalUserId, "user-xyz")
        XCTAssertEqual(opts.customSecret, "secret-value")
        XCTAssertEqual(opts.presentation, "OVERLAY")
        XCTAssertEqual(opts.presentationStyle, "CAMERA_PREVIEW")
    }

    func testStringPropertiesAbsentReturnEmptyString() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertEqual(opts.livenessConfiguration, "")
        XCTAssertEqual(opts.operationInfoId, "")
        XCTAssertEqual(opts.operationInfoPayload, "")
        XCTAssertEqual(opts.operationInfoExternalUserId, "")
        XCTAssertEqual(opts.customSecret, "")
        XCTAssertEqual(opts.presentation, "")
        XCTAssertEqual(opts.presentationStyle, "")
    }
}

// MARK: - RecognizeCallbackInitValueTests

final class RecognizeCallbackInitValueTests: XCTestCase {

    // MARK: operationType

    func testInitValueOperationTypeEnroll() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.operationType, value: "ENROLL")
        XCTAssertEqual(callback.operationType, .enroll)
    }

    func testInitValueOperationTypeAuthenticate() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.operationType, value: "AUTHENTICATE")
        XCTAssertEqual(callback.operationType, .authenticate)
    }

    func testInitValueOperationTypeUnknownDefaultsToEnroll() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.operationType, value: "UNKNOWN")
        XCTAssertEqual(callback.operationType, .enroll)
    }

    // MARK: String output fields

    func testInitValueWebsocketURL() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.websocketURL, value: "wss://example.com/ws")
        XCTAssertEqual(callback.websocketURL, "wss://example.com/ws")
    }

    func testInitValueCustomerName() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.customerName, value: "Acme Corp")
        XCTAssertEqual(callback.customerName, "Acme Corp")
    }

    func testInitValueImageEncryptionPublicKey() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.imageEncryptionPublicKey, value: "MFwwDQYJ")
        XCTAssertEqual(callback.imageEncryptionPublicKey, "MFwwDQYJ")
    }

    func testInitValueImageEncryptionKeyId() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.imageEncryptionKeyId, value: "key-id-007")
        XCTAssertEqual(callback.imageEncryptionKeyId, "key-id-007")
    }

    func testInitValueHost() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.host, value: "https://recognize.ping.com")
        XCTAssertEqual(callback.host, "https://recognize.ping.com")
    }

    func testInitValueApiKey() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.apiKey, value: "api-key-abc")
        XCTAssertEqual(callback.apiKey, "api-key-abc")
    }

    func testInitValueUsername() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.username, value: "testuser")
        XCTAssertEqual(callback.username, "testuser")
    }

    func testInitValueTransactionData() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.transactionData, value: "tx-data-payload")
        XCTAssertEqual(callback.transactionData, "tx-data-payload")
    }

    func testInitValueGenerateClientState() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.generateClientState, value: "true")
        XCTAssertEqual(callback.generateClientState, "true")
    }

    func testInitValueClientState() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.clientState, value: "client-state-blob")
        XCTAssertEqual(callback.clientState, "client-state-blob")
    }

    // MARK: mobileSDKOptions

    func testInitValueMobileSDKOptionsStringDict() {
        let callback = RecognizeCallback()
        let raw: [String: Any] = [
            JourneyConstants.livenessConfiguration: "LEVEL_1",
            JourneyConstants.livenessEnvironmentAware: JourneyConstants.boolTrue
        ]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: raw)
        XCTAssertEqual(callback.mobileSDKOptions.livenessConfiguration, "LEVEL_1")
        XCTAssertTrue(callback.mobileSDKOptions.livenessEnvironmentAware)
    }

    func testInitValueMobileSDKOptionsNonStringValuesCoerced() {
        let callback = RecognizeCallback()
        let raw: [String: Any] = [JourneyConstants.cameraDelaySeconds: 4]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: raw)
        // The value 4 is coerced to "4" via string interpolation; Int("4") == 4
        XCTAssertEqual(callback.mobileSDKOptions.cameraDelaySeconds, 4)
    }

    func testInitValueMobileSDKOptionsEmptyDictProducesDefaults() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: [String: Any]())
        XCTAssertFalse(callback.mobileSDKOptions.livenessEnvironmentAware)
        XCTAssertEqual(callback.mobileSDKOptions.cameraDelaySeconds, 0)
        XCTAssertEqual(callback.mobileSDKOptions.numberOfEnrollmentCircuits, 5)
    }

    func testInitValueUnknownKeyIsIgnored() {
        let callback = RecognizeCallback()
        // Should not crash; all properties retain their defaults.
        callback.initValue(name: "unknownOutputField", value: "irrelevant")
        XCTAssertEqual(callback.operationType, .enroll)
        XCTAssertEqual(callback.websocketURL, "")
    }

    func testInitValueWrongTypeForStringFieldIsIgnored() {
        let callback = RecognizeCallback()
        // Passing a non-String for a string field — the guard `value as? String` should fail silently.
        callback.initValue(name: JourneyConstants.websocketURL, value: 42)
        XCTAssertEqual(callback.websocketURL, "")
    }
}

// MARK: - JourneyConstantsRecognizeTests

final class JourneyConstantsRecognizeTests: XCTestCase {

    func testPingOneRecognizeCallbackConstant() {
        XCTAssertEqual(JourneyConstants.pingOneRecognizeCallback, "PingOneRecognizeCallback")
    }

    func testInputFieldKeyConstants() {
        XCTAssertEqual(JourneyConstants.inputSignedJwt, "IDToken1signedJwt")
        XCTAssertEqual(JourneyConstants.inputClientState, "IDToken1clientState")
        XCTAssertEqual(JourneyConstants.inputRecognizeId, "IDToken1recognizeId")
        XCTAssertEqual(JourneyConstants.inputDevicePublicSigningKey, "IDToken1devicePublicSigningKey")
        XCTAssertEqual(JourneyConstants.inputClientError, "IDToken1clientError")
        XCTAssertEqual(JourneyConstants.inputClientErrorCode, "IDToken1clientErrorCode")
    }

    func testBoolTrueConstant() {
        XCTAssertEqual(JourneyConstants.boolTrue, "true")
    }

    func testDefaultZeroConstant() {
        XCTAssertEqual(JourneyConstants.defaultZero, "0")
    }

    func testDefaultNumberOfEnrollmentCircuitsConstant() {
        XCTAssertEqual(JourneyConstants.defaultNumberOfEnrollmentCircuits, "5")
    }

    func testClientErrorConstant() {
        XCTAssertEqual(JourneyConstants.clientError, "clientError")
    }

    func testOutputFieldKeyConstants() {
        XCTAssertEqual(JourneyConstants.operationType, "operationType")
        XCTAssertEqual(JourneyConstants.websocketURL, "websocketURL")
        XCTAssertEqual(JourneyConstants.customerName, "customerName")
        XCTAssertEqual(JourneyConstants.imageEncryptionPublicKey, "imageEncryptionPublicKey")
        XCTAssertEqual(JourneyConstants.imageEncryptionKeyId, "imageEncryptionKeyId")
        XCTAssertEqual(JourneyConstants.host, "host")
        XCTAssertEqual(JourneyConstants.apiKey, "apiKey")
        XCTAssertEqual(JourneyConstants.username, "username")
        XCTAssertEqual(JourneyConstants.transactionData, "transactionData")
        XCTAssertEqual(JourneyConstants.generateClientState, "generateClientState")
        XCTAssertEqual(JourneyConstants.clientState, "clientState")
        XCTAssertEqual(JourneyConstants.mobileSDKOptions, "mobileSDKOptions")
    }

    func testMobileSDKOptionKeyTypos() {
        // These two keys carry intentional server-side typos — assert the exact values are preserved.
        XCTAssertEqual(JourneyConstants.shouldRetrieveEnrollmentFrame, "shuoldRetrieveEnrollmentFrame")
        XCTAssertEqual(JourneyConstants.shouldRetrieveAuthenticationFrame, "shouldRetriveAuthenticationFrame")
    }
}

// MARK: - RecognizeOperationTypeTests

final class RecognizeOperationTypeTests: XCTestCase {

    func testRawValueEnroll() {
        XCTAssertEqual(RecognizeOperationType.enroll.rawValue, "ENROLL")
    }

    func testRawValueAuthenticate() {
        XCTAssertEqual(RecognizeOperationType.authenticate.rawValue, "AUTHENTICATE")
    }

    func testInitFromRawValueEnroll() {
        XCTAssertEqual(RecognizeOperationType(rawValue: "ENROLL"), .enroll)
    }

    func testInitFromRawValueAuthenticate() {
        XCTAssertEqual(RecognizeOperationType(rawValue: "AUTHENTICATE"), .authenticate)
    }

    func testInitFromRawValueUnknownReturnsNil() {
        XCTAssertNil(RecognizeOperationType(rawValue: "UNKNOWN"))
    }
}

#endif
