# CHANGELOG

## 1.16.0
### 19-Feb-2026
- Added proof-of-concept validations for swiftDialog `2.5.1`'s "blurscreen" control
- Removed vendor-specific Local Validations (in favor of Remote Validations)
- Updated Configuration `policyJSON` to better match internal usage
- Added "activate" command to Validations
- Updated the Microsoft Teams message template to the new format  (Pull Request #156; thanks, @nlopezUA!)
- Simplify Client-side Logging (thanks, @DevliegereM!)
- Added proof-of-concept validations for swiftDialog `2.5.6`'s "hide or show" dialog window
- Updated Dynamic Download Estimates for macOS 26 (and beyond)
- Updated for swiftDialog `3.0.0`
- Updated `checkNetworkQualityCatchAllConfiguration` for macOS 26 (thanks for the heads-up, @Harald Brouwers!)
- Added new salutation banner greeting, based on time o’ day (Pull Request #171; thanks, @ScottEKendall!)
- Add configurable battery threshold to AC power pre-flight check (Pull Request #175; thanks, @owainri!)

## 1.15.1
### 06-Feb-2025
- Fixed minor issue with `calculateFreeDiskSpace` function result not being parsed into scriptLog (thanks, @robjschroeder!)

## 1.15.0
### 11-Jun-2024
- Added logging functions [Pull Request No. 137](https://github.com/setup-your-mac/Setup-Your-Mac/pull/137); thanks, @robjschroeder!
- Modified Microsoft Teams Message `activitySubtitle`
- Activated main "Setup Your Mac" dialog with each `listitem`
- Added swiftDialog `2.5.0`'s `--verbose`, `--debug` and `--resizable` flags to debugModes
- Failure Message: Increased `sleep` value from `0.3` to `0.7` (thanks, for the report, @arnoldtaw; thanks for the code suggestion, @jcmbowman)
- Miscellaneous formatting and clean-up
- Added Support Team fields (thanks, @HowardGMac!)
- Set `swiftDialogMinimumRequiredVersion` to `2.5.0.4768`
- Improved exit code processing for 'Welcome' dialog
- Added pre-flight check for AC power (thanks for the suggestion, @arnoldtaw; thanks for the code, Obi-Josh!)
- Added Variables for Prefill Email and Computer Name (thanks, @AndrewMBarnett!)
- Improved Remote Validation error-checking
- Updated Dynamic Download Estimates for macOS 15 Sequoia

## 1.14.2
### 15-Feb-2024
- Addresses [Issue 139](https://github.com/setup-your-mac/Setup-Your-Mac/issues/139) `brandingBannerDisplayText=false` not working (thanks for the report, @seaneldridge7!)
  Thanks for the fix, @drtaru! [Pull Request No. 140](https://github.com/setup-your-mac/Setup-Your-Mac/pull/140)

## 1.14.1
### 11-Feb-2024
- Addressed an issue where icons were not displaying (thanks, @bartreardon!)

## 1.14.0
### 05-Feb-2024
- Updated Vimeo ID
- Corrected omission of [SYM-Helper] for `moveableInProduction`
- Updated "Microsoft Office 365" to "Microsoft 365"
- Added OS Build number to webhook output [Pull Request No. 124](https://github.com/dan-snelson/Setup-Your-Mac/pull/124); thanks, @drtaru!
- Changed filepath validation test from `-f` (i.e., "True if file exists and is a regular file") to `-e` (i.e., "True if file exists (regardless of type)."); thanks for the inspiration, @mrmte! [Issue 19](https://github.com/BIG-RAT/SYM-Helper/issues/19); thanks for the code suggestion, @bartreardon!
- Updates to `README.md`, `CONTRIBUTORS.md` and `CONTRIBUTING.md` [Pull Request No. 128](https://github.com/setup-your-mac/Setup-Your-Mac/pull/128); thanks, @robjschroeder!
- Refactored the way `brandingBanner` variable is checked [Pull Request No. 131](https://github.com/setup-your-mac/Setup-Your-Mac/pull/131); thanks, @drtaru!
- Increased minimum required version of swiftDialog to `2.4.0.4750`
- Leveraged the new `listitem: subtitle` option with a dedicated `subtitle` field in `policyJSON`
- Corrected misspelling of "policies" in log entries [Issue No. 134](https://github.com/setup-your-mac/Setup-Your-Mac/issues/134); thanks, @Honestpuck!
- Updated `brandingBanner` to [image by benzoix on Freepik](https://www.freepik.com/author/benzoix)

## 1.13.0
### 24-Oct-2023
- 🔥 **Breaking Change** for users of Setup Your Mac prior to `1.13.0` 🔥 
    - Removed `setupYourMacPolicyArrayIconPrefixUrl` (in favor using the fully qualified domain name of the server which hosts your icons)
- Added [SYM-Helper] to identify variables which can be configured in SYM-Helper (0.8.0)
- Updated sample banner image (Image by pikisuperstar on Freepik)
- Added `overlayoverride` variable to dynamically override the `overlayicon`, based on which Configuration is selected by the end-user ([Pull Request No. 111](https://github.com/dan-snelson/Setup-Your-Mac/pull/111); thanks yet again, @drtaru!)
- Modified the display of support-related information (including adding `supportTeamWebsite` (Addresses [Issue No. 97](https://github.com/dan-snelson/Setup-Your-Mac/issues/97); thanks, @theahadub!))
- Adjustments to Completion Actions (including the `wait` flavor; thanks for the heads-up, @Tom!)
- Updated Microsoft Teams filepath validation
- Add position prompt (Addresses [Issue No. 120](https://github.com/dan-snelson/Setup-Your-Mac/issues/120); thanks for the suggestion, @astrugatch! [Pull Request No. 121](https://github.com/dan-snelson/Setup-Your-Mac/pull/121); thanks, @drtaru! This has to be your best one yet!)
- Corrections to "Continue" button after Network Quality test [Pull Request No. 115](https://github.com/dan-snelson/Setup-Your-Mac/pull/115); thanks, @delize!

## 1.12.12
### 28-Sep-2023
- Added a failure indication when a "Local" validation trigger does not exist in the main script ([Pull Request No. 117](https://github.com/dan-snelson/Setup-Your-Mac/pull/117); thanks for another one, @drtaru!)

## 1.12.11
### 26-Sep-2023
- Restored logging of `jamfProPolicyNameFailures`
- Updated `if … then` statements when disabling the "Continue" button in the User Input "Welcome" dialog until Dynamic Download Estimates have complete ([Pull Request No. 115](https://github.com/dan-snelson/Setup-Your-Mac/pull/116); thanks, @delize!)

## 1.12.10
### 15-Sep-2023
- Better WelcomeMessage logic and variable handling ([Pull Request No. 101](https://github.com/dan-snelson/Setup-Your-Mac/pull/101); thanks big bunches, @GadgetGeekNI!)

## 1.12.9
### 15-Sep-2023
- Added `-L` to `curl` command when caching banner images (thanks for the suggestion, @bartreardon!)
- Added `swiftDialogMinimumRequiredVersion` variable to more easily track the minimum build. ([Pull Request No. 98](https://github.com/dan-snelson/Setup-Your-Mac/pull/98); thanks, @GadgetGeekNI!)
- Hide unused Support variables ([Pull Request No. 99](https://github.com/dan-snelson/Setup-Your-Mac/pull/99); thanks again, @GadgetGeekNI!)
- Added Pre-flight Check: Validate `supportTeam` variables are populated ([Pull Request No. 100](https://github.com/dan-snelson/Setup-Your-Mac/pull/100); thanks for another one, @GadgetGeekNI!)

## 1.12.8
### 13-Sep-2023
- Added a check for FileVault being enabled during Setup Assistant (for macOS 14 Sonoma) ([Pull Request No. 96](https://github.com/dan-snelson/Setup-Your-Mac/pull/96); thanks, Obi-@drtaru!)

## 1.12.7
### 09-Sep-2023
- Added ability disable the "Continue" button in the User Input "Welcome" dialog until Dynamic Download Estimates have complete ([Pull Request No. 93](https://github.com/dan-snelson/Setup-Your-Mac/pull/93); thanks, @Eltord!)
- Added a check to account for if the `loggedInUser` returns in ALL CAPS (as this sometimes happens with SSO Attributes) ([Pull Request No. 94](https://github.com/dan-snelson/Setup-Your-Mac/pull/94); thanks for another one, @Eltord!)
- Added a Pre-flight Check for the running shell environment: Will exit gracefully if the shell does not match \bin\bash. ([Pull Request No. 95](https://github.com/dan-snelson/Setup-Your-Mac/pull/95); thanks — yet again — @drtaru!)
- Remove any default dialog file

## 1.12.6
### 30-Aug-2023
- Reverted `mktemp`-created files to pre-SYM `1.12.1` behaviour
- Updated required version of swiftDialog to `2.3.2.4726`

## 1.12.5
### 28-Aug-2023
- Added `sleep "${debugModeSleepAmount}"` to `recon` validation

## 1.12.4
### 26-Aug-2023
- `toggleJamfLaunchDaemon` (during `quitScript` function) based on `completionActionOption` ([Pull Request No. 89](https://github.com/dan-snelson/Setup-Your-Mac/pull/89); thanks for another one, @TechTrekkie!)

## 1.12.3
### 23-Aug-2023
- Changed `dialogURL` to new GitHub Repo ([Pull Request No. 88](https://github.com/dan-snelson/Setup-Your-Mac/pull/88); thanks yet again, @drtaru!)

## 1.12.2
### 22-Aug-2023
- Updated minimum version of macOS to 12
- Corrected deletion of cached welcomeBannerImage

## 1.12.1
### 21-Aug-2023
- Added permissions correction on ALL `mktemp`-created files (for swiftDialog `2.3.1`)
- Updated required version of swiftDialog to `2.3.1.4721`

## 1.12.0
### 21-Aug-2023
- Add version check to `dialogCheck` ([Pull Request No. 67](https://github.com/dan-snelson/Setup-Your-Mac/pull/67); thanks yet again, @drtaru!)
- Make `presetConfiguration` also apply to `userInput` ([Pull Request No. 63](https://github.com/dan-snelson/Setup-Your-Mac/pull/63); thanks for another one, @rougegoat!)
- Fix for visual hiccup where `infobox` displays "Analyzing input …" if `configurationDownloadEstimation` and `promptForConfiguration` are both set to `false` ([Pull Request No. 69](https://github.com/dan-snelson/Setup-Your-Mac/pull/69); thanks yet again, @rougegoat!)
- Added networkQuality check for macOS Sonoma 14
- Formatting updates
- Updated Palo Alto GlobalProtect icon hash
- Changed "Restart Attended" Completion Action one-liner (Addresses [Issue No. 71](https://github.com/dan-snelson/Setup-Your-Mac/issues/71); thanks, @master-vodawagner!)
- Delay the removal of `overlayicon` (Addresses [Issue No. 73](https://github.com/dan-snelson/Setup-Your-Mac/issues/73); thanks, @mani2care!)
- Added `reconOption` prompts for `realname` and `email` (Addresses [Issue No. 52](https://github.com/dan-snelson/Setup-Your-Mac/issues/52); thanks for the suggestion @brianhm; thanks for the code, @Siggloo!)
- Changed dialog heights to percentages
- Auto-cache / auto-remove a hosted welcomeBannerImage (Addresses [Issue No. 74](https://github.com/dan-snelson/Setup-Your-Mac/issues/74)
- Added a `welcomeDialog` option of `messageOnly` (Addresses [Issue No. 66](https://github.com/dan-snelson/Setup-Your-Mac/issues/66); thanks for the suggestion, @ryanasik)
- Reverted "Restart Attended" Completion Action one-liner (Unaddresses [Issue No. 71](https://github.com/dan-snelson/Setup-Your-Mac/issues/71); sorry, @master-vodawagner)
- Set newly added email address to required (regex courtesy of @bartreardon) (Addresses [Issue No. 75](https://github.com/dan-snelson/Setup-Your-Mac/issues/75); thanks for the suggestion, @ryanasik)
- Added code to pre-fill user's full name (Addresses [Issue No. 76](https://github.com/dan-snelson/Setup-Your-Mac/issues/76); thanks for the suggestion, @ryanasik)
- Reverted dialog heights to pixels
- Updated Vimeo video ID
- Updated `serialNumber` code (with special thanks to @Eltord for saving each and every user `0.0.6` seconds)
- Added `suppressReconOnPolicy` variable; when set to `true`, a `-forceNoRecon` flag when executing the `run_jamf_trigger` function (Addresses [Issue No. 79](https://github.com/dan-snelson/Setup-Your-Mac/issues/79); thanks for the idea, @fitzwater-rowan; thanks for yet another PR, @rougegoat!)
- Added "Install Buffers" to each Configuration to include installation time of packages (Addresses [Issue No. 78](https://github.com/dan-snelson/Setup-Your-Mac/issues/78); thanks, @Eltord!
- Added permissions correction on `mktemp`-created files (for swiftDialog `2.3`)
- Updated required version of swiftDialog to `2.3.0.4718`

## 1.11.0
### 24-May-2023
[Release-specific Blog Post](https://snelson.us/2023/05/setup-your-mac-1-11-0-via-swiftdialog-2-2/)
- Updates for `swiftDialog` `2.2`
  - Required `selectitems`
  - New `activate` command to bring swiftDialog to the front
  - Display Configurations as radio buttons
- Report on RSR version (if applicable) [Pull Request No. 50](https://github.com/dan-snelson/Setup-Your-Mac/pull/50) thanks @drtaru!)
- Specify a Configuration as Parameter `11` ([Pull Request No. 59](https://github.com/dan-snelson/Setup-Your-Mac/pull/59); thanks big bunches, @drtaru!. Addresses [Issue No. 58](https://github.com/dan-snelson/Setup-Your-Mac/issues/58); thanks for the idea, @nunoidev!)
- Configuration Names and Descriptions as variables ([Pull Request No. 60](https://github.com/dan-snelson/Setup-Your-Mac/pull/60); great idea! thanks, @theadamcraig!)
- Consolidated Jamf Pro-related webHookMessage variables; Set "Additional Comments" to "None" when there aren't any failures

## 1.10.1
### 22-May-2023
[Release-specific Blog Post](https://snelson.us/2023/05/setup-your-mac-1-10-0-via-swiftdialog)
- Removed "(beta)" from Dynamic Download Estimates
- Added `promptForBuilding` and `promptForDepartment` to match other prompts for Welcome Screen ([Pull Request No. 55](https://github.com/dan-snelson/Setup-Your-Mac/pull/55); thanks @robjschroeder!)
- Rearranged "Pre-flight Check: Validate Logged-in System Accounts"
- Eliminated a visual "glitch" when `promptForConfiguration` is `false` and `configurationDownloadEstimation` is `true` (_Sort of_ addresses [Issue No. 56](https://github.com/dan-snelson/Setup-Your-Mac/issues/56); thanks for the heads-up, @rougegoat!)
- Eliminated the visual "glitch" when `welcomeDialog` is `false`

## 1.10.0
### 08-May-2023
[Release-specific Blog Post](https://snelson.us/2023/05/setup-your-mac-1-10-0-via-swiftdialog)
- 🆕 **Dynamic Download Estimates** (Addresses [Issue No. 7](https://github.com/dan-snelson/Setup-Your-Mac/issues/7); thanks for the idea, @DevliegereM; heavy-lifting provided by @bartreardon!)
    - Manually set `configurationDownloadEstimation` within the SYM script to `true` to enable
    - New `calculateFreeDiskSpace` function will record free space to `scriptLog` before and after SYM execution
        - Compare before and after free space values via: `grep "free" $scriptLog`
    - Populate the following variables, in Gibibits (i.e., Total File Size in Gigabytes * 7.451), for each Configuration:
        - `configurationCatchAllSize`
        - `configurationOneSize`
        - `configurationTwoSize`
        - `configurationThreeSize`
    - Specify an arbitrary value for `correctionCoefficient` (i.e., a "fudge factor" to help estimates match reality)
        - Validate actual elapsed time with: `grep "Elapsed" $scriptLog`
- 🔥 **Breaking Change** for users of Setup Your Mac prior to `1.10.0` 🔥 
    - Added `recon` validation, which **must** be used when specifying the `recon` trigger (Addresses [Issue No. 19](https://github.com/dan-snelson/Setup-Your-Mac/issues/19))
- Standardized formatting of `toggleJamfLaunchDaemon` function
  - Added logging while waiting for installation of `${jamflaunchDaemon}`
- Limit the `loggedInUserFirstname` variable to `25` characters and capitalize its first letter (Addresses [Issue No. 20](https://github.com/dan-snelson/Setup-Your-Mac/issues/20); thanks @mani2care!)
- Added line break to `welcomeTitle` and `welcomeBannerText`
- Replaced some generic "Mac" instances with hardware-specific model name (thanks, @pico!)
- Replaced `verbose` Debug Mode code with `outputLineNumberInVerboseDebugMode` function (thanks, @bartreardon!)
- Removed dependency on `dialogApp`
- Check `bannerImage` and `welcomeBannerImage` ([Pull Request No. 22](https://github.com/dan-snelson/Setup-Your-Mac/pull/22) **AND** [Pull Request No. 24](https://github.com/dan-snelson/Setup-Your-Mac/pull/24) thanks @amadotejada!)
- A "raw" unsorted listing of departments — with possible duplicates — is converted to a sorted, unique, JSON-compatible `departmentList` variable (Addresses [Issue No. 23](https://github.com/dan-snelson/Setup-Your-Mac/issues/23); thanks @rougegoat!)
- The selected Configuration now displays in `helpmessage` (Addresses [Issue No. 17](https://github.com/dan-snelson/Setup-Your-Mac/issues/17); thanks for the idea, @master-vodawagner!)
- Disable the so-called "Failure" dialog by setting the new `failureDialog` variable to `false` (Addresses [Issue No. 25](https://github.com/dan-snelson/Setup-Your-Mac/issues/25); thanks for the idea, @DevliegereM!)
- Added function to send a message to Microsoft Teams [Pull Request No. 29](https://github.com/dan-snelson/Setup-Your-Mac/pull/29) thanks @robjschroeder!)
- Added Building & Room User Input, Centralize User Input settings in one area [Pull Request No. 26](https://github.com/dan-snelson/Setup-Your-Mac/pull/26) thanks @rougegoat!)
- Replaced Parameter 10 with webhookURL for Microsoft Teams messaging ([Pull Request No. 31](https://github.com/dan-snelson/Setup-Your-Mac/pull/31) @robjschroeder, thanks for the idea @colorenz!!)
- Added an action card to the Microsoft Teams webhook message to view the computer's inventory record in Jamf Pro ([Pull Request No. 32](https://github.com/dan-snelson/Setup-Your-Mac/pull/32); thanks @robjschroeder!)
- Additional User Input Flags ([Pull Request No. 34](https://github.com/dan-snelson/Setup-Your-Mac/pull/34); thanks @rougegoat!)
- Corrected Dan's copy-pasta bug: Changed `--webHook` to `--data` ([Pull Request No. 36](https://github.com/dan-snelson/Setup-Your-Mac/pull/36); thanks @colorenz!)
- Enable or disable any combination of the fields on the Welcome dialog ([Pull Request No. 37](https://github.com/dan-snelson/Setup-Your-Mac/pull/37); thanks big bunches, @rougegoat!!)
- Moved various `shellcheck disable` codes sprinkled throughout script front-and-center to Line No. `2`
- Add Remote Validation results of "Success" or "Installed" to update the List Item with "Installed" instead of "Running" ([Pull Request No. 41](https://github.com/dan-snelson/Setup-Your-Mac/pull/41); thanks @drtaru!)
- Option to disable Banner Text ([Pull Request No. 42](https://github.com/dan-snelson/Setup-Your-Mac/pull/42); thanks, @rougegoat!)
- Switch `policy -trigger` to `policy -event` (Addresses [Issue No. 38](https://github.com/dan-snelson/Setup-Your-Mac/issues/38); thanks for looking out for us, @delize!)
- Resolves an issue when `promptForConfiguration` is NOT set to `true`, the `checkNetworkQualityConfigurations` function would display in the "Welcome" dialog (Addresses [Issue No. 46](https://github.com/dan-snelson/Setup-Your-Mac/issues/46); thanks, @jonlonergan!)
- Corrected capitalization of `networkQuality`
- Added `trigger` `validation` to "Elapsed Time" output
- Updated `webhookMessage` to include Slack functionality ([Pull Request No. 48](https://github.com/dan-snelson/Setup-Your-Mac/pull/48); thanks @iDrewbs!)
- Add button to computer record for Slack webhook ([Pull Request No. 49](https://github.com/dan-snelson/Setup-Your-Mac/pull/49); thanks @drtaru!)
- Fix Banner Text displaying when set to False ([Pull Request No. 51](https://github.com/dan-snelson/Setup-Your-Mac/pull/51); thanks @rougegoat!)

## 1.9.0
### 01-Apr-2023
[Release-specific Blog Post](https://snelson.us/2023/04/setup-your-mac-1-9-0-via-swiftdialog/)
- Previously installed apps with a `filepath` validation now display "Previously Installed" (instead of a generic "Installed"; [Issue No. 13](https://github.com/dan-snelson/Setup-Your-Mac/issues/13); thanks for the idea, @Manikandan!)
- Allow "first name" to correctly handle names in "Lastname, Firstname" format ([Pull Request No. 11](https://github.com/dan-snelson/Setup-Your-Mac/pull/11); thanks @meschwartz!)
- Corrected `PATH` (thanks, @Theile!)
- `Configuration` no longer displays in SYM's `infobox` when `welcomeDialog` is set to `false` or `video` (Addresses [Issue No. 12](https://github.com/dan-snelson/Setup-Your-Mac/issues/12); thanks, @Manikandan!)
- Updated icon hashes
- `toggleJamfLaunchDaemon` function ([Pull Request No. 16](https://github.com/dan-snelson/Setup-Your-Mac/pull/16); thanks, @robjschroeder!)
- Formatted policyJSON with [Erik Lynd's JSON Tools](https://marketplace.visualstudio.com/items?itemName=eriklynd.json-tools)
- Corrected an issue where inventory would be submitted twice (thanks, @Manikandan!)

## 1.8.1
### 11-Mar-2023
[Release-specific Blog Post](https://snelson.us/2023/03/setup-your-mac-1-8-0-via-swiftdialog/)
- Added `currentLoggedInUser` function to better validate `loggedInUser` (Addresses [Issue No. 2](https://github.com/dan-snelson/Setup-Your-Mac/issues/2))
- Added new [Microsoft Office 365](/Setup-Your-Mac/Validations/Microsoft%20Office%20365.bash) Remote Validation ([Pull Request No. 3](https://github.com/dan-snelson/Setup-Your-Mac/pull/3))
- Improved logging when `welcomeDialog` is `video` or `false` (Addresses [Issue No. 4](https://github.com/dan-snelson/Setup-Your-Mac/issues/4))
- Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)

## 1.8.0
### 06-Mar-2023
[Release-specific Blog Post](https://snelson.us/2023/03/setup-your-mac-1-8-0-via-swiftdialog/)
- Introduces fully customizable "Configurations" (thanks, [@drtaru](https://github.com/drtaru)!)
    - **Required:** Minimum organizational apps (i.e., full disk encryption, endpoint security, VPN, communication tools, etc.)
    - **Recommended:** Required apps and Microsoft Office
    - **Complete:** Recommended apps, Adobe Acrobat Reader and Google Chrome
- Play video at Welcome dialog (Script Parameter `6`) by specifying `video` (Addresses [Issue No. 36](https://github.com/dan-snelson/dialog-scripts/issues/36))
  - 🔥 **Breaking Change** for users of Setup Your Mac prior to `1.8.0` 🔥 
      - To capture user input, `welcomeDialog` (Script Parameter `6`) must be set to `userInput`
- Addresses [Issue No. 39](https://github.com/dan-snelson/dialog-scripts/issues/39) (thanks big bunches, [@wako](https://github.com/wakco)!)
- Addresses [Issue No. 43](https://github.com/dan-snelson/dialog-scripts/issues/39) (thanks, @wako)
- Removed the following fields from the Welcome dialog
  - Comment
  - Select B
  - Select C

## 1.7.2
### 28-Feb-2023
[Release-specific Blog Post](https://snelson.us/2023/02/setup-your-mac-via-swiftdialog-1-7-0/)
- Reordered Pre-Flight Check to not validate OS until AFTER Setup Assistant / Finder & Dock
- Added `disabled` option for `requiredMinimumBuild`
- Added check for Self Service's `brandingimage.png` (Addresses [Issue No. 40](https://github.com/dan-snelson/dialog-scripts/issues/40))
- Pre-flight Check logging messages now saved to client-side log
- Addresses [Issue No. 41](https://github.com/dan-snelson/dialog-scripts/issues/41)

## 1.7.1
### 07-Feb-2023
[Release-specific Blog Post](https://snelson.us/2023/02/setup-your-mac-via-swiftdialog-1-7-0/)
- Addresses [Issue No. 35](https://github.com/dan-snelson/dialog-scripts/issues/35)
- Improves user-interaction with `helpmessage` under certain circumstances (thanks, @bartreardon!)
- Increased `debugMode` delay (thanks for the heads-up, @Lewis B!)
- Changed Banner Image (to something much, much smaller)

## 1.7.0
### 01-Feb-2023
[Release-specific Blog Post](https://snelson.us/2023/02/setup-your-mac-via-swiftdialog-1-7-0/)
- Adds compatibility for and leverages new features of [swiftDialog](https://github.com/bartreardon/swiftDialog/blob/main/README.md) `2.1`
  - `bannertext`
  - `helpmessage`
  - `infobox`
  - `progress`-related racing-stripes (which now **require** `swiftDialog 2.1+`)
- Completion Actions
  - Adjusted default code option (to hopefully help Mac Admins using an Enrollment Complete trigger [i.e., `runAsUser` doesn't work too well when `_mbsetupuser` is the logged-in user])
- Combined `listitem` steps for installation and validation (thanks, @roiegat!)
  - Addresses [Issue No. 30](https://github.com/dan-snelson/dialog-scripts/issues/30)
- Validate Operating System Version, Build and Outdated OS Action
  - Addresses [Issue No. 31](https://github.com/dan-snelson/dialog-scripts/issues/31)
  - Introduces the ability to specify a `requiredMinimumBuild` as Script Parameter `8` (thanks, @SirDrSpiderpig!)
    - For example, to only allow macOS Ventura 13.2 (or later), specify: `22D`
  - Introduces Outdated OS Action
    - Open Self Service to your OS update policy: `jamfselfservice://content?entity=policy&id=117&action=view`
    - Open Software Update (default): `/System/Library/CoreServices/Software Update.app`
- Temporarily disables `jamf` binary check-in (thanks, @mactroll and @cube!)
  - Purposely commented-out the code to re-enable the `jamf` binary; presumes the Mac will be restarted
- Separated "Global Variables" from "Dialog Variables" to allow for additional Script Parameters 
- Improved Pre-flight Check messaging
- Introduces `verbose` as an option for `Debug Mode`
  - Most useful when first deploying Setup Your Mac



## 1.6.0
### 09-Jan-2023
[Release-specific Blog Post](https://snelson.us/2023/01/setup-your-mac-via-swiftdialog-1-6-0/)
- Addresses [Issue No. 21](https://github.com/dan-snelson/dialog-scripts/issues/21)
  - 🔥 **Breaking Change** 🔥 (for users of Setup Your Mac prior to `1.6.0`)
      - `policy_array`'s "`path`" has been replaced with "`validation`"
  - 🆕 The `confirmPolicyExecution` function confirms if the policy needs to be executed for `filepath` validations
    - A validation of `None` always executes the Jamf Pro trigger when `debug mode` is set to `false`
  - 🆕 The `validatePolicyResult` function validates if the policy succeeded and the related service is _running_, based on the specified `validation` option
    - [Feature-specific Blog Post](https://snelson.us/2023/01/setup-your-mac-validation/)
    - **Validation Options:**
       - {absolute path} (simulates pre-`1.6.0` behavior, for example: `"/Applications/Microsoft Teams.app/Contents/Info.plist"`)
       - `Local` (for validation within this script, for example: `"filevault"`)
       - `Remote` (for validation validation via a single-script Jamf Pro policy, for example: `"symvGlobalProtect"`)
       - `None` (for triggers which don't require validation, for example: `recon`; always evaluates as successful)
- Enhanced policy logging options to address [Issue No. 25](https://github.com/dan-snelson/dialog-scripts/issues/25)
  - Search for and comment-out: `eval "${jamfBinary} policy -trigger ${trigger}"`
  - Uncomment: `eval "${jamfBinary} policy -trigger ${trigger} -verbose | tee -a ${scriptLog}"`
  - Ensure `debug mode` is set to `false`
- Added Rosetta 2 policy execution and validation
- Enhanced Logging
  - Addresses [Issue No. 29](https://github.com/dan-snelson/dialog-scripts/issues/29)


##  1.5.1
### 07-Dec-2022
[Release-specific Blog Post](https://snelson.us/2022/12/setup-your-mac-via-swiftdialog-1-5-1/)
- Updates to "Pre-flight Checks"
  - Moved section to start of script
  - :new: Added additional check for Setup Assistant (for Mac Admins using an "Enrollment Complete" trigger)

##  1.5.0
### 28-Nov-2022
[Release-specific Blog Post](https://snelson.us/2022/11/setup-your-mac-via-swiftdialog-1-5-0/)
- :new: Prompt user for additional fields at Welcome dialog
  - New fields are included in a single `welcomeJSON` variable (thanks for all your efforts and feedback, @drtaru and @Andrew!)
    - See [welcomeScreenTesting.bash](JSON/welcomeScreenTesting.bash) (thanks, @bartreardon!)
    - In **Debug Mode**, changes are logged only (thanks, @Andrew!)
  - Dynamic `reconOptions` based on user's input at the **Welcome** dialog
  - Thanks for your patience, @remusache, @midiman1000, @erikmadams, @colorenz and @benphilware
- :fire: **Breaking Changes** :fire: (for users of **Setup Your Mac** prior to `1.5.0`)
  - Script Parameter Reordering (sorry; I'll strive not to ever do this again)
    - **Parameter 4:** Script Log Location [ `/var/tmp/org.churchofjesuschrist.log` ]
    - **Parameter 5:** Debug Mode [ `true` (default) | `false` ]
    - **Parameter 6:** Welcome dialog [ `true` (default) | `false` ]
    - **Parameter 7:** Completion Action [ `wait` | `sleep` (with seconds) | `Shut Down` | `Shut Down Attended` | `Shut Down Confirm` | `Restart` |  **`Restart Attended`(default)** | `Restart Confirm` | `Log Out` | `Log Out Attended` | `Log Out Confirm` ]
- Miscellaneous Improvements
  - Moved code blocks and variables to better reflect the **Welcome** > **Setup Your Mac** > **Failure** workflow
  - Random code clean-up


## 1.4.0
### 21-Nov-2022
[Release-specific Blog Post](https://snelson.us/2022/11/setup-your-mac-via-swiftdialog-1-3-1)
- Significantly enhanced **Completion Action** options
  - :white_check_mark: Addresses [Issue 15](https://github.com/dan-snelson/dialog-scripts/issues/15) (thanks, @mvught, @riddl0rd, @iDrewbs and @master-vodawagner)
  - :tada: Dynamically set `button1text` based on the value of `completionActionOption` (thanks, @jared-a-young)
  - :partying_face: Dynamically set `progresstext` based on the value of `completionActionOption` (thanks, @iDrewbs)
  - :new: Three new flavors: **Shut Down**, **Restart** or **Log Out**
    - :rotating_light: **Forced:** Zero user-interaction
      - Added brute-force `killProcess "Self Service"`
      - Added `hack` to allow Policy Logs to be shipped to Jamf Pro server
    - :warning: **Attended:** Forced, but only _after_ user-interaction (thanks, @owainiorwerth)
      - Added `hack` to allow Policy Logs to be shipped to Jamf Pro server
    - :bust_in_silhouette: **Confirm:** Displays built-in macOS _user-dismissible_ dialog box
  - Sleep
  - Wait (default)
- Improved **Debug Mode** behavior
  - :bug: `DEBUG MODE |` now only displayed as `infotext` (i.e., bottom, left-hand corner)
  - `completionAction` informational-only with simple dialog box (thanks, @_____???)
  - Swapped `blurscreen` for `moveable`
  - General peformance increases
- Miscellaneous Improvements
  - Removed `jamfDisplayMessage` function and reverted `dialogCheck` function to use `osascript` (with an enhanced error message)
  - Replaced "Installing …" with "Updating …" for `recon`-flavored `trigger`
  - Changed "Updating Inventory" to "Computer Inventory" for `recon`-flavored `listitem`
  - Changed exit code to `1` when user quits "Welcome" screen
  - Changed `welcomeIcon` URLs
  - Changed URL for Harvesting Self Service icons screencast (thanks, @nstrauss)



## 1.3.0
### 09-Nov-2022
[Release-specific Blog Post](https://snelson.us/2022/11/setup-your-mac-via-swiftdialog-1-3-0/)
- **Script Parameter Changes:**
  - :warning: **Parameter 4:** `debug` mode **enabled** by default
  - :new: **Parameter 7:** Script Log Location
- :new: Embraced _**drastic**_ speed improvements in :bullettrain_front:`swiftDialog v2`:dash:
- Caffeinated script (thanks, @grahampugh!)
- Enhanced `wait` exiting logic
- General script standardization

## 1.2.10
### 05-Oct-2022 
- Modifications for swiftDialog v2 (thanks, @bartreardon!)
  - Added I/O pause to `dialog_update_setup_your_mac`
  - Added `list: show` when displaying policy_array
  - Re-ordered Setup Your Mac progress bar commands
- More specific logging for various dialog update functions
- Confirm Setup Assistant complete and user at Desktop (thanks, @ehemmete!)

## 1.2.9
### 03-Oct-2022
- Added `setupYourMacPolicyArrayIconPrefixUrl` variable (thanks for the idea, @mani2care!)
- Removed unnecessary `listitem` icon updates (thanks, @bartreardon!)
- Output swiftDialog version when running in debug mode
- Updated URL for Zoom icon
## 1.2.8
### 19-Sep-2022

- Replaced "ugly" `completionAction` `if … then … else` with "more readabale" `case` statement (thanks, @pyther!)
- Updated "method for determining laptop/desktop" (thanks, @acodega and @scriptingosx!)
- Additional tweaks discovered during internal production deployment
## 1.2.7
### 10-Sep-2022
[Release-specific Blog Post](https://snelson.us/2022/09/setup-your-mac-via-swiftdialog-1-2-7/)
- Added "completionAction" (Script Parameter 6) to address [Pull Request No. 5](https://github.com/dan-snelson/dialog-scripts/pull/5)
- Added "Failure" dialog to address [Issue No. 6](https://github.com/dan-snelson/dialog-scripts/issues/6)
## 1.2.6
### 29-Aug-2022
- Adjust I/O timing (for policy_array loop)
## 1.2.5
### 24-Aug-2022
- Resolves https://github.com/dan-snelson/dialog-scripts/issues/3 (thanks, @pyther!)

## 1.2.4

### 18-Aug-2022
[Release-specific Blog Post](https://snelson.us/2022/06/setup-your-mac-via-swiftdialog-1-2-1/)
- Swap "Installing …" and "Pending …" status indicators (thanks, @joncrain)
## 1.2.3
### 15-Aug-2022
- Updates for switftDialog v1.11.2
- Report failures in Jamf Pro Policy Triggers

## 1.2.2
### 07-Jun-2022
- Added "dark mode" for logo (thanks, @mm2270)
- Added "compact" for `--liststyle`

## 1.2.1
### 01-Jun-2022
- Made Asset Tag Capture optional (via Jamf Pro Script Paramter 5)

## 1.2.0
### 30-May-2022
- Changed `--infobuttontext` to `--infotext`
- Added `regex` and `regexerror` for Asset Tag Capture
- Replaced @adamcodega's `apps` with @smithjw's `policy_array`
- Added progress update
- Added filepath validation

## 1.1.0
### 19-May-2022
- Added initial "Welcome Screen" with Asset Tag Capture and Debug Mode

## 1.0.0
### 30-Apr-2022
-  First "official" release