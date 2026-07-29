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
import KeylessSDK
@testable import PingRecognize
import PingJourneyPlugin

// MARK: - RecognizeErrorTests

final class RecognizeErrorTests: XCTestCase {

    func testInitStoresMessage() {
        let error = RecognizeError("something went wrong", code: 30000)
        XCTAssertEqual(error.message, "something went wrong")
        XCTAssertEqual(error.code, 30000)
    }

    func testErrorDescriptionMatchesMessage() {
        let error = RecognizeError("network timeout", code: 30005)
        XCTAssertEqual(error.errorDescription, "network timeout")
    }

    func testEmptyMessageIsAllowed() {
        let error = RecognizeError("", code: 0)
        XCTAssertEqual(error.message, "")
        XCTAssertEqual(error.errorDescription, "")
    }

    func testConformsToLocalizedError() {
        let error: LocalizedError = RecognizeError("test", code: 0)
        XCTAssertEqual(error.errorDescription, "test")
    }
}

// MARK: - RecognizeMobileSDKOptionsTests + RecognizeCallbackConstantsTests

final class RecognizeMobileSDKOptionsTests: XCTestCase {

    // MARK: Boolean computed properties

    func testBoolTrueReturnsTrueForExactString() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.livenessEnvironmentAware: "true",
            JourneyConstants.showSuccessFeedback: "true",
            JourneyConstants.showFailureFeedback: "true",
            JourneyConstants.showInstructionsScreen: "true",
        ])
        XCTAssertEqual(opts.livenessEnvironmentAware, true)
        XCTAssertEqual(opts.showSuccessFeedback, true)
        XCTAssertEqual(opts.showFailureFeedback, true)
        XCTAssertEqual(opts.showInstructionsScreen, true)
    }

    func testBoolFalseWhenKeyAbsent() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertNil(opts.livenessEnvironmentAware)
        XCTAssertNil(opts.showSuccessFeedback)
        XCTAssertNil(opts.showFailureFeedback)
        XCTAssertNil(opts.showInstructionsScreen)
    }

    func testBoolFalseForNonTrueString() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.livenessEnvironmentAware: "false",
            JourneyConstants.showSuccessFeedback: "false"
        ])
        XCTAssertEqual(opts.livenessEnvironmentAware, false)
        XCTAssertEqual(opts.showSuccessFeedback, false)
    }

    func testBoolFalseWhenExplicitlySetToFalse() {
        let opts = RecognizeMobileSDKOptions(raw: [
            JourneyConstants.showSuccessFeedback: "false",
            JourneyConstants.showFailureFeedback: "false",
            JourneyConstants.showInstructionsScreen: "false"
        ])
        XCTAssertEqual(opts.showSuccessFeedback, false)
        XCTAssertEqual(opts.showFailureFeedback, false)
        XCTAssertEqual(opts.showInstructionsScreen, false)
    }

    // MARK: Integer coercion

    func testCameraDelaySecondsValidInt() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.cameraDelaySeconds: "3"])
        XCTAssertEqual(opts.cameraDelaySeconds, 3)
    }

    func testCameraDelaySecondsAbsentReturnsNil() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertNil(opts.cameraDelaySeconds)
    }

    func testCameraDelaySecondsNonNumericReturnsNil() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.cameraDelaySeconds: "abc"])
        XCTAssertNil(opts.cameraDelaySeconds)
    }

    func testNumberOfEnrollmentCircuitsValidInt() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.numberOfEnrollmentCircuits: "7"])
        XCTAssertEqual(opts.numberOfEnrollmentCircuits, 7)
    }

    func testNumberOfEnrollmentCircuitsAbsentReturnsNil() {
        let opts = RecognizeMobileSDKOptions(raw: [:])
        XCTAssertNil(opts.numberOfEnrollmentCircuits)
    }

    func testNumberOfEnrollmentCircuitsNonNumericReturnsNil() {
        let opts = RecognizeMobileSDKOptions(raw: [JourneyConstants.numberOfEnrollmentCircuits: "nope"])
        XCTAssertNil(opts.numberOfEnrollmentCircuits)
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

    func testInitValueGenerateClientStateString() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.generateClientState, value: "true")
        XCTAssertTrue(callback.generateClientState)
    }

    func testInitValueGenerateClientStateBoolTrue() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.generateClientState, value: true)
        XCTAssertTrue(callback.generateClientState)
    }

    func testInitValueGenerateClientStateBoolFalse() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.generateClientState, value: false)
        XCTAssertFalse(callback.generateClientState)
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
            JourneyConstants.livenessEnvironmentAware: "true"
        ]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: raw)
        XCTAssertEqual(callback.mobileSDKOptions.livenessConfiguration, "LEVEL_1")
        XCTAssertEqual(callback.mobileSDKOptions.livenessEnvironmentAware, true)
    }

    func testInitValueMobileSDKOptionsNonStringValuesCoerced() {
        let callback = RecognizeCallback()
        let raw: [String: Any] = [JourneyConstants.cameraDelaySeconds: 4]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: raw)
        // The value 4 is coerced to "4" via string interpolation; Int("4") == 4
        XCTAssertEqual(callback.mobileSDKOptions.cameraDelaySeconds, 4)
    }

    func testInitValueMobileSDKOptionsEmptyDictProducesNilForOptionals() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: [String: Any]())
        XCTAssertNil(callback.mobileSDKOptions.livenessEnvironmentAware)
        XCTAssertNil(callback.mobileSDKOptions.cameraDelaySeconds)
        XCTAssertNil(callback.mobileSDKOptions.numberOfEnrollmentCircuits)
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

