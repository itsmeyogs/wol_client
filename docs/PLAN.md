# WoL Gateway Client — Delivery Plan

## Rules

- Work proceeds checkpoint by checkpoint.
- Do not commit before the user explicitly marks the checkpoint passed.
- Each checkpoint gets a unique commit message.
- Allowed commit types: `chore`, `feat`, `fix`, `test`, `docs`.
- Every checkpoint ends with analyzer, test, and relevant build/API evidence.
- Live gateway evidence is separate from local/mock evidence.
- API tokens never appear in logs, test output, screenshots, or error notifications.
- Every navigable page belongs to a feature folder under `lib/presentation/pages/`.
- One navigable page gets one file and one primary page widget.
- New page files never go directly in the `pages/` root.
- Feature page names use `<feature>_<action>_page.dart` and matching `<Feature><Action>Page`.

## Status summary

| Checkpoint | Scope | Status | Commit |
|---|---|---|---|
| CP0 | Application foundation | Passed | `4508236 chore: establish application foundation` |
| CP1 | Local gateway management | Passed | `9d20b48 feat: add local gateway management` |
| CP2 | Gateway connectivity and validated save | Passed | `94baed3 feat: add gateway health connectivity` |
| CP3 | Device management and Add Device flow | Passed | `af391d1 feat: add gateway device management` |
| CP4 | Device status and wake actions | Passed | `6fcb767 feat: add device status and wake actions` |
| CP5 | Diagnostics page | Passed | `b8018a5 feat: add gateway diagnostics`; `076d1bc feat: add thermal diagnostics` |
| CP6 | Full API and platform verification | Passed | `5540dd8 test: verify gateway API workflows` |
| CP7 | Firebase authentication | Passed | `feat: add Firebase authentication` |
| CP8 | Firebase sync contract and Rules | Passed | `docs: define Firebase gateway sync contract` |
| CP9 | Firebase gateway sync | Post-MVP | Pending |
| CP10 | Cross-device verification | Post-MVP | Pending |

## CP0 — Application foundation

### Scope

- Flutter project baseline.
- GetX, Dio, Logger, SQLite dependencies.
- Clean Architecture directories.
- Platform database factories.
- Responsive utility.
- Theme and semantic colors.
- Shared snackbar utility.
- GetX binding foundation.
- Initial project documentation.

### Acceptance criteria

- Android debug build succeeds.
- Windows debug build succeeds.
- Web/WASM build succeeds.
- SQLite opens on supported targets.
- Shared theme is consumed from `core/theme`.
- Shared dependencies use GetX Bindings.

### Evidence

```text
flutter analyze
flutter test
flutter build apk --debug
flutter build windows --debug
flutter build web --wasm
```

### Commit

```text
4508236 chore: establish application foundation
```

## CP1 — Local gateway management

### Scope

- Gateway model.
- SQLite gateway CRUD.
- Gateway repository and use cases.
- Gateway list, form, and dashboard shell.
- Single gateway session.
- URL construction and local validation.
- Long-press Edit/Delete actions.
- Radio scheme selector.
- Custom field labels.

### Acceptance criteria

- User adds a gateway record locally.
- User edits a gateway record locally.
- User deletes a gateway after confirmation.
- User taps a gateway to open one active session.
- User can return and select another gateway.
- URL stores no scheme or `/api/v1` in `baseUrl`.
- Empty state and error state provide next actions.
- Gateway data survives app restart.

### Evidence

```text
dart analyze
flutter test
```

### Commit

```text
9d20b48 feat: add local gateway management
```

## CP2 — Gateway connectivity and validated save

### Scope

- Shared Dio client.
- Request/response/error logging.
- Safe token redaction.
- `GET /health` validation.
- Authenticated `GET /diagnostics` validation.
- Timeout and HTTP error mapping.
- Save only after API validation.

### Acceptance criteria

- Valid gateway saves after health and diagnostics succeed.
- Invalid URL is rejected locally or with a clear network error.
- Unreachable gateway is reported clearly.
- Invalid token returns an authentication error.
- Failed edit leaves the previous gateway record unchanged.
- API token is absent from logs and displayed errors.
- Duplicate save submission is prevented.

### Evidence

