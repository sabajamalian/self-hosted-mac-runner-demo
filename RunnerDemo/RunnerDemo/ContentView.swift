import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text(RunnerInfo.primaryMessage)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("primaryLabel")

            Text(RunnerInfo.runnerLabel(
                architecture: "arm64",
                platform: "macOS"
            ))
            .font(.caption)
            .foregroundColor(.secondary)
            .accessibilityIdentifier("runnerLabel")
        }
        .padding(32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
