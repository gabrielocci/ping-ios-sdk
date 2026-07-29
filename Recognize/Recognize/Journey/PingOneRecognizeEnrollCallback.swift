//
//  PingOneRecognizeEnrollCallback.swift
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
import PingJourneyPlugin

/// A Journey callback that drives PingOne Recognize biometric **enrollment**.
///
/// Returned by `RecognizeCallback` when the server sets `operationType` to `ENROLL`,
/// or when `operationType` is `AUTHENTICATE` but the server also supplies a `clientState`
/// (enrollment-restore path).
///
/// **Usage:**
/// ```swift
/// if let callback = node.callbacks.first(where: { $0 is PingOneRecognizeEnrollCallback })
///         as? PingOneRecognizeEnrollCallback {
///     let result = await callback.execute()
/// }
/// ```
public class PingOneRecognizeEnrollCallback: AbstractRecognizeCallback, @unchecked Sendable {

    /// Configures the Keyless SDK and performs the enrollment operation.
    ///
    /// - Returns: `.success(())` on completion, or `.failure(error)` if any step fails.
    ///   On failure the `IDToken1clientError` input field is automatically populated.
    public func execute() async -> Result<Void, Error> {
        do {
            try await configure()
            try Task.checkCancellation()
            if !clientState.isEmpty {
                try await enrollWithClientState(clientState, options: mobileSDKOptions)
            } else {
                try await enroll(options: mobileSDKOptions)
            }
            return .success(())
        } catch {
            let message = error.localizedDescription.isEmpty
                ? JourneyConstants.clientError
                : error.localizedDescription
            self.error(message)
            if let recognizeError = error as? RecognizeError {
                setClientErrorCode(String(recognizeError.code))
            }
            return .failure(error)
        }
    }

    // MARK: - Enrollment Operations

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
            livenessEnvironmentAware: options.livenessEnvironmentAware ?? BiomAuthConfig.DEFAULT_LIVENESS_ENV_AWARE,
            cameraDelaySeconds: options.cameraDelaySeconds ?? BiomEnrollConfig.DEFAULT_DELAY,
            generatingClientState: generateClientState ? .backup : nil,
            showInstructionsScreen: options.showInstructionsScreen ?? BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN,
            showSuccessFeedback: options.showSuccessFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK,
            showFailureFeedback: options.showFailureFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_FAILURE_FEEDBACK,
            presentationStyle: Self.enrollPresentationStyle(from: options.presentation)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.enroll(configuration: enrollConfig) { [weak self] result in
                switch result {
                case .success(let enrollmentResult):
                    if let keylessId = enrollmentResult.keylessId { self?.setRecognizeId(keylessId) }
                    if let jwt = enrollmentResult.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = enrollmentResult.clientState { self?.setClientState(state) }
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

    /// Handles the authenticate-with-clientState path: checks whether the user is already enrolled.
    ///
    /// Called from the factory when `operationType` is `AUTHENTICATE` but a `clientState` is present.
    /// - If `validateUserDeviceActive` returns nil the user is already enrolled — delegates to `PingOneRecognizeAuthenticateCallback`.
    /// - If `validateUserDeviceActive` returns `userNotEnrolled` — runs enrollment with the server-supplied client state.
    /// - Any other error from either call is propagated as a `RecognizeError`.
    internal func enrollWithClientState(_ clientState: String, options: RecognizeMobileSDKOptions) async throws {
        let validationError: KeylessSDKError? = await withCheckedContinuation { continuation in
            Keyless.validateUserDeviceActive { error in
                continuation.resume(returning: error)
            }
        }

        if let error = validationError {
            guard case .integrationError(let ie) = error.kind, ie == .userNotEnrolled else {
                throw RecognizeError(error.message, code: error.code)
            }
        } else {
            // User is already enrolled — run normal authentication.
            try await performAuthenticate(options: options)
            return
        }

        let operationInfo: Keyless.OperationInfo? = options.operationInfoId.isEmpty ? nil
            : Keyless.OperationInfo(
                id: options.operationInfoId,
                payload: options.operationInfoPayload,
                externalUserId: options.operationInfoExternalUserId.isEmpty ? nil : options.operationInfoExternalUserId
            )

        let enrollConfig = BiomEnrollConfig(
            clientState: clientState,
            operationInfo: operationInfo,
            jwtSigningInfo: jwtSigningInfo(from: transactionData),
            livenessConfiguration: Self.livenessConfiguration(from: options.livenessConfiguration),
            livenessEnvironmentAware: options.livenessEnvironmentAware ?? BiomAuthConfig.DEFAULT_LIVENESS_ENV_AWARE,
            cameraDelaySeconds: options.cameraDelaySeconds ?? BiomEnrollConfig.DEFAULT_DELAY,
            generatingClientState: generateClientState ? .backup : nil,
            showInstructionsScreen: options.showInstructionsScreen ?? BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN,
            showSuccessFeedback: options.showSuccessFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK,
            showFailureFeedback: options.showFailureFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_FAILURE_FEEDBACK,
            presentationStyle: Self.enrollPresentationStyle(from: options.presentation)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Keyless.enroll(configuration: enrollConfig) { [weak self] result in
                switch result {
                case .success(let enrollmentResult):
                    if let keylessId = enrollmentResult.keylessId { self?.setRecognizeId(keylessId) }
                    if let jwt = enrollmentResult.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = enrollmentResult.clientState { self?.setClientState(state) }
                    if case .success(let key) = Keyless.getDevicePublicSigningKey() {
                        self?.setDevicePublicSigningKey(key)
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: RecognizeError(error.message, code: error.code))
                }
            }
        }
    }
}
#endif
