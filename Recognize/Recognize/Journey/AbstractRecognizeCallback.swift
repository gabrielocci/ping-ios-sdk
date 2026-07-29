//
//  AbstractRecognizeCallback.swift
//  PingRecognize
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#if canImport(KeylessSDK)
import Foundation
@preconcurrency import KeylessSDK
import PingOrchestrate
import PingJourneyPlugin


// MARK: - RecognizeOperationType

/// The operation type conveyed by the server in the `operationType` output field.
public enum RecognizeOperationType: String, Sendable {
    case enroll = "ENROLL"
    case authenticate = "AUTHENTICATE"
}

// MARK: - RecognizeMobileSDKOptions

/// Typed wrapper around the `mobileSDKOptions` dictionary received from the server.
///
/// The server delivers all values as strings, including booleans (`"true"`/`"false"`) and
/// integers (`"2"`, `"5"`). Computed properties convert these to native Swift types.
public struct RecognizeMobileSDKOptions: Sendable {

    let raw: [String: String]

    // MARK: Common options

    /// The liveness detection configuration level (e.g. `"LEVEL_1"`).
    public var livenessConfiguration: String { raw[JourneyConstants.livenessConfiguration] ?? "" }

    /// Whether the SDK adapts its behaviour to the surrounding environment.
    public var livenessEnvironmentAware: Bool? { raw[JourneyConstants.livenessEnvironmentAware].flatMap(Bool.init) }

    /// The server-assigned operation info ID.
    public var operationInfoId: String { raw[JourneyConstants.operationInfoId] ?? "" }

    /// The server-assigned operation info payload.
    public var operationInfoPayload: String { raw[JourneyConstants.operationInfoPayload] ?? "" }

    /// The external user ID linked to this operation.
    public var operationInfoExternalUserId: String { raw[JourneyConstants.operationInfoExternalUserId] ?? "" }

    /// Delay in seconds before the camera activates.
    public var cameraDelaySeconds: Int? { raw[JourneyConstants.cameraDelaySeconds].flatMap(Int.init) }

    /// Whether to show a success feedback overlay after the operation completes.
    public var showSuccessFeedback: Bool? { raw[JourneyConstants.showSuccessFeedback].flatMap(Bool.init) }

    // MARK: Enrollment-only options

    /// A custom secret to bind to the enrollment record.
    /// - Note: Parsed from the server but not yet forwarded to the Keyless SDK — behaviour under investigation.
    public var customSecret: String { raw[JourneyConstants.customSecret] ?? "" }

    /// Whether to show a failure feedback overlay when enrollment fails.
    public var showFailureFeedback: Bool? { raw[JourneyConstants.showFailureFeedback].flatMap(Bool.init) }

    /// Whether to display the instructions screen before the camera activates.
    public var showInstructionsScreen: Bool? { raw[JourneyConstants.showInstructionsScreen].flatMap(Bool.init) }

    /// The UI presentation style for enrollment (e.g. `"OVERLAY"`).
    public var presentation: String { raw[JourneyConstants.presentation] ?? "" }

    /// The number of enrollment circuits the SDK runs to capture biometrics.
    public var numberOfEnrollmentCircuits: Int? { raw[JourneyConstants.numberOfEnrollmentCircuits].flatMap(Int.init) }

    // MARK: Authentication-only options

    /// The UI presentation style for authentication (e.g. `"CAMERA_PREVIEW"`).
    public var presentationStyle: String { raw[JourneyConstants.presentationStyle] ?? "" }

}

// MARK: - AbstractRecognizeCallback

/// Abstract base class for PingOne Recognize callbacks in PingOne Journey workflows.
///
/// Provides shared output properties, input helpers, SDK configuration, and
/// field-parsing logic. Concrete subclasses implement the biometric operation:
/// - `PingOneRecognizeEnrollCallback` — enrollment and enrollment-with-client-state
/// - `PingOneRecognizeAuthenticateCallback` — standard authentication
open class AbstractRecognizeCallback: AbstractCallback, ContinueNodeAware, @unchecked Sendable {

