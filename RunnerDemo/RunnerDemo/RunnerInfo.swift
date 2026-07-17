import Foundation

/// Provides deterministic, testable utility functions for the RunnerDemo app.
enum RunnerInfo {

    /// The primary message displayed on the main screen.
    static let primaryMessage = "Running on a self-hosted Mac"

    /// Returns a formatted label combining platform and architecture.
    ///
    /// - Parameters:
    ///   - architecture: The CPU architecture string (e.g. "arm64").
    ///   - platform: The OS platform string (e.g. "macOS").
    /// - Returns: A formatted string, or "Unknown Runner" when either input is empty.
    static func runnerLabel(architecture: String, platform: String) -> String {
        guard !architecture.isEmpty, !platform.isEmpty else {
            return "Unknown Runner"
        }
        return "\(platform) / \(architecture)"
    }
}
