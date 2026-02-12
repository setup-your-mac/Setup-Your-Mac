# AGENTS.md (Setup Your Mac, version 1.16.0)

These instructions are for AI coding agents working in this repository.

## Scope and priority

- Primary focus: `Setup-Your-Mac-via-Dialog.bash`
- Secondary files (edit only when required by the task): `Prompt-to-Setup-Your-Mac.bash`, `Validations/*`, docs
- Preserve behavior unless the user explicitly asks to change it

## Project context

`Setup-Your-Mac-via-Dialog.bash` is a production enrollment workflow script that:

- runs as `root`
- drives end-user UI with swiftDialog
- executes Jamf Pro custom policy events
- depends on guardrails (pre-flight checks, dependency checks, exit handling, logging)

Breakages can affect zero-touch onboarding and first-run usability. Optimize for operational safety.

## Non-negotiables

### Preserve SYM-Helper compatibility

Anything marked `[SYM-Helper]` in `Setup-Your-Mac-via-Dialog.bash` is externally managed by SYM-Helper.

- Do not remove `[SYM-Helper]` markers
- Do not rename, repurpose, or silently change semantics of `[SYM-Helper]` variables
- Do not change expected value formats for `[SYM-Helper]` variables without explicit request

### Maintain operational safety

- Keep dependency and environment checks intact (`root`, shell/runtime checks, swiftDialog/Jamf assumptions)
- Do not bypass failure paths or exit-code handling
- Do not break dialog launch/update/quit flow
- Do not reduce logging coverage in existing critical paths

## Editing rules for `Setup-Your-Mac-via-Dialog.bash`

- Keep script parameter numbering stable (`$4`, `$5`, etc.) unless explicitly requested
- Keep default parameter values backward compatible unless explicitly requested
- Reuse existing helpers/functions (`logMessage`, `runAsUser`, etc.) instead of ad-hoc patterns
- Prefer small, localized diffs over broad refactors
- Match existing Bash style and quoting conventions in surrounding code
- Use `lowerCamelCase` for new variable and function names unless matching an existing external contract (Jamf parameter labels, JSON keys, command flags, or `[SYM-Helper]` variables)
- Avoid introducing new external dependencies

## Behavioral invariants (must hold unless explicitly changed)

- Preserve dialog lifecycle: welcome dialog -> setup dialog updates -> finalize/failure messaging -> quit/completion action
- Preserve overall trigger flow for each step: policy execution/confirmation -> validation -> list item status update -> progress increment
- Preserve status semantics used in UI/logging (`pending`, `wait`, `success`, `fail`, `error`) and current user-facing statustext meanings
- Preserve failure accumulation behavior (`jamfProPolicyTriggerFailure`, `jamfProPolicyNameFailures`, `exitCode`)
- Preserve completion-action behavior for `Wait`, `Sleep`, `Log Out`, `Restart`, `Shut Down`, `Quit`, and debug-mode override behavior
- Preserve artifact cleanup behavior in completion and quit paths (command/json temp files, overlay assets, dialog log cleanup)

## Refactor boundaries

Refactor-friendly areas (default starting points):

- Pure data shaping and helper logic that does not change side effects
- Repeated string/JSON assembly where output can be kept identical
- Small helper extraction inside validation branches while preserving branch behavior

High-risk areas (edit only with explicit intent and targeted verification):

- `dialogUpdate*` call ordering and timing-sensitive UI updates
- `confirmPolicyExecution`, `validatePolicyResult`, and the main step/trigger loops
- `quitScript`, `completionAction`, launch daemon toggling, and cleanup sequencing
- Pre-flight checks that gate execution (`root`, shell/runtime, dependencies, logging)

## Runtime dependency contracts

- `jamf` unavailable: script must fail predictably through existing guardrails; do not add silent fallbacks
- swiftDialog unavailable or below minimum: preserve existing install/check behavior and messaging
- `runAsUser`/`launchctl` assumptions: keep command execution model intact for UI-facing actions
- Network-dependent operations (download estimates, webhooks, remote validations): preserve current failure-tolerant behavior and logging
- macOS-native tools (`PlistBuddy`, `scutil`, `fdesetup`, `system_profiler`) are part of current contract; do not replace with new deps

## Refactor strategy

Use incremental phases and verify after each phase:

1. Isolate pure helpers (string transforms, value parsing, repeated message assembly)
2. Refactor function internals without changing inputs/outputs or call order
3. Refactor orchestration only after helper-level behavior is stable
4. Stop and report when a planned change requires behavioral deviation

## Validation and policy changes

When modifying policy/validation behavior:

- Preserve existing `policyJSON` shape unless task requires a schema change
- Keep local/remote validation behavior consistent with current conventions
- Avoid changing user-visible policy names/labels unless requested
- Document behavior changes in `CHANGELOG.md`

## Logging and error handling

- Use the script's logging conventions; avoid unstructured `echo` for production paths
- Ensure errors still feed expected failure handling and final status reporting
- Do not swallow non-zero statuses without a clear reason and log message

## Required checks after edits

Run these checks after modifying shell scripts:

1. `bash -n Setup-Your-Mac-via-Dialog.bash` (or each edited `.bash` file)
2. `zsh -n` on any edited Zsh files
3. Optional but recommended: targeted `shellcheck` if available

If any check cannot run, state that clearly in your final response.

## Minimal smoke-test matrix for refactors

For non-trivial changes to `Setup-Your-Mac-via-Dialog.bash`, validate at least:

1. Syntax-only pass (`bash -n`)
2. Debug mode flow (`debugMode=true` or `verbose`) to confirm dialog/log sequencing without executing full policy side effects
3. At least one successful policy step and one failure path (local or remote validation)
4. Completion action path relevant to changed code (`Wait` minimum; plus `Restart`/`Log Out`/`Sleep` if touched)
5. User-abort path at welcome dialog (exit-code and cleanup behavior)

## Regression evidence expectations

When submitting refactor changes, include:

- Functions/sections touched
- Which invariants were explicitly checked
- Commands run and results (`bash -n`, any smoke checks)
- Known risks or untested paths (if any)

## Changelog discipline

When behavior changes, update `CHANGELOG.md` in the current unreleased version section (or add one if needed).
Purely internal refactors/comments can skip changelog updates unless user requests otherwise.

## Commit/PR guidance for agents

- Summarize user-visible behavior changes first
- Call out risks to enrollment flow, dialog UX, and Jamf event sequencing
- Include validation evidence (syntax check results, and any smoke test notes if run)
