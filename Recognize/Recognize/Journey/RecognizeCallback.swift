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
import PingJourneyPlugin

/// Factory callback registered for the `"PingOneRecognizeCallback"` server type.
///
/// The server emits a single callback type for both enrollment and authentication.
/// `RecognizeCallback` reads the `operationType` output field during `initialize(with:)`
/// and returns the appropriate concrete instance:
/// - `ENROLL` → `PingOneRecognizeEnrollCallback`
/// - `AUTHENTICATE` (with clientState) → `PingOneRecognizeEnrollCallback` (enrollment-restore path)
/// - `AUTHENTICATE` (without clientState) → `PingOneRecognizeAuthenticateCallback`
///
/// This class is not intended to be used directly — cast the result of
/// `node.callbacks` to `PingOneRecognizeEnrollCallback` or `PingOneRecognizeAuthenticateCallback`.
class RecognizeCallback: AbstractRecognizeCallback, @unchecked Sendable {

    override func initialize(with json: [String: Any]) async -> any Callback {
        // Parse shared output fields into self first.
        _ = await super.initialize(with: json)

        switch operationType {
        case .enroll:
            let callback = PingOneRecognizeEnrollCallback()
            _ = await callback.initialize(with: json)
            return callback
        case .authenticate:
            if !clientState.isEmpty {
                let callback = PingOneRecognizeEnrollCallback()
                _ = await callback.initialize(with: json)
                return callback
            } else {
                let callback = PingOneRecognizeAuthenticateCallback()
                _ = await callback.initialize(with: json)
                return callback
            }
        }
    }
}
#endif
