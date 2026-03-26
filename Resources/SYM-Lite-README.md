# SYM-Lite Quick Start Guide

## Overview
SYM-Lite is a lean, purpose-built script for executing Jamf Pro Policy Custom Triggers and Installomator labels through a unified swiftDialog selection interface.

**Version:** 0.0.1a1  
**File:** `Resources/SYM-Lite.zsh`  
**Size:** 40KB (1,184 lines)  
**Status:** ✓ Syntax validated, ready for functional testing

---

## Key Features

✓ **Dual execution support** — Installomator labels AND Jamf Pro policies in single session  
✓ **Interactive selection UI** — User-friendly checkbox dialog  
✓ **Silent mode** — CSV-based automation support  
✓ **Inspect Mode monitoring** — Real-time progress via file system monitoring  
✓ **Path-based validation** — Pre/post-execution checks  
✓ **Cache monitoring** — Detects in-progress downloads  
✓ **Completion dialogs** — Success/failure summary and restart prompt  
✓ **Graceful interruption** — Clean shutdown on SIGINT/SIGTERM  

---

## Configuration

### Adding Installomator Items

Edit the `installomatorItems` array (lines ~120-128):

```zsh
installomatorItems=(
    "label:Display Name:Validation Path:Icon URL"
)
```

**Example:**
```zsh
installomatorItems=(
    "microsoftword:Microsoft Word:/Applications/Microsoft Word.app:https://icon.url"
    "googlechrome:Google Chrome:/Applications/Google Chrome.app:https://icon.url"
    "zoom:Zoom:/Applications/zoom.us.app:https://icon.url"
)
```

### Adding Jamf Policy Items

Edit the `jamfPolicyItems` array (lines ~131-136):

```zsh
jamfPolicyItems=(
    "trigger:Display Name:Validation Path:Icon URL"
)
```

**Example:**
```zsh
jamfPolicyItems=(
    "installRosetta:Install Rosetta 2:/usr/bin/arch:SF=cpu"
    "enableFileVault:Enable FileVault:/Library/Preferences/com.apple.fdesetup.plist:SF=lock.shield"
    "configureDock:Configure Dock:/usr/local/bin/dockutil:SF=dock.rectangle"
)
```

**Icon Options:**
- Full URL: `https://...`
- SF Symbol: `SF=symbolname,weight=semibold,colour1=auto,colour2=auto`

---

## Usage

### Interactive Mode (Default)

Run the script as root with no parameters:

```bash
sudo /Users/[redacted]/Documents/GitHub/Setup-Your-Mac/Resources/SYM-Lite.zsh
```

**User experience:**
1. Selection dialog appears with all configured items
2. User selects one or more items using checkboxes
3. Inspect Mode dialog launches showing real-time progress
4. Completion dialog shows results
5. Optional restart prompt

### Silent Mode

Run with Jamf parameters or command-line flags:

**Via Jamf Policy:**
- Parameter 4: `silent`
- Parameter 5: `microsoftword,googlechrome,installRosetta`

**Direct execution:**
```bash
sudo /path/to/SYM-Lite.zsh "" "" "" silent "microsoftword,googlechrome"
```

**Silent mode behavior:**
- No selection dialog
- CSV list parsed directly
- No restart prompt
- Suitable for automated deployment

---

## Dependencies

### Required
- **macOS** 10.14+
- **Root access** — Script must run as root
- **swiftDialog** 3.0.0.4952+ (auto-installed if missing)

### Conditional
- **Installomator** — Required if Installomator items configured
  - Default path: `/Library/Management/AppAutoPatch/Installomator/Installomator.sh`
  - Edit `organizationInstallomatorFile` variable to customize
- **Jamf Pro Client** — Required if Jamf policy items configured
  - Default path: `/usr/local/bin/jamf`
  - Edit `jamfBinary` variable to customize

---

## Execution Flow