// MARK: - RecognizeCallbackInputSetterTests

final class RecognizeCallbackInputSetterTests: XCTestCase {

    /// Builds a RecognizeCallback whose `json` already contains an `input` array
    /// with all six Recognize input keys — mirrors what the Journey framework delivers.
    private func makeCallback() async -> RecognizeCallback {
        let inputKeys = [
            JourneyConstants.inputSignedJwt,
            JourneyConstants.inputClientState,
            JourneyConstants.inputRecognizeId,
            JourneyConstants.inputDevicePublicSigningKey,
            JourneyConstants.inputClientError,
            JourneyConstants.inputClientErrorCode
        ]
        let inputArray = inputKeys.map { ["name": $0, "value": ""] }
        let json: [String: Any] = ["input": inputArray, "output": [], "type": "PingOneRecognizeCallback"]
        let callback = RecognizeCallback()
        _ = await callback.initialize(with: json)
        return callback
    }

    private func inputValue(for key: String, in callback: RecognizeCallback) -> String? {
        guard let inputs = callback.json["input"] as? [[String: Any]] else { return nil }
        return inputs.first(where: { ($0["name"] as? String) == key })?["value"] as? String
    }

    func testSetSignedJwt() async {
        let callback = await makeCallback()
        callback.setSignedJwt("jwt-token-xyz")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputSignedJwt, in: callback), "jwt-token-xyz")
    }

    func testSetClientState() async {
        let callback = await makeCallback()
        callback.setClientState("state-blob")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputClientState, in: callback), "state-blob")
    }

    func testSetRecognizeId() async {
        let callback = await makeCallback()
        callback.setRecognizeId("recognize-id-001")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputRecognizeId, in: callback), "recognize-id-001")
    }

    func testSetDevicePublicSigningKey() async {
        let callback = await makeCallback()
        callback.setDevicePublicSigningKey("public-key-pem")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputDevicePublicSigningKey, in: callback), "public-key-pem")
    }

    func testSetClientErrorCode() async {
        let callback = await makeCallback()
        callback.setClientErrorCode("ERR_001")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputClientErrorCode, in: callback), "ERR_001")
    }

    func testErrorHelper() async {
        let callback = await makeCallback()
        callback.error("something went wrong")
        XCTAssertEqual(inputValue(for: JourneyConstants.inputClientError, in: callback), "something went wrong")
    }
}

// MARK: - StringDictionaryTests

final class StringDictionaryTests: XCTestCase {

    func testStringStringDictPassthroughUnchanged() {
        let callback = RecognizeCallback()
        let input: [String: Any] = ["key1": "value1", "key2": "value2"]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: input)
        XCTAssertEqual(callback.mobileSDKOptions.operationInfoId, "")
        XCTAssertEqual(callback.mobileSDKOptions.livenessConfiguration, "")
    }

    func testStringAnyDictWithNonStringValuesCoerced() {
        let callback = RecognizeCallback()
        let input: [String: Any] = [
            JourneyConstants.cameraDelaySeconds: 3,
            JourneyConstants.numberOfEnrollmentCircuits: 7
        ]
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: input)
        XCTAssertEqual(callback.mobileSDKOptions.cameraDelaySeconds, 3)
        XCTAssertEqual(callback.mobileSDKOptions.numberOfEnrollmentCircuits, 7)
    }

    func testNonDictValueProducesEmptyOptions() {
        let callback = RecognizeCallback()
        callback.initValue(name: JourneyConstants.mobileSDKOptions, value: "not-a-dict")
        XCTAssertNil(callback.mobileSDKOptions.cameraDelaySeconds)
        XCTAssertNil(callback.mobileSDKOptions.numberOfEnrollmentCircuits)
        XCTAssertNil(callback.mobileSDKOptions.livenessEnvironmentAware)
    }
}


// MARK: - EnrollWithClientStateTests

final class EnrollWithClientStateTests: XCTestCase {

    func testClientStateAbsentRoutesToAuthenticateBranch() async {
        let inputKeys = [
            JourneyConstants.inputSignedJwt,
            JourneyConstants.inputClientState,
            JourneyConstants.inputRecognizeId,
            JourneyConstants.inputDevicePublicSigningKey,
            JourneyConstants.inputClientError,
            JourneyConstants.inputClientErrorCode
        ]
        let inputArray = inputKeys.map { ["name": $0, "value": ""] }
        let outputArray: [[String: Any]] = [
            ["name": JourneyConstants.operationType, "value": "AUTHENTICATE"]
        ]
        let json: [String: Any] = [
            "input": inputArray,
            "output": outputArray,
            "type": JourneyConstants.pingOneRecognizeCallback
        ]
        let callback = RecognizeCallback()
        _ = await callback.initialize(with: json)

        XCTAssertEqual(callback.clientState, "")
        XCTAssertEqual(callback.operationType, .authenticate)

        let inputs = callback.json["input"] as? [[String: Any]]
        let recognizeIdValue = inputs?.first(where: { ($0["name"] as? String) == JourneyConstants.inputRecognizeId })?["value"] as? String
        XCTAssertEqual(recognizeIdValue, "")
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