    /// Reference to the continue node for accessing other callbacks.
    public weak var continueNode: ContinueNode?

    // MARK: - Output Properties

    /// Whether this is an enrollment or authentication operation.
    private(set) public var operationType: RecognizeOperationType = .enroll

    /// The WebSocket URL for the Recognize authentication service.
    private(set) public var websocketURL: String = ""

    /// The customer name associated with this PingOne Recognize deployment.
    private(set) public var customerName: String = ""

    /// The public key used to encrypt images before sending them to the server.
    private(set) public var imageEncryptionPublicKey: String = ""

    /// The ID that identifies the image encryption key.
    private(set) public var imageEncryptionKeyId: String = ""

    /// The Recognize node host URL (used to configure the Keyless SDK).
    private(set) public var host: String = ""

    /// The API key for the Keyless SDK.
    private(set) public var apiKey: String = ""

    /// The username associated with the biometric operation.
    private(set) public var username: String = ""

    /// Customer-supplied transaction data to be signed by the SDK.
    private(set) public var transactionData: String = ""

    /// Whether the server requested generation of a new client state.
    private(set) public var generateClientState: Bool = false

    /// An existing client-state payload provided by the server during enrollment restore.
    private(set) public var clientState: String = ""

    /// Mobile SDK options parsed from the server response.
    private(set) public var mobileSDKOptions: RecognizeMobileSDKOptions = RecognizeMobileSDKOptions(raw: [:])

    // MARK: - Initialization

    /// Populates output properties from the JSON output fields delivered by the server.
    public override func initValue(name: String, value: Any) {
        switch name {
        case JourneyConstants.operationType:
            if let stringValue = value as? String {
                self.operationType = RecognizeOperationType(rawValue: stringValue) ?? .enroll
            }
        case JourneyConstants.websocketURL:
            if let stringValue = value as? String { self.websocketURL = stringValue }
        case JourneyConstants.customerName:
            if let stringValue = value as? String { self.customerName = stringValue }
        case JourneyConstants.imageEncryptionPublicKey:
            if let stringValue = value as? String { self.imageEncryptionPublicKey = stringValue }
        case JourneyConstants.imageEncryptionKeyId:
            if let stringValue = value as? String { self.imageEncryptionKeyId = stringValue }
        case JourneyConstants.host:
            if let stringValue = value as? String { self.host = stringValue }
        case JourneyConstants.apiKey:
            if let stringValue = value as? String { self.apiKey = stringValue }
        case JourneyConstants.username:
            if let stringValue = value as? String { self.username = stringValue }
        case JourneyConstants.transactionData:
            if let stringValue = value as? String { self.transactionData = stringValue }
        case JourneyConstants.generateClientState:
            if let boolValue = value as? Bool {
                self.generateClientState = boolValue
            } else if let stringValue = value as? String {
                self.generateClientState = Bool(stringValue) ?? false
            }
        case JourneyConstants.clientState:
            if let stringValue = value as? String { self.clientState = stringValue }
        case JourneyConstants.mobileSDKOptions:
            self.mobileSDKOptions = RecognizeMobileSDKOptions(raw: Self.stringDictionary(from: value))
        default:
            break
        }
    }

    // MARK: - Input Helpers

