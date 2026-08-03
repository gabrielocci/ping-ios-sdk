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
/// Returned by `RecognizeCallback` when the server sets `operationType` to `ENROLL`.
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
            let result = try await enroll(options: mobileSDKOptions)
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

    /// Performs the biometric enrollment operation. Thin wrapper over the shared
    /// `performEnroll(clientStateOverride:options:)` — kept `open` for testability.
    open func enroll(options: RecognizeMobileSDKOptions) async throws -> RecognizeResult {
        try await performEnroll(options: options)
    }
}
#endif