```text
dart analyze
flutter analyze
flutter test
flutter build apk --debug
flutter build windows --debug
flutter build web --wasm
```

Live evidence must include a valid gateway, invalid token, and unreachable gateway.

### Commit

```text
94baed3 feat: add gateway health connectivity
```

## CP3 — Device management and Add Device flow

### Scope

- Device model and mapping.
- Device repository/use cases/controller.
- Device list and detail foundation.
- `lib/presentation/pages/gateway/gateway_dashboard_page.dart` owns the device list entry point.
- `lib/presentation/pages/device/discovery_scan_page.dart` owns network discovery.
- `lib/presentation/pages/device/device_add_edit_page.dart` owns manual add, discovery-result review, and edit.
- `DiscoveryScanPage`.
- `DeviceAddEditPage` for manual add, discovery candidate add, and edit.
- Discover from Network flow.
- Add Manually flow from the discovery page footer.
- Device create/update/delete.
- Discovery candidate mapping.

### Current implementation

Device model, repository, use cases, controller, `DiscoveryScanPage`, `DeviceAddEditPage`, model test, and dashboard wiring are present. CP3 was approved as passed. Live gateway evidence was verified with CP6.

### Acceptance criteria

- `GET /devices` loads an empty and populated list.
- `GET /devices/{id}` loads device detail.
- `POST /discovery/scan` displays candidates without auto-saving.
- Dashboard `+` opens `DiscoveryScanPage`.
- User can select a candidate and review/edit it in `DeviceAddEditPage`.
- A null discovery MAC can be completed manually.
- Empty discovery results still expose `Add manually` in the discovery page footer.
- Edit opens `DeviceAddEditPage` without discovery controls.
- User can add a device manually.
- `POST /devices` persists a valid device.
- `PUT /devices/{id}` updates a device.
- `DELETE /devices/{id}` removes a device after confirmation.
- Validation errors and duplicate MAC conflicts are clear.
- All device requests use the active gateway session.

### Verification checklist

```text
[x] flutter analyze
[x] flutter test
[x] live GET /devices
[x] live GET /devices/{id}
[x] live POST /discovery/scan with results
[x] live POST /discovery/scan with empty result
[x] add discovered device
[x] add manual device
[x] edit device
[x] delete device
[x] invalid device validation
[x] duplicate MAC conflict
```

### Commit after user approval

```text
feat: add gateway device management
```

## CP4 — Device status and wake actions

### Scope

- `GET /devices/{id}/status`.
- `POST /devices/{id}/wake`.
- Pages under `lib/presentation/pages/status/`.
- Separate status and wake page files when both become independently navigable.
- Status badges and result details.
- Wake confirmation.
- Loading and duplicate-action prevention.
- Latency and reason display.

### Acceptance criteria

- `ONLINE`, `OFFLINE`, and `UNKNOWN` are displayed correctly.
- Previous device state remains if a refresh fails.
- `PACKET_SENT` is explained as packet delivery, not proof of power-on.
- Wake action cannot be double-submitted.
- Errors are shown through GetX snackbar without token leakage.

### Commit

```text
feat: add device status and wake actions
```

## CP5 — Diagnostics page

### Scope

- `GET /diagnostics` presentation.
- `lib/presentation/pages/diagnostics/diagnostics_page.dart`.
- Safe diagnostics sections.
- Loading, empty, error, and refresh states.

### Acceptance criteria

- Safe gateway diagnostics are readable.
- Token, credentials, raw commands, and sensitive identifiers are absent.
- Refresh uses the active gateway.

### Verification

```text
dart analyze
flutter analyze
flutter test
git diff --check
```

### Verification result

- Firestore Rules emulator checks passed: owner CRUD, guest denial, cross-user
  denial, immutable `ownerId`, invalid scheme, and unknown fields.
- Firebase Rules deployed successfully to project `wol-client`.
- Android, Windows, and Web/WASM builds passed.
- Flutter analyzer and tests passed.
- Firestore runtime sync is intentionally deferred to CP9.

### Commit

```text
feat: add gateway diagnostics
```

## CP6 — Full API and platform verification

### Endpoint matrix

