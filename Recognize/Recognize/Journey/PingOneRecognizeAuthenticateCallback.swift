//
//  PingOneRecognizeAuthenticateCallback.swift
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

/// A Journey callback that drives PingOne Recognize biometric **authentication**.
///
/// Returned by `RecognizeCallback` when the server sets `operationType` to `AUTHENTICATE`
/// and no `clientState` is present.
///
/// **Usage:**
/// ```swift
/// if let callback = node.callbacks.first(where: { $0 is PingOneRecognizeAuthenticateCallback })
///         as? PingOneRecognizeAuthenticateCallback {
///     let result = await callback.execute()
/// }
/// ```
public class PingOneRecognizeAuthenticateCallback: AbstractRecognizeCallback, @unchecked Sendable {

    /// Configures the Keyless SDK and performs the authentication operation.
    ///
    /// - Returns: `.success(())` on completion, or `.failure(error)` if any step fails.
    ///   On failure the `IDToken1clientError` input field is automatically populated.
    public func execute() async -> Result<Void, Error> {
        do {
            try await configure()
            try Task.checkCancellation()
            try await performAuthenticate(options: mobileSDKOptions)
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
}
#endif
