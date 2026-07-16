//
//  RecognizeCallback.swift
//  PingRecognize
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#if canImport(KeylessSDK)
import Foundation
import KeylessSDK
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
    public var livenessEnvironmentAware: Bool { raw[JourneyConstants.livenessEnvironmentAware] == JourneyConstants.boolTrue }

    /// The server-assigned operation info ID.
    public var operationInfoId: String { raw[JourneyConstants.operationInfoId] ?? "" }

    /// The server-assigned operation info payload.
    public var operationInfoPayload: String { raw[JourneyConstants.operationInfoPayload] ?? "" }

    /// The external user ID linked to this operation.
    public var operationInfoExternalUserId: String { raw[JourneyConstants.operationInfoExternalUserId] ?? "" }

    /// Delay in seconds before the camera activates.
    public var cameraDelaySeconds: Int { Int(raw[JourneyConstants.cameraDelaySeconds] ?? JourneyConstants.defaultZero) ?? 0 }

    /// Whether to show a success feedback overlay after the operation completes.
    ///
    /// Defaults to `true` to match `DEFAULT_SHOW_SUCCESS_FEEDBACK` in the Keyless SDK.
    /// Uses `!= boolFalse` so that an absent server value preserves the Keyless default.
    public var showSuccessFeedback: Bool { raw[JourneyConstants.showSuccessFeedback] != JourneyConstants.boolFalse }

    // MARK: Enrollment-only options

    /// A custom secret to bind to the enrollment record.
    /// - Note: Parsed from the server but not yet forwarded to the Keyless SDK — behaviour under investigation.
    public var customSecret: String { raw[JourneyConstants.customSecret] ?? "" }

    /// Whether to retrieve the enrollment frame image.
    /// - Note: The server-side key intentionally contains a typo (`"shuold"`) which is preserved.
    public var shouldRetrieveEnrollmentFrame: Bool { raw[JourneyConstants.shouldRetrieveEnrollmentFrame] == JourneyConstants.boolTrue }

    /// Whether to show a failure feedback overlay when enrollment fails.
    ///
    /// Defaults to `true` to match `DEFAULT_SHOW_FAILURE_FEEDBACK` in the Keyless SDK.
    /// Uses `!= boolFalse` so that an absent server value preserves the Keyless default.
    public var showFailureFeedback: Bool { raw[JourneyConstants.showFailureFeedback] != JourneyConstants.boolFalse }

    /// Whether to display the instructions screen before the camera activates.
    ///
    /// Defaults to `true` to match `BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN` in the Keyless SDK.
    /// Uses `!= boolFalse` instead of the usual `== boolTrue` pattern so that an absent server value
    /// preserves the Keyless default rather than silently disabling the screen.
    public var showInstructionsScreen: Bool { raw[JourneyConstants.showInstructionsScreen] != JourneyConstants.boolFalse }

    /// The UI presentation style for enrollment (e.g. `"OVERLAY"`).
    public var presentation: String { raw[JourneyConstants.presentation] ?? "" }

    /// The number of enrollment circuits the SDK runs to capture biometrics.
    public var numberOfEnrollmentCircuits: Int { Int(raw[JourneyConstants.numberOfEnrollmentCircuits] ?? JourneyConstants.defaultNumberOfEnrollmentCircuits) ?? 5 }

    // MARK: Authentication-only options

    /// Whether to retrieve the stored biometric secret during authentication.
    /// - Note: Parsed from the server but not yet forwarded to the Keyless SDK — behaviour under investigation.
    public var shouldRetrieveSecret: Bool { raw[JourneyConstants.shouldRetrieveSecret] == JourneyConstants.boolTrue }

    /// Whether to delete the stored biometric secret after successful authentication.
    /// - Note: Parsed from the server but not yet forwarded to the Keyless SDK — behaviour under investigation.
    public var shouldDeleteSecret: Bool { raw[JourneyConstants.shouldDeleteSecret] == JourneyConstants.boolTrue }

    /// Whether to retrieve the authentication frame image.
    /// - Note: The server-side key intentionally contains a typo (`"shouldRetrive"`) which is preserved.
    public var shouldRetrieveAuthenticationFrame: Bool { raw[JourneyConstants.shouldRetrieveAuthenticationFrame] == JourneyConstants.boolTrue }

    /// The UI presentation style for authentication (e.g. `"CAMERA_PREVIEW"`).
    public var presentationStyle: String { raw[JourneyConstants.presentationStyle] ?? "" }

    /// Whether to remove the PIN binding after authentication.
    public var shouldRemovePin: Bool { raw[JourneyConstants.shouldRemovePin] == JourneyConstants.boolTrue }
}

