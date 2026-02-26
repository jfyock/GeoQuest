import SwiftUI

@Observable
final class LoadingViewModel {
    private(set) var currentScreen: LoadingScreenData
    private(set) var progress: Double = 0.0
    private let screens = LoadingScreenData.presets
    private var timerTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?

    init() {
        currentScreen = LoadingScreenData.presets[0]
    }

    func startRotation(interval: TimeInterval = AppConstants.loadingScreenRotationInterval) {
        timerTask = Task { [weak self] in
            guard let self else { return }
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                index = (index + 1) % self.screens.count
                let nextScreen = self.screens[index]
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.currentScreen = nextScreen
                }
            }
        }

        // Animate progress bar from 0 to ~0.9 over the loading period
        progressTask = Task { [weak self] in
            guard let self else { return }
            let totalSteps = 30
            for step in 0..<totalSteps {
                guard !Task.isCancelled else { break }
                try? await Task.sleep(for: .milliseconds(80))
                let target = Double(step + 1) / Double(totalSteps) * 0.9
                withAnimation(.easeOut(duration: 0.15)) {
                    self.progress = target
                }
            }
        }
    }

    func completeProgress() {
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 1.0
        }
    }

    func stopRotation() {
        timerTask?.cancel()
        timerTask = nil
        progressTask?.cancel()
        progressTask = nil
    }
}
