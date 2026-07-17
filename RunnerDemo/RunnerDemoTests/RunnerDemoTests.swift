import XCTest
@testable import RunnerDemo

final class RunnerDemoTests: XCTestCase {

    func testPrimaryMessage() {
        XCTAssertEqual(RunnerInfo.primaryMessage, "Running on a self-hosted Mac")
    }

    func testRunnerLabelFormatting() {
        XCTAssertEqual(
            RunnerInfo.runnerLabel(architecture: "arm64", platform: "macOS"),
            "macOS / arm64"
        )
    }

    func testRunnerLabelEmptyArchitecture() {
        XCTAssertEqual(
            RunnerInfo.runnerLabel(architecture: "", platform: "macOS"),
            "Unknown Runner"
        )
    }

    func testRunnerLabelEmptyPlatform() {
        XCTAssertEqual(
            RunnerInfo.runnerLabel(architecture: "arm64", platform: ""),
            "Unknown Runner"
        )
    }

    func testRunnerLabelBothEmpty() {
        XCTAssertEqual(
            RunnerInfo.runnerLabel(architecture: "", platform: ""),
            "Unknown Runner"
        )
    }

    func testRunnerLabelGenericValues() {
        XCTAssertEqual(
            RunnerInfo.runnerLabel(architecture: "x86_64", platform: "Linux"),
            "Linux / x86_64"
        )
    }
}
