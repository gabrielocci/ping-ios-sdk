//
//  RecognizeResult.swift
//  PingRecognize
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#if canImport(KeylessSDK)
import CoreGraphics

/// The result of a successful PingOne Recognize biometric operation.
///
/// Returned by `PingOneRecognizeEnrollCallback.execute()` and
/// `PingOneRecognizeAuthenticateCallback.execute()` on success.
public struct RecognizeResult: Sendable {

    /// The signed JWT produced by the Keyless SDK, if JWT signing was configured.
    public let signedJwt: String?

    /// The client state blob produced by the Keyless SDK, if client-state generation was enabled.
    public let clientState: String?

    /// The Recognize user ID assigned during enrollment. Empty for authentication operations.
    public let recognizeId: String?

    /// The captured selfie frame, present only when `retrieveSelfie` was `true` in `mobileSDKOptions`.
    public let selfie: CGImage?
}
#endif
