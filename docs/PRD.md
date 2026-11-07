# WoL Gateway Client — PRD

Flutter client for managing WoL gateways and devices on Android, Windows, and Web/WASM.

## MVP

- Gateway CRUD in local SQLite.
- Save validation through `/health` and authenticated `/diagnostics`.
- Device CRUD, discovery, status check, wake, and diagnostics.
- Guest use before Firebase login.

## First screen

The first screen manages gateways. Clicking a gateway opens one gateway session; all later API actions use that gateway until the user returns to the list.

The add action is a compact `+` button. Empty state includes a labelled Add gateway action for discoverability.

Gateway cards use a simple tap to open the gateway. Long press exposes Edit and Delete actions.

Implementation constraint: dependency lifecycle and construction use GetX Bindings; UI pages must not manually construct repositories, data sources, or controllers.

Visual implementation constraint: application theme and semantic colors are centralized under `lib/core/theme/` for consistent maintenance across Android, Windows, and Web.

UI component constraint: page-specific repeated controls may remain local helpers; cross-page components use named files under `lib/presentation/widgets/`.

## Gateway fields

`name`, `scheme`, `baseUrl`, `apiToken`, `createdAt`, `updatedAt`.

The user selects `http://` or `https://`; code appends `/api/v1`.

API tokens remain plaintext in SQLite and Firestore by explicit product decision. Tokens never enter logs, errors, analytics, or reactive UI state. Firebase Authentication and Firestore Rules protect cloud access.
