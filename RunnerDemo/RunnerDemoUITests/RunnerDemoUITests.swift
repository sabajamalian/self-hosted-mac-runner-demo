import XCTest

final class RunnerDemoUITests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testPrimaryLabelIsVisible() throws {
        let primaryLabel = app.staticTexts["primaryLabel"]
        XCTAssertTrue(
            primaryLabel.waitForExistence(timeout: 5),
            "Primary label should appear within 5 seconds"
        )
        XCTAssertEqual(
            primaryLabel.label,
            "Running on a self-hosted Mac",
            "Primary label should display the expected message"
        )
    }

    func testRunnerLabelIsVisible() throws {
        let runnerLabel = app.staticTexts["runnerLabel"]
        XCTAssertTrue(
            runnerLabel.waitForExistence(timeout: 5),
            "Runner label should appear within 5 seconds"
        )
        XCTAssertFalse(
            runnerLabel.label.isEmpty,
            "Runner label should not be empty"
        )
    }
}
