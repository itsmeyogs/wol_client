# WoL Gateway Client — Checkpoints

- CP0: architecture, dependencies, GetX, Dio, Logger, SQLite, responsive, WASM setup.
- CP1: gateway SQLite CRUD, list, form, session, local validation, URL construction.
- CP2: `/health`, authenticated `/diagnostics`, error mapping, validated Add/Edit save.
- CP3: device CRUD, discovery/manual Add Device flow.
- CP4: status checks and WoL wake.
- CP5: diagnostics page.
- CP6: all endpoints, errors, builds, responsive/accessibility review.

No commit before the user marks the checkpoint passed.

## Current implementation note

CP0–CP2 source is implemented. Live gateway verification remains required before marking them passed. The current UI covers gateway list, empty state, add/edit validation, one-gateway session, and dashboard shell.

UI interaction update: gateway actions use long press; scheme uses a horizontal radio group; snackbar feedback is centralized through GetX `AppSnackbar`.

## Theme maintenance rule

All theme configuration belongs in `lib/core/theme/app_theme.dart`; semantic color tokens belong in `app_colors.dart`. New UI code must consume these tokens or the active Material `ColorScheme`, never scattered hardcoded colors.

## Dependency injection rule

Every shared service, repository, use case, and controller must be registered through a GetX `Bindings` class. Keep construction wiring out of `main.dart`; use constructor injection inside registered factories. Add feature-specific bindings when new features become independently navigable.

## Widget reuse rule

Start with the smallest local helper. Extract to `lib/presentation/widgets/` only after a widget is reused across pages with the same API and styling. Avoid premature generic components.
