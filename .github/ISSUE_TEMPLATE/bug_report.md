---
name: Bug Report
about: Submit a bug report for Setup Your Mac (after using the snippet below and having reviewed open swiftDialog issues)
title: ''
labels: bug
assignees: ''

---

> Before submitting a bug report, please use the following snippet to download a fresh, time-stamped version of `Setup-Your-Mac-via-Dialog.bash` and ensure you can replicate the unexpected behavior:
> 
> `timestamp=$( date '+%Y-%m-%d-%H%M%S' ) ; curl -o ~/Downloads/Setup-Your-Mac-via-Dialog-$timestamp.bash https://raw.githubusercontent.com/setup-your-mac/Setup-Your-Mac/main/Setup-Your-Mac-via-Dialog.bash ; sudo bash ~/Downloads/Setup-Your-Mac-via-Dialog-$timestamp.bash`
> 
> Also, please review the [open swiftDialog issues](https://github.com/bartreardon/swiftDialog/issues) to help determine the source of the issue.

---

**Describe the bug**
A clear, concise description of the bug.

**To Reproduce**
 - Please describe how the script was executed (i.e., via macOS Terminal, via in a Jamf Pro Self Service policy, etc.).
 - Please detail any modififications.
 
**Expected behavior**
A clear, concise description of what you expected to happen.

**Code/log output**
Please supply the full command used, and if applicable, add full output from Terminal. Either upload the log, or paste the output in a code block (triple backticks at the start and end of the code block, please!).

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
 - OS version (i.e., 26.3)
 - Script version (i.e., 1.16.0) - please upgrade to the latest version before submitting a bug report.
 - swiftDialog version (i.e., 3.0.0) - please upgrade to the latest version before submitting a bug report.

**Additional context**
Add any other context about the problem here.