```
PRE-FLIGHT CHECKS
  ├─ Verify root
  ├─ Check/install swiftDialog
  ├─ Verify Installomator (if items configured)
  └─ Verify Jamf binary (if items configured)
       ↓
SELECTION INTERFACE
  ├─ Show dialog (interactive) or parse CSV (silent)
  ├─ Validate at least one selection
  └─ Separate items by type
       ↓
INSPECT MODE CONFIGURATION
  ├─ Build unified JSON config
  ├─ Merge Installomator + Jamf items
  ├─ Add cachePaths for download detection
  └─ Validate JSON with jq
       ↓
EXECUTION ENGINE
  ├─ Launch Inspect Mode dialog (background)
  │   └─ Monitors file system for validation paths
  ├─ Process items sequentially
  │   ├─ Installomator: executeInstallomatorLabel()
  │   └─ Jamf: executeJamfPolicy()
  ├─ Inspect Mode auto-detects when paths appear
  └─ Wait for dialog close
       ↓
COMPLETION & RESTART
  ├─ Show completion dialog (success/errors)
  └─ Prompt for restart (if enabled)
```

---

## How Inspect Mode Works

swiftDialog's Inspect Mode **monitors the file system**, not log files. It uses Apple's FSEvents API to detect when files appear.

**What Inspect Mode Does:**
- Watches specified `paths` arrays for each item
- Monitors `cachePaths` for download progress (`.pkg`, `.dmg`, `.download` files)
- Updates item status when validation paths are detected
- Scans every `scanInterval` seconds (default: 2)

**What Inspect Mode Does NOT Do:**
- Parse log files (no `Installomator.log` or `jamf.log` monitoring)
- Track command output
- Monitor process execution

**How Items Complete:**
1. Script executes Installomator or Jamf policy
2. Inspect Mode continuously checks if validation path exists
3. When file appears, item status updates to complete
4. Dialog auto-enables "Close" button when all items done

**Example:**
- Installomator installs `/Applications/Microsoft Word.app`
- Inspect Mode detects when that path exists
- Item automatically marks complete in dialog

---

## Validation & Skip Logic

### Installomator Items
1. **Pre-check:** If validation path exists → skip, log "already exists"
2. **Execute:** Run Installomator with `DEBUG=0 NOTIFY=silent`
3. **Inspect Mode:** Watches validation path, marks complete when app appears
4. **Post-check:** Exit code 0 = success, non-zero = failure

### Jamf Policy Items
1. **Pre-check:** If validation path exists → skip, log "already configured"
2. **Execute:** Run `jamf policy -event <trigger>`
3. **Inspect Mode:** Watches validation path, marks complete when file appears
4. **Post-check:** 
   - Exit code 0 + validation path exists = success
   - Exit code 0 + validation path missing = success (warn)
   - Non-zero exit code = failure

**Important:** Inspect Mode visual feedback is independent of script success/failure tracking. The dialog shows items as complete when paths appear, but the script tracks actual execution success separately.

---

## Customization Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `organizationPreset` | `"1"` | swiftDialog Inspect Mode preset (1-4) |
| `organizationInstallomatorFile` | `/Library/Management/...` | Path to Installomator.sh |
| `jamfBinary` | `/usr/local/bin/jamf` | Path to jamf binary |
| `organizationOverlayiconURL` | swiftDialog logo | Overlay icon URL |
| `mainDialogIcon` | `SF=gearshape.2...` | Main dialog icon |
| `fontSize` | `"14"` | Dialog message font size |
| `restartPromptEnabled` | `"true"` | Show restart prompt after completion |
| `scriptLog` | `/var/log/...log` | Client-side log path |

---

## Logging

**Primary Log:** `/var/log/org.churchofjesuschrist.log`

**Log Levels:**
- `[PRE-FLIGHT]` — Initial checks
- `[NOTICE]` — Major operations
- `[INFO]` — Detailed status updates
- `[WARNING]` — Non-fatal issues
- `[ERROR]` — Failures
- `[FATAL ERROR]` — Script termination