// MARK: - RecognizeCallback

/// A Journey callback that drives the PingOne Recognize biometric authentication SDK.
///
/// The server emits a single callback type (`"PingOneRecognizeCallback"`) for both
/// enrollment and authentication. The `operationType` output field distinguishes the two flows.
///
/// **Usage:**
/// ```swift
/// if let recognizeCallback = node.callbacks.first(where: { $0 is RecognizeCallback })
///         as? RecognizeCallback {
///     let result = await recognizeCallback.execute()
/// }
/// ```
public class RecognizeCallback: AbstractCallback, ContinueNodeAware, @unchecked Sendable {

    /// Reference to the continue node for accessing other callbacks.
    public weak var continueNode: ContinueNode?

    // MARK: - Output Properties

    /// Whether this is an enrollment or authentication operation.
    private(set) public var operationType: RecognizeOperationType = .enroll

    /// The WebSocket URL for the Recognize authentication service.
    /// - Note: Provided by the server for context but not forwarded to the Keyless SDK, which manages its own transport layer.
    private(set) public var websocketURL: String = ""

    /// The customer name associated with this PingOne Recognize deployment.
    /// - Note: Provided by the server for context but not forwarded to the Keyless SDK.
    private(set) public var customerName: String = ""

    /// The public key used to encrypt images before sending them to the server.
    /// - Note: Provided by the server for context but not forwarded to the Keyless SDK, which handles image encryption internally.
    private(set) public var imageEncryptionPublicKey: String = ""

    /// The ID that identifies the image encryption key.
    /// - Note: Provided by the server for context but not forwarded to the Keyless SDK.
    private(set) public var imageEncryptionKeyId: String = ""

    /// The Recognize node host URL (used to configure the Keyless SDK).
    private(set) public var host: String = ""

    /// The API key for the Keyless SDK.
    private(set) public var apiKey: String = ""

    /// The username associated with the biometric operation.
    /// - Note: Provided by the server for context but not forwarded to the Keyless SDK.
    ///   User identity is bound via `operationInfoExternalUserId` when the server supplies an explicit `operationInfoId`.
    private(set) public var username: String = ""

    /// Customer-supplied transaction data to be signed by the SDK.
    private(set) public var transactionData: String = ""

