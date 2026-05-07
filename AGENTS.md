# AGENTS.md (Setup Your Mac, version 1.16.2b2)

**Single source of truth for coding agents working in this repository.**
Use this file for repo-specific agent behavior, boundaries, and validation rules. It takes precedence over `README.md`, `CONTRIBUTING.md`, and lightweight loader files such as `.github/copilot-instructions.md` when repository guidance overlaps.

## Orchestration Contract

This file codifies project rules, operational boundaries, workflow, and repeatable skills for Setup Your Mac. Favor operational safety over stylistic cleanup. Preserve implemented behavior unless the user explicitly asks to change it.

## Project Overview

`Setup-Your-Mac-via-Dialog.bash` is a production enrollment workflow script that:

- runs as `root`
- drives end-user UI with swiftDialog
- executes Jamf Pro custom policy events
- depends on guardrails for pre-flight checks, dependency checks, exit handling, and logging

Breakages can affect zero-touch onboarding and first-run usability. Optimize for operational safety.

## Scope and Priority

- Primary focus: `Setup-Your-Mac-via-Dialog.bash`
- Secondary files: `Prompt-to-Setup-Your-Mac.bash`, `Validations/*`, `Resources/SYM-Lite.zsh`, and docs only when required by task scope
- Preserve current behavior by default
- Prefer small, localized edits over broad rewrites

## Key Commands

- Validate main script syntax after every edit: `bash -n Setup-Your-Mac-via-Dialog.bash`
- Validate other Bash edits with `bash -n <file>`
- Validate edited Zsh files with `zsh -n <file>`
- Optional but recommended when available: targeted `shellcheck <file>`

## Agent Workflow

- Start non-trivial or high-risk work in plan mode before editing.
- Default user-facing communication mode is `$caveman full` unless security, irreversible actions, or user confusion require normal clarity.
- Use surgical edits. Target exact functions, branches, or helper blocks instead of broad rewrites.
- Before editing `Setup-Your-Mac-via-Dialog.bash`, identify whether touched lines are inside a `[SYM-Helper]`-managed surface.
- After any substantive shell-script edit, run the relevant syntax check immediately before widening scope.
- Reuse existing helpers such as `logMessage`, `runAsUser`, and current dialog-update helpers instead of adding ad-hoc patterns.
- Stop and report when safe implementation requires behavioral deviation from current contracts.

## Boundaries

**Always allowed without asking**

- Read any repository file needed for current task.
- Run targeted syntax checks (`bash -n`, `zsh -n`) and targeted `shellcheck` when available.
- Make small, task-scoped edits to docs or low-risk helper logic that follow rules below.
- Improve clarity and structure of agent-facing docs as long as repo-specific constraints stay intact.

**Ask before doing**

- Change expected semantics or value formats of anything marked `[SYM-Helper]`.
- Change script parameter numbering (`$4`, `$5`, etc.) or default parameter behavior.
- Change policy ordering, dialog JSON structure, completion-action defaults, exit-code semantics, or logging/output contracts.
- Add new production dependencies, remote services, or silent fallback behavior.
- Modify tracked release/documentation artifacts outside direct task scope.

**Never do**

- Remove `[SYM-Helper]` markers.
- Rename, repurpose, or silently change semantics of `[SYM-Helper]` variables.
- Bypass failure handling, dependency guardrails, or pre-flight gating.
- Break dialog launch, update, quit, or cleanup flow.
- Hardcode secrets, credentials, or organization-specific sensitive data.
- Modify unrelated files just because they are nearby.

## Source of Truth

When files disagree, prefer:

1. `Setup-Your-Mac-via-Dialog.bash` for implemented behavior, parameter contracts, policy orchestration, completion actions, and cleanup flow.
2. `AGENTS.md` for agent workflow, operational boundaries, validation requirements, and editing expectations.
3. `Prompt-to-Setup-Your-Mac.bash`, `Validations/*`, and `Resources/SYM-Lite.zsh` for behavior local to those supporting scripts when they are in scope.
4. `README.md` and `CHANGELOG.md` for contributor and release documentation.
5. `.github/copilot-instructions.md` as a loader that points agents back to this file.

## Mission and Scope

Mission: keep Setup Your Mac reliable as a production enrollment workflow that guides end users through policy-driven setup with clear status, safe failure handling, and predictable completion behavior.

In scope:

