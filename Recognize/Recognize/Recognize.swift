//
//  Recognize.swift
//  PingRecognize
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Custom error type for Recognize SDK exceptions
public struct RecognizeError: Error, LocalizedError, Sendable {
    public let message: String

    /// A localized description of the error.
    public var errorDescription: String? {
        return message
    }

    /// Initializes a new instance of `RecognizeError` with a given message.
    public init(_ message: String) {
        self.message = message
    }
}