**Output Capture:**
- Installomator output: Captured and logged with `Installomator (label):` prefix
- Jamf policy output: Captured and logged with `Jamf (trigger):` prefix
- All output written to primary script log for troubleshooting

**Inspect Mode Monitoring:**
- Inspect Mode uses file system monitoring (FSEvents), not log parsing
- Items complete when validation paths appear, independent of log output

**Auto-rotation:** Log rotates when exceeds 10MB

---

## Troubleshooting

### swiftDialog not installing
- Check internet connectivity
- Verify GitHub access (not blocked by firewall)
- Manually download from: https://github.com/swiftDialog/swiftDialog/releases

### Items being skipped
- Check validation paths are correct
- Verify apps/files don't already exist
- Review pre-flight log messages

### Jamf policies failing
- Verify jamf binary exists: `ls -l /usr/local/bin/jamf`
- Test trigger manually: `sudo jamf policy -event <trigger>`
- Check policy exists in Jamf Pro and trigger name matches

### Installomator failures
- Verify Installomator path: `ls -l /Library/Management/.../Installomator.sh`
- Test label manually: `sudo /path/to/Installomator.sh <label> DEBUG=1`
- Check label exists and is spelled correctly

### Selection dialog empty
- Verify items are configured in arrays
- Check array syntax (colon-separated fields)
- Review pre-flight log for parsing errors

---

## Testing Checklist

### Before Production
- [ ] Edit `installomatorItems` array with organization's apps
- [ ] Edit `jamfPolicyItems` array with organization's policies
- [ ] Update icon URLs to organization's icons
- [ ] Verify Installomator path matches environment
- [ ] Verify Jamf binary path matches environment
- [ ] Test interactive mode with single item
- [ ] Test silent mode with CSV input
- [ ] Test mixed selection (Installomator + Jamf)
- [ ] Verify validation paths are correct
- [ ] Test failure handling (invalid label/trigger)
- [ ] Test skip logic (pre-installed items)
- [ ] Verify restart prompt behavior

### Functional Tests
1. **Interactive single item:** Select one Installomator label → verify install
2. **Interactive multiple:** Select 2+ items → verify sequential execution
3. **Silent mode:** Run with CSV → verify no dialogs, auto-execute
4. **Mixed execution:** Select both types → verify both execute correctly
5. **Skip logic:** Select already-installed item → verify skip
6. **Failure handling:** Select invalid item → verify error capture
7. **Completion dialog:** Verify success/failure counts accurate
8. **Restart prompt:** Test both "Restart Now" and "Later" buttons

---

## Next Steps

1. **Configure items** — Edit arrays with your organization's apps and policies
2. **Update paths** — Verify Installomator and Jamf paths match your environment
3. **Icon URLs** — Replace example URLs with your organization's icon URLs
4. **Test in VM** — Run through test checklist in non-production environment
5. **Deploy to Self Service** — Add as Jamf Self Service policy with appropriate scope
6. **Monitor logs** — Review `/var/log/org.churchofjesuschrist.log` for operational insights

---

## Support

For issues or questions:
- Review script logs: `/var/log/org.churchofjesuschrist.log`
- Check syntax: `zsh -n /path/to/SYM-Lite.zsh`
- Validate swiftDialog: `/usr/local/bin/dialog --version`
- Test Installomator: `sudo /path/to/Installomator.sh <label> DEBUG=1`
- Test Jamf trigger: `sudo jamf policy -event <trigger> -verbose`

---

**Script Location:** `/Users/[redacted]/Documents/GitHub/Setup-Your-Mac/Resources/SYM-Lite.zsh`  
**Version:** 0.0.1a1  
**Date:** March 26, 2026  
**Author:** Dan K. Snelson (@dan-snelson)