- root-run enrollment workflow behavior
- swiftDialog user experience and update flow
- Jamf Pro policy execution and validation orchestration
- dependency checks, logging, cleanup, and completion actions
- supporting validation scripts and setup-adjacent documentation

Out of scope unless explicitly requested:

- replacing Jamf-driven workflow with a different orchestration model
- removing guardrails for speed or convenience
- broad UI redesigns that change dialog lifecycle semantics
- new external dependencies for core production flow

## Implementation Priorities

1. Preserve operational safety, dependency checks, and predictable failure paths.
2. Preserve dialog lifecycle and policy-step sequencing.
3. Keep `[SYM-Helper]` compatibility intact.
4. Maintain backward compatibility for parameter contracts and user-facing behavior.
5. Favor minimal, testable edits and reuse existing helpers.

## Key Files

- `Setup-Your-Mac-via-Dialog.bash`: primary production workflow, dialog lifecycle, policy execution, validation, completion actions, cleanup
- `Prompt-to-Setup-Your-Mac.bash`: prompt/setup-adjacent Bash entry point when task explicitly touches it
- `Validations/*`: per-product validation scripts used by policy flow
- `Resources/SYM-Lite.zsh`: supporting Zsh helper path when task scope requires it
- `README.md` and `CHANGELOG.md`: contributor-facing and release-facing documentation

## Current Runtime Hotspots

- `[SYM-Helper]`-managed variables and sections inside `Setup-Your-Mac-via-Dialog.bash`
- `dialogUpdate*` ordering and timing-sensitive UI updates
- `confirmPolicyExecution`, `validatePolicyResult`, and main step/trigger loops
- `quitScript`, `completionAction`, launch daemon toggling, and cleanup sequencing
- runtime assumptions around `jamf`, swiftDialog, `runAsUser`, `launchctl`, and network-dependent validations

## Non-Negotiables

### Preserve SYM-Helper Compatibility

Anything marked `[SYM-Helper]` in `Setup-Your-Mac-via-Dialog.bash` is externally managed by SYM-Helper.

- Do not remove `[SYM-Helper]` markers.
- Do not rename, repurpose, or silently change semantics of `[SYM-Helper]` variables.
- Do not change expected value formats for `[SYM-Helper]` variables without explicit request.

### Maintain Operational Safety

- Keep dependency and environment checks intact, including `root`, shell/runtime, swiftDialog, and Jamf assumptions.
- Do not bypass failure paths or exit-code handling.
- Do not break dialog launch, update, quit, or completion flow.
- Do not reduce logging coverage in existing critical paths.

## Editing Rules for `Setup-Your-Mac-via-Dialog.bash`

- Keep script parameter numbering stable unless explicitly requested.
- Keep default parameter values backward compatible unless explicitly requested.
- Reuse existing helpers and functions instead of introducing ad-hoc patterns.
- Match existing Bash style and quoting conventions in surrounding code.
- Use `lowerCamelCase` for new variable and function names unless matching an existing external contract such as Jamf parameter labels, JSON keys, command flags, or `[SYM-Helper]` variables.
- Avoid introducing new external dependencies.

## Behavioral Invariants

These must hold unless explicitly changed:

- Preserve dialog lifecycle: welcome dialog -> setup dialog updates -> finalize or failure messaging -> quit or completion action.
- Preserve overall trigger flow for each step: policy execution or confirmation -> validation -> list-item status update -> progress increment.
- Preserve status semantics used in UI and logging: `pending`, `wait`, `success`, `fail`, `error`, and current user-facing `statustext` meanings.
- Preserve failure accumulation behavior through `jamfProPolicyTriggerFailure`, `jamfProPolicyNameFailures`, and `exitCode`.
- Preserve completion-action behavior for `Wait`, `Sleep`, `Log Out`, `Restart`, `Shut Down`, `Quit`, plus debug-mode override behavior.
- Preserve artifact cleanup behavior in completion and quit paths, including command and JSON temp files, overlay assets, and dialog log cleanup.

## Refactor Boundaries

Refactor-friendly areas:

- pure data shaping and helper logic that does not change side effects
- repeated string or JSON assembly where output can remain identical
- small helper extraction inside validation branches while preserving branch behavior

High-risk areas that need explicit intent and targeted verification:

