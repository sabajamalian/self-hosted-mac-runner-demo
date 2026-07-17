# Self-Hosted macOS Runner Demo Repository

> **Status: Implemented ✅** — All items in this plan have been implemented. See `README.md` for setup, usage, and troubleshooting. This file is retained as a reference for the original design intent.

## Problem and approach

Create a public GitHub repository that demonstrates an Apple silicon MacBook acting as a GitHub Actions self-hosted runner. The main workflow will be manually dispatched by a trusted maintainer, build a small SwiftUI iOS app with the MacBook's installed Xcode, run unit and UI tests in a temporary iOS Simulator, capture evidence from the physical runner, and upload the results.

The demo should make the hardware-specific value visible without allowing untrusted pull request code to execute on the MacBook. It will use a dedicated runner label, least-privilege workflow permissions, pinned actions, temporary simulator resources, sanitized machine diagnostics, and documented teardown steps.

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       └── self-hosted-ios.yml
├── RunnerDemo/
│   ├── RunnerDemo.xcodeproj/
│   ├── RunnerDemo/
│   ├── RunnerDemoTests/
│   └── RunnerDemoUITests/
├── scripts/
│   ├── ci.sh
│   ├── create-simulator.sh
│   ├── runner-info.sh
│   └── cleanup.sh
├── .gitignore
├── LICENSE
└── README.md
```

## Planned implementation

1. **Create the sample iOS app**
   - Add a minimal SwiftUI app with a committed shared Xcode scheme.
   - Show a simple "Running on a self-hosted Mac" screen so the UI test and screenshot are easy to understand during the demo.
   - Keep the app dependency-free so the demo tests Xcode, Simulator, and the physical runner rather than package downloads.
   - Add a small model or formatter with deterministic unit tests.
   - Add a UI test that launches the app and verifies the primary screen content.

2. **Add reusable local CI scripts**
   - `runner-info.sh`: emit sanitized details such as CPU architecture, macOS version, Xcode version, available disk space, and installed iOS runtimes. Do not expose serial numbers, UUIDs, IP addresses, usernames, or home-directory paths.
   - `create-simulator.sh`: select a compatible installed iPhone device type and the newest available iOS runtime, create a simulator named for the workflow run, boot it, and return its UDID.
   - `ci.sh`: run `xcodebuild test` against the simulator UDID, place DerivedData and the `.xcresult` bundle under the workflow's temporary directory, and preserve the command exit status.
   - `cleanup.sh`: shut down and delete only the simulator created for the current run, then remove run-scoped temporary build data.
   - Make the scripts usable locally so the same commands can be rehearsed before the live GitHub Actions run.

3. **Build the self-hosted GitHub Actions workflow**
   - Trigger only with `workflow_dispatch`; do not add `pull_request`, `pull_request_target`, `push`, issue-comment, or reusable-workflow entry points.
   - Target `[self-hosted, macOS, ARM64, demo-mac]`.
   - Set `permissions: contents: read`, a job timeout, and concurrency that permits only one demo job on the MacBook at a time.
   - Pin every third-party action to a full commit SHA and note the corresponding release in comments.
   - Collect sanitized runner information, create and boot a temporary simulator, run unit and UI tests, and capture a simulator screenshot.
   - Publish the test result bundle, screenshot, and diagnostics as a short-retention artifact.
   - Write a concise GitHub Actions job summary containing hardware, macOS, Xcode, simulator, and test-result details.
   - Run cleanup with `if: always()` so failed and cancelled test runs do not leave demo simulators or DerivedData behind.

4. **Document MacBook runner setup**
   - List prerequisites: Apple silicon Mac, supported macOS, Xcode with the required iOS runtime, Xcode license acceptance, command-line tools selection, Git, and sufficient disk space.
   - Use GitHub's generated repository runner command to download and register the current `osx-arm64` Actions runner. Never place the short-lived registration token in the repository, shell history examples, screenshots, or logs.
   - Register the custom `demo-mac` label while retaining the default `self-hosted`, `macOS`, and `ARM64` labels.
   - Recommend a dedicated non-admin macOS account, a dedicated runner directory, FileVault, screen lock, and no personal cloud credentials in that account.
   - Document foreground `./run.sh` mode as the live-demo path because its job logs are visible on the MacBook. Document the runner service as an optional unattended mode.
   - Explain how to stop the runner, remove it from GitHub, unregister it locally, and delete its working directory after the demo.

5. **Write the live demo guide**
   - Show the MacBook waiting for a job in the runner terminal.
   - Open the Actions tab and manually dispatch the workflow from the protected default branch.
   - Point out the job being scheduled specifically to the `demo-mac` label.
   - Show Xcode and Simulator activity on the physical MacBook while tests execute.
   - Open the GitHub job summary and downloaded artifacts to prove which hardware and Xcode version performed the work.
   - Include a failure demonstration by describing a safe, reversible test assertion change, but do not automate untrusted branch or pull request execution.
   - End with runner shutdown and cleanup.

6. **Add repository guidance and metadata**
   - Add a prominent warning that a self-hosted runner executes workflow code with the runner account's permissions.
   - Explain why public pull request workflows are intentionally excluded and why labels alone are routing controls, not a security boundary.
   - Add troubleshooting for offline labels, Xcode license errors, unavailable runtimes, Simulator boot failures, and runner service GUI-session limitations.
   - Add `.gitignore` entries for DerivedData, result bundles, local runner files, and Simulator artifacts.
   - Add an appropriate open-source license and a status badge for the manual workflow.

## Acceptance criteria

- A maintainer can register an Apple silicon MacBook with the `demo-mac` label without storing a token or machine-specific secret in the repository.
- The workflow can only be started manually from repository Actions by a user with sufficient repository permissions.
- A successful run builds the app, runs unit and UI tests on a temporary iOS Simulator, and uploads an `.xcresult` bundle, a simulator screenshot, and sanitized runner diagnostics.
- Cleanup runs after success, failure, or cancellation and deletes only resources created by that workflow run.
- No workflow path executes code from an untrusted pull request on the MacBook.
- The README supports a repeatable live demo, troubleshooting, and complete runner teardown.

## Notes and considerations

- A public repository's self-hosted runner must be treated as sensitive infrastructure. `workflow_dispatch` reduces exposure, but repository write access still grants the ability to alter and run workflow code.
- The strongest practical setup for a personal MacBook is a disposable runner account and removing the runner immediately after the demo. A separate dedicated Mac is safer for ongoing use.
- The scripts should discover installed simulator device types and runtimes rather than hard-code a specific iPhone or iOS version.
- The workflow should avoid printing environment variables or broad system profiles because they can contain local paths and identifying information.
- The demo intentionally excludes a GitHub-hosted runner comparison so the narrative stays focused on physical Apple hardware and native Xcode tooling.
