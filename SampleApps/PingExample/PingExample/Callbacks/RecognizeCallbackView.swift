//
//  RecognizeCallbackView.swift
//  PingExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingRecognize

struct RecognizeCallbackView: View {
    @StateObject private var viewModel: RecognizeCallbackViewModel

    init(callback: RecognizeCallback, onNext: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: RecognizeCallbackViewModel(callback: callback, onNext: onNext))
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Processing biometric operation...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            viewModel.startIfNeeded()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}

class RecognizeCallbackViewModel: ObservableObject {
    private var task: Task<Void, Never>?
    private let callback: RecognizeCallback
    private let onNext: () -> Void
    private var hasStarted = false

    init(callback: RecognizeCallback, onNext: @escaping () -> Void) {
        self.callback = callback
        self.onNext = onNext
    }

    @MainActor
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        task = Task {
            let result = await callback.execute()
            switch result {
            case .success:
                print("Recognize operation succeeded")
            case .failure(let error):
                if let recognizeError = error as? RecognizeError {
                    print("Recognize operation failed [\(recognizeError.code)]: \(recognizeError.message)")
                } else {
                    print("Recognize operation failed: \(error.localizedDescription)")
                }
            }

            if !Task.isCancelled {
                await MainActor.run {
                    self.onNext()
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancel()
    }
}
