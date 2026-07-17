# self-hosted-mac-runner-demo

> **Demo:** iOS build and test workflow on a physical Apple silicon self-hosted GitHub Actions runner.

[![iOS Build and Test](https://github.com/sabajamalian/self-hosted-mac-runner-demo/actions/workflows/self-hosted-ios.yml/badge.svg)](https://github.com/sabajamalian/self-hosted-mac-runner-demo/actions/workflows/self-hosted-ios.yml)

---

## ⚠️ Security Warning

**A self-hosted runner executes workflow code with the permissions of the account running the runner process.** Review the following carefully before setting one up:

- **The runner label `demo-mac` is a routing control, not a security boundary.** Any user with write access to this repository can dispatch the workflow and run arbitrary code on the Mac.
- **Public pull request workflows are intentionally excluded.** The workflow trigger is `workflow_dispatch` only — there is no `pull_request`, `pull_request_target`, `push`, or issue-comment trigger that would automatically execute code from a fork or an untrusted contributor.
- **Treat the runner Mac as sensitive infrastructure.** Follow the hardening recommendations below and remove the runner promptly after the demo.

---

## Contents

1. [Prerequisites](#prerequisites)
2. [Runner Registration](#runner-registration)
3. [Security Recommendations](#security-recommendations)
4. [Local Rehearsal](#local-rehearsal)
5. [Live Demo Walkthrough](#live-demo-walkthrough)
6. [Failure Demonstration](#failure-demonstration)
7. [Artifacts and Job Summary](#artifacts-and-job-summary)
8. [Teardown and Unregistration](#teardown-and-unregistration)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Apple silicon Mac | M1 / M2 / M3 or later |
| macOS 13 (Ventura) or later | Xcode 15 requires macOS 13.5+ |
| Xcode 14 or later | Install from the App Store or [developer.apple.com](https://developer.apple.com/xcode/) |
| iOS 16+ Simulator runtime | Add via **Xcode → Settings → Platforms** |
| Xcode license accepted | Run `sudo xcodebuild -license accept` once |
| Xcode Command Line Tools selected | Run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| Git | Included with Xcode Command Line Tools |
| Python 3 | Required by the scripts; pre-installed on macOS 13+ |
| ~10 GB free disk space | For DerivedData and Simulator runtime |

---

## Runner Registration

> **Never commit or retain the short-lived registration token.** Use it once during `config.sh`, then discard it.

1. In your GitHub repository, go to **Settings → Actions → Runners → New self-hosted runner**.
2. Select **macOS** and **ARM64**. Copy the displayed `./config.sh` command — it contains a single-use token.
3. On the Mac, open a terminal in the desired runner directory (e.g. `~/actions-runner/`) and run the generated commands from GitHub. When prompted for labels, **keep the defaults** (`self-hosted`, `macOS`, `ARM64`) **and also add `demo-mac`**:
   ```
   # Example — use the actual command from GitHub Settings, not this one
   ./config.sh \
     --url https://github.com/YOUR_ORG/self-hosted-mac-runner-demo \
     --token GITHUB_GENERATED_TOKEN \
     --labels demo-mac
   ```
4. The token is consumed during `config.sh` and does not need to be stored anywhere.

---

## Security Recommendations

- **Use a dedicated non-admin macOS account** (`System Preferences → Users & Groups → Add Account`). A standard (non-admin) account limits damage if the runner process is exploited.
- **Create a dedicated runner directory** (e.g. `~/actions-runner/`) — keep it separate from personal data.
- **Enable FileVault** and a short screen-lock timeout.
- **Do not store personal cloud credentials** (iCloud, AWS, Azure, etc.) in the runner account.
- **Remove the runner immediately after the demo** — see [Teardown and Unregistration](#teardown-and-unregistration).
- The strongest setup for a short demo is a disposable runner account; for ongoing use, consider a dedicated Mac isolated from personal infrastructure.

---

## Local Rehearsal

You can run every script locally before the live GitHub Actions demo:

```bash
# 1. Gather sanitized runner information
bash scripts/runner-info.sh

# 2. Create and boot a temporary simulator
bash scripts/create-simulator.sh
# Note: scripts/create-simulator.sh sets RUNNER_TEMP automatically when running locally.
# To reuse the same RUNNER_TEMP across steps, export it first:
export RUNNER_TEMP="$(mktemp -d /tmp/runner-demo-XXXXXX)"
bash scripts/create-simulator.sh

# 3. Run the unit and UI tests
bash scripts/ci.sh

# 4. Inspect results
open "$RUNNER_TEMP/TestResults.xcresult"   # opens in Xcode
cat  "$RUNNER_TEMP/xcodebuild.log"

# 5. Clean up (deletes only the simulator and data from this run)
bash scripts/cleanup.sh
```

For a full end-to-end local rehearsal in one shell session:

```bash
export RUNNER_TEMP="$(mktemp -d /tmp/runner-demo-XXXXXX)"
bash scripts/runner-info.sh
bash scripts/create-simulator.sh
bash scripts/ci.sh; TEST_EXIT=$?
bash scripts/cleanup.sh
exit $TEST_EXIT
```

---

## Live Demo Walkthrough

### Step 1 – Start the runner in foreground mode

On the Mac, in the runner directory:

```bash
./run.sh
```

The terminal shows the runner waiting for a job:
```
√ Connected to GitHub
Listening for Jobs
```

Foreground mode is preferred for a live demo because job logs appear directly in the runner terminal, making it visible what Xcode and Simulator are doing on the physical machine.

### Step 2 – Dispatch the workflow

In GitHub:
1. Go to **Actions → iOS Build and Test (Self-Hosted Mac)**.
2. Click **Run workflow → Run workflow** (from the default branch).
3. Watch the job appear and be routed to the `demo-mac` label.

### Step 3 – Observe the runner Mac

- The runner terminal shows each step executing.
- Simulator.app launches in the background (you can open it to watch the UI tests run).
- Xcode build output is visible in the runner log.

### Step 4 – Inspect the results

Once the workflow completes:
- The **Summary** tab of the workflow run shows a table with architecture, macOS, Xcode, simulator/runtime, and test outcome.
- The **Artifacts** section contains the `.xcresult` bundle (zipped), simulator screenshot, runner diagnostics, and build log.

---

## Failure Demonstration

To demonstrate a safe, reversible test failure:

1. Locally edit `RunnerDemo/RunnerDemoTests/RunnerDemoTests.swift` and change one assertion to an incorrect value, for example:
   ```swift
   // Before
   XCTAssertEqual(RunnerInfo.primaryMessage, "Running on a self-hosted Mac")
   // After (intentionally wrong)
   XCTAssertEqual(RunnerInfo.primaryMessage, "This will fail")
   ```
2. Commit and push to a branch (this **will not** trigger the self-hosted workflow automatically).
3. Dispatch the workflow manually from that branch via **Run workflow → [select branch]**.
4. Observe the ❌ failure in the job summary and the xcodebuild log in the artifact.
5. Revert the change on the branch when done.

> **Do not** automate a push/pull_request trigger to demonstrate failure — that would remove the manual-only safeguard.

---

## Artifacts and Job Summary

Each successful (or failed) run uploads a short-retention (5-day) artifact named `ios-test-results-<run-id>` containing:

| File | Contents |
|---|---|
| `runner-diagnostics.txt` | Sanitized CPU arch, macOS, Xcode, disk, iOS runtimes |
| `xcodebuild.log` | Full build and test output |
| `simulator-screenshot.png` | Screenshot of the simulator at end of test run |
| `TestResults.xcresult.zip` | Zipped `.xcresult` bundle — open with `xed` or Xcode |

The **Job Summary** shows:

| Item | Example |
|---|---|
| Architecture | `arm64` |
| macOS | `14.5` |
| Xcode | `Xcode 15.4` |
| Simulator / Runtime | `iPhone 15 / iOS17-2` |
| Test Result | ✅ `success` |

> **Why zip the xcresult?** `actions/upload-artifact` skips files inside directories whose names start with `.`. Zipping the bundle ensures all internal files (including hidden ones) are preserved.

---

## Teardown and Unregistration

### Stop the runner

In the terminal where `./run.sh` is running, press `Ctrl+C`. The runner disconnects gracefully.

### Remove from GitHub

1. Go to **Settings → Actions → Runners**.
2. Find the runner and click **Remove**. GitHub generates a removal token.
3. On the Mac, in the runner directory, run:
   ```bash
   ./config.sh remove --token REMOVAL_TOKEN
   ```

### Delete the runner directory

```bash
rm -rf ~/actions-runner/
```

### Verify cleanup

- Confirm the runner no longer appears in **Settings → Actions → Runners**.
- Confirm no orphaned simulators remain: `xcrun simctl list devices | grep RunnerDemo`
- If any remain, delete them: `xcrun simctl delete <UDID>`

---

## Optional: Service Mode

For unattended operation (runner starts at login), install as a service:

```bash
./svc.sh install
./svc.sh start
```

> **Caveat:** When running as a launchd service, the runner process may not have access to the GUI session required to launch Simulator.app. If UI tests fail with a "Failed to boot simulator" error in service mode, use foreground `./run.sh` mode instead.

---

## Troubleshooting

### Runner shows as Offline

- Verify the Mac is powered on and connected to the internet.
- Check that `./run.sh` (or the service) is running.
- Confirm the runner labels match exactly: `self-hosted`, `macOS`, `ARM64`, `demo-mac` (case-sensitive).

### Label mismatch — job stays queued

- The workflow requires all four labels. Verify with:
  ```bash
  # In the runner directory
  grep -A5 "labels" .runner
  ```
- Re-run `./config.sh` with the correct `--labels` value if needed.

### Xcode license not accepted

```
xcodebuild: error: You have not agreed to the Xcode license agreements
```
Fix:
```bash
sudo xcodebuild -license accept
```

### Missing iOS runtime

```
error: Unable to find a destination matching the provided destination specifier
```
Fix: Open **Xcode → Settings → Platforms** and download the required iOS runtime.

### Simulator fails to boot

- Check for disk pressure: `df -h /` — ensure at least 5 GB free.
- Delete stale simulators: `xcrun simctl delete unavailable`
- Check system logs: `xcrun simctl diagnose`

### Disk pressure during build

DerivedData can consume several gigabytes. Clean up periodically:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
The scripts place DerivedData under `RUNNER_TEMP`, which is cleaned up automatically by `cleanup.sh` after each run.

### Service mode / GUI session limitation

If the runner is installed as a launchd service and Simulator tests fail to launch, the process lacks a GUI session. Solutions:
1. Switch to foreground mode (`./run.sh`) for the demo.
2. Or enable "Allow user to log in" for the runner account and keep a GUI session open.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── self-hosted-ios.yml   # Manual workflow (workflow_dispatch only)
├── RunnerDemo/
│   ├── RunnerDemo.xcodeproj/
│   │   ├── project.pbxproj
│   │   └── xcshareddata/
│   │       └── xcschemes/
│   │           └── RunnerDemo.xcscheme   # Shared scheme (committed)
│   ├── RunnerDemo/
│   │   ├── RunnerDemoApp.swift
│   │   ├── ContentView.swift
│   │   ├── RunnerInfo.swift              # Deterministic model / formatter
│   │   └── Assets.xcassets/
│   ├── RunnerDemoTests/
│   │   └── RunnerDemoTests.swift         # Unit tests
│   └── RunnerDemoUITests/
│       └── RunnerDemoUITests.swift       # UI tests
├── scripts/
│   ├── runner-info.sh       # Sanitized runner diagnostics
│   ├── create-simulator.sh  # Dynamic run-scoped simulator creation
│   ├── ci.sh                # xcodebuild test runner
│   └── cleanup.sh           # Idempotent teardown
├── .gitignore
├── LICENSE
├── README.md
└── plan.md                  # Original implementation plan (implemented ✅)
```

---

## License

MIT — see [LICENSE](LICENSE).