    /// The `generateClientState` bool string supplied by the server (`"true"` or `"false"`).
    private(set) public var generateClientState: String = ""

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
                self.generateClientState = boolValue ? JourneyConstants.boolTrue : ""
            } else if let stringValue = value as? String {
                self.generateClientState = stringValue
            }
        case JourneyConstants.clientState:
            if let stringValue = value as? String { self.clientState = stringValue }
        case JourneyConstants.mobileSDKOptions:
            self.mobileSDKOptions = RecognizeMobileSDKOptions(raw: Self.stringDictionary(from: value))
        default:
            break
        }
    }

    // MARK: - Execution

    /// Configures the Keyless SDK and executes the enrollment or authentication operation.
    ///
    /// - Returns: `.success(())` on completion, or `.failure(error)` if any step fails.
    ///   On failure the `IDToken1clientError` input field is automatically populated.
    public func execute() async -> Result<Void, Error> {
        do {
            try await configure()
            try Task.checkCancellation()
            switch operationType {
            case .enroll:
                try await enroll(options: mobileSDKOptions)
            case .authenticate:
                if !clientState.isEmpty {
                    try await enrollWithClientState(clientState, options: mobileSDKOptions)
                } else {
                    try await authenticate(options: mobileSDKOptions)
                }
            }
            return .success(())
        } catch {
            let message = error.localizedDescription.isEmpty
                ? JourneyConstants.clientError
                : error.localizedDescription
            self.error(message)
            return .failure(error)
        }
    }

    // MARK: - Input Helpers

    /// Writes the error message into the `IDToken1clientError` input field.
    /// - Parameter value: The error message to send to the server.
    public func error(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputClientError)
    }

    /// Sets the signed JWT returned by the Keyless SDK into the `IDToken1signedJwt` input field.
    public func setSignedJwt(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputSignedJwt)
    }

    /// Sets the client state returned by the Keyless SDK into the `IDToken1clientState` input field.
    public func setClientState(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputClientState)
    }

    /// Sets the Recognize user ID into the `IDToken1recognizeId` input field.
    public func setRecognizeId(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputRecognizeId)
    }

    /// Sets the device public signing key into the `IDToken1devicePublicSigningKey` input field.
    public func setDevicePublicSigningKey(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputDevicePublicSigningKey)
    }

    /// Sets a client error code into the `IDToken1clientErrorCode` input field.
    public func setClientErrorCode(_ value: String) {
        _ = input(value, forKey: JourneyConstants.inputClientErrorCode)
    }

    // MARK: - Keyless SDK Wrappers

    /// Returns a `JwtSigningInfo` when `transactionData` is non-empty; `nil` otherwise.
    private func jwtSigningInfo(from transactionData: String) -> JwtSigningInfo? {
        transactionData.isEmpty ? nil : JwtSigningInfo(claimTransactionData: transactionData)
    }

    /// Configures and initialises the Keyless SDK with the server-supplied credentials.
    internal func configure() async throws {
        let setupConfig = SetupConfig(
            apiKey: apiKey,
            hosts: [host],
            numberOfEnrollmentCircuits: mobileSDKOptions.numberOfEnrollmentCircuits
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.configure(setupConfiguration: setupConfig) { error in
                if let error = error {
                    continuation.resume(throwing: RecognizeError(error.message))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Performs the biometric enrollment operation using `BiomEnrollConfig`.
    ///
    /// On success, populates `IDToken1recognizeId`, `IDToken1signedJwt`, and `IDToken1clientState`.
    internal func enroll(options: RecognizeMobileSDKOptions) async throws {
        let operationInfo: Keyless.OperationInfo? = options.operationInfoId.isEmpty ? nil
            : Keyless.OperationInfo(
                id: options.operationInfoId,
                payload: options.operationInfoPayload,
                externalUserId: options.operationInfoExternalUserId.isEmpty ? nil : options.operationInfoExternalUserId
            )

        let enrollConfig = BiomEnrollConfig(
            clientState: clientState.isEmpty ? nil : clientState,
            operationInfo: operationInfo,
            jwtSigningInfo: jwtSigningInfo(from: transactionData),
            livenessConfiguration: Self.livenessConfiguration(from: options.livenessConfiguration),
            livenessEnvironmentAware: options.livenessEnvironmentAware,
            cameraDelaySeconds: options.cameraDelaySeconds,
            generatingClientState: Self.clientStateType(from: generateClientState),
            shouldRetrieveEnrollmentFrame: options.shouldRetrieveEnrollmentFrame,
            showInstructionsScreen: options.showInstructionsScreen,
            showSuccessFeedback: options.showSuccessFeedback,
            showFailureFeedback: options.showFailureFeedback,
            presentationStyle: Self.enrollPresentationStyle(from: options.presentation)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.enroll(configuration: enrollConfig) { [weak self] result in
                switch result {
                case .success(let enrollmentResult):
                    if let keylessId = enrollmentResult.keylessId { self?.setRecognizeId(keylessId) }
                    if let jwt = enrollmentResult.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = enrollmentResult.clientState { self?.setClientState(state) }
                    continuation.resume()
                case .failure(let error):
                    if let sdkError = error as? KeylessSDKError {
                        continuation.resume(throwing: RecognizeError(sdkError.message))
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Performs the biometric authentication operation using `BiomAuthConfig`.
    ///
    /// On success, populates `IDToken1signedJwt`, `IDToken1clientState`, and (when available)
    /// `IDToken1devicePublicSigningKey`.
    internal func authenticate(options: RecognizeMobileSDKOptions) async throws {
        let operationInfo: Keyless.OperationInfo? = options.operationInfoId.isEmpty ? nil
            : Keyless.OperationInfo(
                id: options.operationInfoId,
                payload: options.operationInfoPayload,
                externalUserId: options.operationInfoExternalUserId.isEmpty ? nil : options.operationInfoExternalUserId
            )

        let authConfig = BiomAuthConfig(
            livenessConfiguration: Self.livenessConfiguration(from: options.livenessConfiguration),
            livenessEnvironmentAware: options.livenessEnvironmentAware,
            cameraDelaySeconds: options.cameraDelaySeconds,
            generatingClientState: Self.clientStateType(from: generateClientState),
            shouldRetrieveAuthenticationFrame: options.shouldRetrieveAuthenticationFrame,
            showSuccessFeedback: options.showSuccessFeedback,
            shouldRemovePin: options.shouldRemovePin,
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
                        continuation.resume(throwing: RecognizeError(sdkError.message))
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Handles the authenticate-with-clientState path: checks whether the user is already enrolled,
    /// and if not, enrolls using the server-supplied `clientState` instead of running a biometric auth session.
    ///
    /// Called from `execute()` in place of `authenticate()` when the server provides a `clientState`.
    /// If `validateUserDeviceActive` returns nil the user is already enrolled — enrollment is skipped.
    /// If `validateUserDeviceActive` returns a `userNotEnrolled` integration error the user is not
    /// yet enrolled and `enroll(clientState:)` is called.
    /// Any other error from either call is propagated as a `RecognizeError`.
    internal func enrollWithClientState(_ clientState: String, options: RecognizeMobileSDKOptions) async throws {
        // Step 1: validate — nil means already enrolled (skip), userNotEnrolled means proceed, anything else is an error.
        let validationError: KeylessSDKError? = await withCheckedContinuation { continuation in
            Keyless.validateUserDeviceActive { error in
                continuation.resume(returning: error)
            }
        }

        if let error = validationError {
            guard case .integrationError(let ie) = error.kind, ie == .userNotEnrolled else {
                throw RecognizeError(error.message)
            }
            // userNotEnrolled — fall through to enroll below.
        } else {
            // nil — user is already enrolled, nothing to do.
            return
        }

        // Step 2: user is not enrolled — enroll with the server-supplied clientState.
        let enrollConfig = BiomEnrollConfig(
            clientState: clientState,
            livenessConfiguration: Self.livenessConfiguration(from: options.livenessConfiguration),
            livenessEnvironmentAware: options.livenessEnvironmentAware,
            cameraDelaySeconds: options.cameraDelaySeconds,
            generatingClientState: Self.clientStateType(from: generateClientState),
            showInstructionsScreen: options.showInstructionsScreen,
            showSuccessFeedback: options.showSuccessFeedback,
            showFailureFeedback: options.showFailureFeedback,
            presentationStyle: Self.enrollPresentationStyle(from: options.presentation)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.enroll(configuration: enrollConfig) { [weak self] result in
                switch result {
                case .success(let enrollmentResult):
                    if let keylessId = enrollmentResult.keylessId { self?.setRecognizeId(keylessId) }
                    if let jwt = enrollmentResult.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = enrollmentResult.clientState { self?.setClientState(state) }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: RecognizeError(error.message))
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Maps the server liveness string (e.g. `"LEVEL_1"`) to `Keyless.LivenessConfiguration`.
    ///
    /// Falls back to `.LEVEL_1` for unrecognised values.
    private static func livenessConfiguration(from string: String) -> Keyless.LivenessConfiguration {
        switch string.uppercased() {
        case "DEVELOPMENT": return .DEVELOPMENT
        case "LEVEL_1":     return .LEVEL_1
        case "LEVEL_2":     return .LEVEL_2
        default:            return .LEVEL_1
        }
    }

    /// Maps the server `presentation` string (e.g. `"OVERLAY"`) to `BiomEnrollConfig.PresentationStyle`.
    ///
    /// Falls back to `.overlay` for unrecognised values.
    private static func enrollPresentationStyle(from string: String) -> BiomEnrollConfig.PresentationStyle {
        switch string.uppercased() {
        case "FULL_SCREEN": return .fullScreen
        default:            return .overlay
        }
    }

    /// Maps the server `presentationStyle` string (e.g. `"CAMERA_PREVIEW"`) to `PresentationStyle`.
    ///
    /// Falls back to `.cameraPreview` for unrecognised values.
    private static func authPresentationStyle(from string: String) -> PresentationStyle {
        switch string.uppercased() {
        case "NO_CAMERA_PREVIEW": return .noCameraPreview
        default:                  return .cameraPreview
        }
    }

    /// Maps the server `generateClientState` bool string (`"true"` / `"false"`) to `ClientStateType`.
    ///
    /// `"true"` → `.backup`; any other value → `nil`.
    private static func clientStateType(from string: String) -> ClientStateType? {
        return string == JourneyConstants.boolTrue ? .backup : nil
    }

    /// Converts a JSON value to a `[String: String]` dictionary.
    ///
    /// Values that are not already strings are coerced via string interpolation.
    private static func stringDictionary(from value: Any) -> [String: String] {
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
    /// Input field key for the signed JWT produced by the Keyless SDK.
    public static let inputSignedJwt = "IDToken1signedJwt"
    /// Input field key for the client state produced by the Keyless SDK.
    public static let inputClientState = "IDToken1clientState"
    /// Input field key for the Recognize user ID produced during enrollment.
    public static let inputRecognizeId = "IDToken1recognizeId"
    /// Input field key for the device public signing key retrieved after authentication.
    public static let inputDevicePublicSigningKey = "IDToken1devicePublicSigningKey"
    /// Input field key for the client error message.
    public static let inputClientError = "IDToken1clientError"
    /// Input field key for a structured client error code.
    public static let inputClientErrorCode = "IDToken1clientErrorCode"
}

// MARK: - JourneyConstants (Recognize output field keys + defaults)

extension JourneyConstants {
    /// Fallback error string used when the error localised description is empty.
    public static let clientError = "clientError"

    // MARK: PingOneRecognize — mobile SDK option default values

    /// String representation of a `true` boolean as delivered by the server.
    public static let boolTrue = "true"
    /// String representation of a `false` boolean as delivered by the server.
    public static let boolFalse = "false"
    /// Default string value for integer fields that default to zero.
    public static let defaultZero = "0"
    /// Default number of enrollment circuits when no value is provided by the server.
    public static let defaultNumberOfEnrollmentCircuits = "5"

    // MARK: PingOneRecognize — output field keys

    public static let operationType = "operationType"
    public static let websocketURL = "websocketURL"
    public static let customerName = "customerName"
    public static let imageEncryptionPublicKey = "imageEncryptionPublicKey"
    public static let imageEncryptionKeyId = "imageEncryptionKeyId"
    public static let host = "host"
    public static let apiKey = "apiKey"
    public static let username = "username"
    public static let transactionData = "transactionData"
    public static let generateClientState = "generateClientState"
    public static let clientState = "clientState"
    public static let mobileSDKOptions = "mobileSDKOptions"
    public static let webSDKOptions = "webSDKOptions"

    // MARK: PingOneRecognize — mobile SDK option keys

    public static let livenessConfiguration = "livenessConfiguration"
    public static let livenessEnvironmentAware = "livenessEnvironmentAware"
    public static let operationInfoId = "operationInfoId"
    public static let operationInfoPayload = "operationInfoPayload"
    public static let operationInfoExternalUserId = "operationInfoExternalUserId"
    public static let cameraDelaySeconds = "cameraDelaySeconds"
    public static let showSuccessFeedback = "showSuccessFeedback"
    public static let customSecret = "customSecret"
    /// Server-side key contains an intentional typo (`"shuold"`) — must match the payload exactly.
    public static let shouldRetrieveEnrollmentFrame = "shuoldRetrieveEnrollmentFrame"
    public static let showFailureFeedback = "showFailureFeedback"
    public static let showInstructionsScreen = "showInstructionsScreen"
    public static let presentation = "presentation"
    public static let numberOfEnrollmentCircuits = "numberOfEnrollmentCircuits"
    public static let shouldRetrieveSecret = "shouldRetrieveSecret"
    public static let shouldDeleteSecret = "shouldDeleteSecret"
    /// Server-side key contains an intentional typo (`"shouldRetrive"`) — must match the payload exactly.
    public static let shouldRetrieveAuthenticationFrame = "shouldRetriveAuthenticationFrame"
    public static let presentationStyle = "presentationStyle"
    public static let shouldRemovePin = "shouldRemovePin"
}
#endif