```text
GET    /health
GET    /diagnostics
POST   /discovery/scan
GET    /devices
GET    /devices/{id}
POST   /devices
PUT    /devices/{id}
DELETE /devices/{id}
GET    /devices/{id}/status
POST   /devices/{id}/wake
```

### Acceptance criteria

- Every endpoint has success evidence.
- `400`, `401`, `404`, `409`, timeout, offline, and malformed response behavior is checked.
- Android, Windows, and Web/WASM builds succeed.
- Responsive behavior is reviewed at mobile, tablet, and desktop widths.
- Keyboard and semantic labels are reviewed on Windows/Web.
- No token leakage is found in logs or notifications.

### Page-structure verification

```text
[ ] every navigable page is inside a feature folder
[ ] every page file has one primary page widget
[ ] file and widget names match
[ ] no page is duplicated in multiple feature folders
[ ] docs paths match repository paths
```

### Commit

```text
test: verify gateway API workflows
```

## CP7 — Firebase authentication — post-MVP

Start only after CP6 passes and the user connects the existing Firebase project.

### Scope

- Firebase project connection.
- Email/password sign-in.
- Google sign-in.
- Logout.
- Session restoration.
- Auth error states.
- Guest mode preservation.

### Acceptance criteria

- Guest can continue local-only usage.
- Email/password login works.
- Google login works on supported targets.
- Logout clears authenticated UI state.
- Session restoration does not block local gateway access.

### Commit

```text
feat: add Firebase authentication
```

## CP8 — Firebase sync contract and Rules — post-MVP

**Execution contract:** `gatewayId` is a stable opaque document ID. It is not
the local SQLite auto-increment `id`; CP9 must add or persist this sync ID.

### Firestore path

```text
users/{uid}/gateways/{gatewayId}
```

### Document fields

```text
name
scheme
baseUrl
apiToken
ownerId
createdAt
updatedAt
```

### Rules requirements

- Unauthenticated users cannot read or write gateway documents.
- A user can access only their own `users/{uid}` path.
- Create requires `ownerId == request.auth.uid`.
- Update requires existing and new owner IDs to remain the authenticated UID.
- Delete requires ownership.
- `ownerId` cannot be changed by a client update.

### Implemented artifacts

- `firestore.rules` validates ownership, exact fields, field types, and `http`/
  `https` scheme values.
- `firebase.json` configures Firestore Rules and the local emulator.
- `test/firestore_rules_test.js` covers owner CRUD, guest denial, cross-user
  denial, owner tampering, invalid scheme, and unknown fields.

### Verification

```text
npm run test:rules
flutter analyze
flutter test
git diff --check
```

### Product security decision

The token is plaintext in Firestore by explicit decision. Authentication and Rules control access; they do not provide encryption. Cloud Functions, KMS, encryption, and sync passphrases are out of scope unless this decision changes.

### Commit

```text
docs: define Firebase gateway sync contract
```

## CP9 — Firebase gateway sync — post-MVP

### Scope

- Automatic sync on login/app start.
- Manual refresh.
- Upload local gateway records.
- Download cloud gateway records.
- SQLite/cloud merge.
- Last-write-wins using `updatedAt`.
- API token edits through Edit Gateway sync normally.

### Acceptance criteria

- New local gateway uploads for the authenticated user.
- Cloud gateway appears on another authenticated device.
- Gateway edits propagate.
- Token edits propagate without logging the token.
- Offline local usage remains available.
- Conflicts resolve deterministically.
- User data remains isolated by Rules.

### Temporary debug cleanup

- Remove the temporary `Exit guest mode` debug button after CP9 sync is complete.
- Remove `AuthController.exitGuestMode()`.
- Remove the guest-mode cleanup test if no longer needed.
- Preserve the normal authenticated logout flow.

### Commit

```text
feat: sync gateway data with Firebase
```

## CP10 — Cross-device verification — post-MVP

### Acceptance criteria

- Device A login and gateway creation.
- Device B login and gateway download.
- Device A gateway edit and Device B refresh.
- Device B token can authenticate to the gateway after sync.
- User A cannot read User B data.
- Logout behavior is correct.
- Android, Windows, and Web/WASM are checked.

### Commit

```text
test: verify cross-device gateway sync
```
