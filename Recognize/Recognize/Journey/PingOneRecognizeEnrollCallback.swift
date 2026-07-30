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
open class PingOneRecognizeEnrollCallback: AbstractRecognizeCallback, @unchecked Sendable {

    /// Configures the Keyless SDK and performs the enrollment operation.
    ///
    /// - Returns: `.success(RecognizeResult)` on completion, or `.failure(error)` if any step fails.
    ///   On failure the `clientError` input field is automatically populated.
    public func execute() async -> Result<RecognizeResult, Error> {
        do {
            try await configure()
            try Task.checkCancellation()
            let result: RecognizeResult
            if !clientState.isEmpty {
                result = try await enrollWithClientState(clientState, options: mobileSDKOptions)
            } else {
                result = try await enroll(options: mobileSDKOptions)
            }
            return .success(result)
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
    /// On success, populates the `recognizeId`, `signedJwt`, and `clientState` input fields.
    open func enroll(options: RecognizeMobileSDKOptions) async throws -> RecognizeResult {
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
            shouldRetrieveEnrollmentFrame: options.retrieveSelfie ?? BiomEnrollConfig.DEFAULT_SHOULD_RETRIEVE_ENROLLMENT_FRAME,
            showInstructionsScreen: options.showInstructionsScreen ?? BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN,
            showSuccessFeedback: options.showSuccessFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK,
            showFailureFeedback: options.showFailureFeedback ?? BiomEnrollConfig.DEFAULT_SHOW_FAILURE_FEEDBACK,
            presentationStyle: Self.enrollPresentationStyle(from: options.presentation)
        )

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RecognizeResult, Error>) in
            Keyless.enroll(configuration: enrollConfig) { [weak self] result in
                switch result {
                case .success(let enrollmentResult):
                    if let keylessId = enrollmentResult.keylessId { self?.setRecognizeId(keylessId) }
                    if let jwt = enrollmentResult.signedJwt { self?.setSignedJwt(jwt) }
                    if let state = enrollmentResult.clientState { self?.setClientState(state) }
                    if case .success(let key) = Keyless.getDevicePublicSigningKey() {
                        self?.setDevicePublicSigningKey(key)
                    }
                    continuation.resume(returning: RecognizeResult(
                        signedJwt: enrollmentResult.signedJwt,
                        clientState: enrollmentResult.clientState,
                        recognizeId: enrollmentResult.keylessId,
                        selfie: enrollmentResult.enrollmentFrame
                    ))
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
    /// - If `validateUserDeviceActive` returns nil the user is already enrolled — delegates to `performAuthenticate`.
    /// - If `validateUserDeviceActive` returns `userNotEnrolled` — runs enrollment with the server-supplied client state.
    /// - Any other error is propagated as a `RecognizeError`.
    /// Validates whether the current device is active (enrolled) in the Keyless SDK.
    ///
    /// Returns a tri-state enum so tests can inject any outcome without constructing
    /// the internal-init `KeylessSDKError` type:
    /// - `.active` — device is enrolled, proceed with authentication.
    /// - `.notEnrolled` — device is not enrolled, proceed with enrollment.
    /// - `.otherError(message:code:)` — unexpected error, propagate to caller.
    ///
    /// Extracted as `open` so test subclasses can override it.
    public enum ValidationResult {
        case active
        case notEnrolled
        case otherError(message: String, code: Int)
    }

    open func validateUserDeviceActive() async -> ValidationResult {
        await withCheckedContinuation { continuation in
            Keyless.validateUserDeviceActive { error in
                guard let error else {
                    continuation.resume(returning: .active)
                    return
                }
                if case .integrationError(let ie) = error.kind, ie == .userNotEnrolled {
                    continuation.resume(returning: .notEnrolled)
                } else {
                    continuation.resume(returning: .otherError(message: error.message, code: error.code))
                }
            }
        }
    }

    open func enrollWithClientState(_ clientState: String, options: RecognizeMobileSDKOptions) async throws -> RecognizeResult {
        switch await validateUserDeviceActive() {
        case .active:
            return try await performAuthenticate(options: options)
        case .otherError(let message, let code):
            throw RecognizeError(message, code: code)
        case .notEnrolled:
            break
        }

        return try await enroll(options: options)
    }
}
#endif
