import SwiftUI

@Observable
final class LoadingViewModel {
    private(set) var currentScreen: LoadingScreenData
    private let screens = LoadingScreenData.presets
    private var timerTask: Task<Void, Never>?

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
    }

    func stopRotation() {
        timerTask?.cancel()
        timerTask = nil
    }
}