- `dialogUpdate*` call ordering and timing-sensitive UI updates
- `confirmPolicyExecution`, `validatePolicyResult`, and main step or trigger loops
- `quitScript`, `completionAction`, launch daemon toggling, and cleanup sequencing
- pre-flight checks that gate execution such as `root`, shell/runtime, dependency, and logging checks

## Runtime Dependency Contracts

- If `jamf` is unavailable, script must fail predictably through existing guardrails. Do not add silent fallbacks.
- If swiftDialog is unavailable or below minimum version, preserve existing install, check, and messaging behavior.
- Preserve `runAsUser` and `launchctl` execution model for UI-facing actions.
- Preserve current failure-tolerant behavior and logging for network-dependent operations such as download estimates, webhooks, and remote validations.
- macOS-native tools such as `PlistBuddy`, `scutil`, `fdesetup`, and `system_profiler` are part of current contract. Do not replace them with new dependencies without explicit approval.

## Refactor Strategy

Use incremental phases and verify after each phase:

1. Isolate pure helpers such as string transforms, value parsing, or repeated message assembly.
2. Refactor function internals without changing inputs, outputs, or call order.
3. Refactor orchestration only after helper-level behavior is stable.
4. Stop and report when a planned change requires behavioral deviation.

## Skills

Invoke these patterns during planning when they fit the task.

### Refactor Policy Step Skill

1. Start at the owning policy step, helper, or validation branch.
2. Preserve policy execution or confirmation -> validation -> list-item status update -> progress increment flow.
3. Reuse existing helpers and keep diff localized.
4. Run `bash -n Setup-Your-Mac-via-Dialog.bash` immediately after edit.
5. Validate touched success or failure path and any affected completion path.

### Adjust Validation Behavior Skill

1. Preserve existing `policyJSON` shape unless task explicitly requires schema change.
2. Keep local and remote validation behavior aligned with current conventions.
3. Avoid changing user-visible policy names or labels unless requested.
4. If behavior changes, document it in `CHANGELOG.md`.

### Release Readiness Review Skill

1. Confirm no `[SYM-Helper]` surface drifted.
2. Confirm parameter numbering and defaults remain stable unless release task says otherwise.
3. Re-check pre-flight behavior, one success path, one failure path, relevant completion actions, and user-abort path.
4. Align `CHANGELOG.md` updates only when scope includes real behavior change or release prep.

## Logging and Error Handling

- Use the script's logging conventions. Avoid unstructured `echo` in production paths.
- Ensure errors still feed expected failure handling and final status reporting.
- Do not swallow non-zero statuses without a clear reason and log message.

## Required Validation

Run these checks after modifying shell scripts:

1. `bash -n Setup-Your-Mac-via-Dialog.bash` or `bash -n <edited-file>` for each edited Bash file.
2. `zsh -n <edited-file>` for each edited Zsh file.
3. Optional but recommended: targeted `shellcheck <edited-file>` when available.

If any check cannot run, say so clearly in final handoff.

## Minimal Smoke-Test Matrix

For non-trivial changes to `Setup-Your-Mac-via-Dialog.bash`, validate at least:

1. Syntax-only pass with `bash -n`.
2. Debug-mode flow such as `debugMode=true` or `verbose` to confirm dialog and log sequencing without executing full policy side effects.
3. At least one successful policy step and one failure path, local or remote.
4. Completion-action path relevant to changed code, with `Wait` minimum plus `Restart`, `Log Out`, or `Sleep` if touched.
5. User-abort path at welcome dialog, including exit-code and cleanup behavior.

## Regression Evidence Expectations

When submitting refactor changes, include:

- functions or sections touched
- which invariants were explicitly checked
- commands run and results such as `bash -n` and any smoke checks
- known risks or untested paths, if any

## Changelog Discipline

When behavior changes, update `CHANGELOG.md` in current unreleased section or add one if needed. Purely internal refactors, comments, or agent-doc clarity updates can skip changelog updates unless user requests otherwise.

## Commit and PR Guidance for Agents

- Summarize user-visible behavior changes first.
- Call out risks to enrollment flow, dialog UX, and Jamf event sequencing.
- Include validation evidence such as syntax-check results and any smoke-test notes.

## Maintenance

Keep this file current with repo rules, validation requirements, and operating boundaries. Prefer merging overlapping guidance instead of adding duplicate sections. Keep file compact enough to stay scannable, but never remove mandatory safety constraints for brevity.