    /// Writes the error message into the `clientError` input field (suffix match).
    public func error(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputClientError)
    }

    /// Sets the signed JWT returned by the Keyless SDK into the `signedJwt` input field.
    public func setSignedJwt(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputSignedJwt)
    }

    /// Sets the client state returned by the Keyless SDK into the `clientState` input field.
    public func setClientState(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputClientState)
    }

    /// Sets the Recognize user ID into the `recognizeId` input field.
    public func setRecognizeId(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputRecognizeId)
    }

    /// Sets the device public signing key into the `devicePublicSigningKey` input field.
    public func setDevicePublicSigningKey(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputDevicePublicSigningKey)
    }

    /// Sets a client error code into the `clientErrorCode` input field.
    public func setClientErrorCode(_ value: String) {
        updateInputValue(value, forSuffix: JourneyConstants.inputClientErrorCode)
    }

    /// Writes `value` into the first input whose `name` ends with `suffix`.
    private func updateInputValue(_ value: String, forSuffix suffix: String) {
        guard var inputArray = json[JourneyConstants.input] as? [[String: Any]] else { return }
        guard let index = inputArray.firstIndex(where: {
            ($0[JourneyConstants.name] as? String)?.hasSuffix(suffix) ?? false
        }) else { return }
        inputArray[index][JourneyConstants.value] = value
        json[JourneyConstants.input] = inputArray
    }

    // MARK: - Shared Biometric Operations

    /// Performs the biometric authentication operation using `BiomAuthConfig`.
    ///
    /// Shared by `PingOneRecognizeAuthenticateCallback` and the already-enrolled
    /// path in `PingOneRecognizeEnrollCallback.enrollWithClientState`.
    func performAuthenticate(options: RecognizeMobileSDKOptions) async throws {
        let operationInfo: Keyless.OperationInfo? = options.operationInfoId.isEmpty ? nil
            : Keyless.OperationInfo(
                id: options.operationInfoId,
                payload: options.operationInfoPayload,
                externalUserId: options.operationInfoExternalUserId.isEmpty ? nil : options.operationInfoExternalUserId
            )

        let authConfig = BiomAuthConfig(
            livenessConfiguration: Self.livenessConfiguration(from: options.livenessConfiguration),
            livenessEnvironmentAware: options.livenessEnvironmentAware ?? BiomAuthConfig.DEFAULT_LIVENESS_ENV_AWARE,
            cameraDelaySeconds: options.cameraDelaySeconds ?? BiomAuthConfig.DEFAULT_CAMERA_DELAY_SECONDS,
            generatingClientState: generateClientState ? .backup : nil,
            showSuccessFeedback: options.showSuccessFeedback ?? BiomAuthConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK,
            jwtSigningInfo: jwtSigningInfo(from: transactionData),
            operationInfo: operationInfo,
            presentationStyle: Self.authPresentationStyle(from: options.presentationStyle)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.authenticate(configuration: authConfig) { [weak self] result in
                switch result {
                case .success(let response):
                    if let jwt = response.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = response.clientState { self?.setClientState(state) }
                    if case .success(let key) = Keyless.getDevicePublicSigningKey() {
                        self?.setDevicePublicSigningKey(key)
                    }
                    continuation.resume()
                case .failure(let error):
                    if let sdkError = error as? KeylessSDKError {
                        continuation.resume(throwing: RecognizeError(sdkError.message, code: sdkError.code))
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Keyless SDK Configuration

    /// Configures and initialises the Keyless SDK with the server-supplied credentials.
    public func configure() async throws {
        let setupConfig = SetupConfig(
            apiKey: apiKey,
            hosts: [host],
            numberOfEnrollmentCircuits: mobileSDKOptions.numberOfEnrollmentCircuits ?? SetupConfig.DEFAULT_NUMBER_OF_ENROLLMENT_CIRCUITS
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.configure(setupConfiguration: setupConfig) { error in
                if let error = error {
                    continuation.resume(throwing: RecognizeError(error.message, code: error.code))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Shared Helpers

    /// Returns a `JwtSigningInfo` when `transactionData` is non-empty; `nil` otherwise.
    public func jwtSigningInfo(from transactionData: String) -> JwtSigningInfo? {
        transactionData.isEmpty ? nil : JwtSigningInfo(claimTransactionData: transactionData)
    }

    /// Maps the server liveness string (e.g. `"LEVEL_1"`) to `Keyless.LivenessConfiguration`.
    public static func livenessConfiguration(from string: String) -> Keyless.LivenessConfiguration {
        switch string.uppercased() {
        case "DEVELOPMENT": return .DEVELOPMENT
        case "LEVEL_1":     return .LEVEL_1
        case "LEVEL_2":     return .LEVEL_2
        default:            return .LEVEL_1
        }
    }

    /// Maps the server `presentation` string (e.g. `"OVERLAY"`) to `BiomEnrollConfig.PresentationStyle`.
    public static func enrollPresentationStyle(from string: String) -> BiomEnrollConfig.PresentationStyle {
        switch string.uppercased() {
        case "FULL_SCREEN": return .fullScreen
        default:            return .overlay
        }
    }

    /// Maps the server `presentationStyle` string (e.g. `"CAMERA_PREVIEW"`) to `PresentationStyle`.
    public static func authPresentationStyle(from string: String) -> PresentationStyle {
        switch string.uppercased() {
        case "NO_CAMERA_PREVIEW": return .noCameraPreview
        default:                  return .cameraPreview
        }
    }

    /// Converts a JSON value to a `[String: String]` dictionary.
    ///
    /// Values that are not already strings are coerced via string interpolation.
    public static func stringDictionary(from value: Any) -> [String: String] {
        if let dict = value as? [String: String] { return dict }
        if let dict = value as? [String: Any] {
            return dict.reduce(into: [:]) { result, pair in
                result[pair.key] = "\(pair.value)"
            }
        }
        return [:]
    }
}

// MARK: - JourneyConstants (Recognize input field keys)

extension JourneyConstants {
    /// The string value used as a fallback client error when `localizedDescription` is empty.
    public static let clientError = "clientError"
    /// The canonical string representation of boolean `true` as sent by the server.
    public static let boolTrue = "true"
    /// The canonical string representation of boolean `false` as sent by the server.
    public static let boolFalse = "false"
    /// Input field suffix for the signed JWT produced by the Keyless SDK.
    public static let inputSignedJwt = "signedJwt"
    /// Input field suffix for the client state produced by the Keyless SDK.
    public static let inputClientState = "clientState"
    /// Input field suffix for the Recognize user ID produced during enrollment.
    public static let inputRecognizeId = "recognizeId"
    /// Input field suffix for the device public signing key retrieved after authentication.
    public static let inputDevicePublicSigningKey = "devicePublicSigningKey"
    /// Input field suffix for the client error message.
    public static let inputClientError = "clientError"
    /// Input field suffix for a structured client error code.
    public static let inputClientErrorCode = "clientErrorCode"
}

// MARK: - JourneyConstants (Recognize output field keys + defaults)

extension JourneyConstants {
    // MARK: PingOneRecognize — output field keys

    static let operationType = "operationType"
    static let websocketURL = "websocketURL"
    static let customerName = "customerName"
    static let imageEncryptionPublicKey = "imageEncryptionPublicKey"
    static let imageEncryptionKeyId = "imageEncryptionKeyId"
    static let host = "host"
    static let apiKey = "apiKey"
    static let username = "username"
    static let transactionData = "transactionData"
    static let generateClientState = "generateClientState"
    static let clientState = "clientState"
    static let mobileSDKOptions = "mobileSDKOptions"
    static let webSDKOptions = "webSDKOptions"

    // MARK: PingOneRecognize — mobile SDK option keys

    static let livenessConfiguration = "livenessConfiguration"
    static let livenessEnvironmentAware = "livenessEnvironmentAware"
    static let operationInfoId = "operationInfoId"
    static let operationInfoPayload = "operationInfoPayload"
    static let operationInfoExternalUserId = "operationInfoExternalUserId"
    static let cameraDelaySeconds = "cameraDelaySeconds"
    static let showSuccessFeedback = "showSuccessFeedback"
    static let customSecret = "customSecret"
    static let showFailureFeedback = "showFailureFeedback"
    static let showInstructionsScreen = "showInstructionsScreen"
    static let presentation = "presentation"
    static let numberOfEnrollmentCircuits = "numberOfEnrollmentCircuits"
    static let presentationStyle = "presentationStyle"
}
#endif
