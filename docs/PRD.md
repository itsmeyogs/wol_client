# WoL Gateway Client — Product Requirements

## 1. Product overview

WoL Gateway Client is a Flutter application for managing one or more WoL Gateway connections and operating the devices exposed by the selected gateway.

The application targets Android, Windows, and Flutter Web/WASM. It supports local guest usage first. Firebase authentication and cloud synchronization are post-MVP features.

## 2. Product goals

- Connect to a WoL Gateway using a user-managed base URL and API token.
- Keep gateway configuration available locally without requiring login.
- Make one selected gateway the exclusive context for device operations.
- Manage gateway devices through the API documented in `API_DOC.md`.
- Discover LAN devices, review results, and add them as managed devices.
- Add devices manually when discovery returns no result or misses a target.
- Provide clear loading, success, empty, validation, network, authorization, and server error states.
- Support Android, Windows, and Web/WASM from one Flutter codebase.

## 3. Target platforms

| Platform | Target | Notes |
|---|---:|---|
| Android | MVP | Primary client platform. |
| Windows | MVP | Desktop management and keyboard use. |
| Web/WASM | MVP target | Requires browser-compatible packages and SQLite WASM assets. |

## 4. Page and feature organization

Each navigable page belongs to its feature folder. Pages from different features are never combined in one file.

```text
lib/presentation/pages/
├── gateway/
│   ├── gateway_list_page.dart
│   ├── gateway_form_page.dart
│   └── gateway_dashboard_page.dart
├── device/
│   ├── discovery_scan_page.dart
│   └── device_add_edit_page.dart
├── status/       reserved for status and wake pages
├── diagnostics/  reserved for diagnostics pages
├── settings/     reserved for settings pages
└── auth/         reserved for authentication pages
```

File names and primary widgets use matching names. For example, `device_add_edit_page.dart` contains `DeviceAddEditPage`. New features add their own folder before adding navigable pages.

## 5. Users and primary jobs

### Guest user

The user can:

- Add, edit, delete, and open local gateways.
- Validate a gateway before saving it.
- Manage devices through the selected gateway.
- Use discovery, manual add, status checks, and wake actions.

### Authenticated user — post-MVP

The user can:

- Sign in with email/password or Google.
- Sync gateway records across devices.
- Refresh cloud data manually or through automatic sync.

## 6. MVP scope

### 6.1 Gateway management

The first screen is the Gateway List.

Gateway fields:

```text
id
name
scheme: http | https
baseUrl
apiToken
createdAt
updatedAt
```

Input rules:

- `name` is required.
- `scheme` defaults to `https`.
- `baseUrl` contains only host/path, without `http://`, `https://`, or `/api/v1`.
- `apiToken` is required.
- The application appends `/api/v1` in code.
- Trailing slashes are removed before persistence.

Save flow:

```text
Local validation
→ GET {scheme}://{baseUrl}/api/v1/health
→ GET {scheme}://{baseUrl}/api/v1/diagnostics with Bearer token
→ save to SQLite only if both checks succeed
```

Save failure behavior:

- New gateway is not inserted.
- Existing gateway remains unchanged during a failed edit.
- The user receives the specific known failure.
- API tokens never appear in logs or error messages.

Gateway card behavior:

- Tap opens the gateway session.
- Long press opens Edit/Delete actions.
- Delete requires confirmation.
- No edit, delete, or navigation icons are shown on the card.
- The compact `+` FAB opens Add Gateway.
- Empty state includes a labelled Add Gateway action.

### 6.2 Gateway session

Only one gateway is active in a session.

```text
Gateway List
→ tap gateway
→ Gateway Dashboard
→ all API operations use that gateway
→ back to Gateway List to choose another gateway
```

There is no `isSelected` database field. The active gateway is held by the session controller. Restarting the app returns the user to the Gateway List.

### 6.3 Device management

Required API operations:

| Method | Path | Product behavior |
|---|---|---|
| `GET` | `/devices` | Load managed devices. |
| `GET` | `/devices/{id}` | Load one device. |
| `POST` | `/devices` | Add a device. |
| `PUT` | `/devices/{id}` | Replace a device configuration. |
| `DELETE` | `/devices/{id}` | Delete a device. |

Device fields follow `API_DOC.md`:

```text
id
name
ipAddress
macAddress
broadcastAddress
wolPort
statusCheckMethod
statusCheckPort
status
lastCheckAt
lastCheckLatencyMs
lastCheckReason
lastWolResult
lastWolAt
```

### 6.4 Add Device

The dashboard add action opens a dedicated Discovery Scan page. Add Device has two paths:

```text
Gateway Dashboard
→ Discovery Scan
   ├── select result → DeviceAddEditPage
   └── footer Add manually → DeviceAddEditPage
```

#### Discover from Network

```text
POST /discovery/scan
→ show scan results
→ user selects a result
→ open DeviceAddEditPage with available values
→ user reviews or edits fields
→ POST /devices
```

Rules:

- Discovery never saves a device automatically.
- `macAddress` may be `null` in discovery results.
- Required fields must be complete before saving.
- Empty discovery results still show `Add manually` in the scan page footer.
- A device missed by discovery can always be entered manually.
- Already registered IP addresses are not expected in discovery results.

#### Add Manually

`DeviceAddEditPage` accepts:

- Name.
- IP address.
- MAC address.
- Broadcast address.
- WoL port.
- Status check method.
- Status check port.

### 6.5 Device edit

Long press a device on the Gateway Dashboard, then choose Edit. This opens `DeviceAddEditPage` with the existing values. Edit has no discovery action; discovery is available only from `DiscoveryScanPage`.

### 6.6 Device actions

| Method | Path | Product behavior |
|---|---|---|
| `GET` | `/devices/{id}/status` | Run and display one status check. |
| `POST` | `/devices/{id}/wake` | Send a WoL magic packet. |

Status values:

- `ONLINE`: connectivity evidence was found.
- `OFFLINE`: strong evidence says the target is unavailable.
- `UNKNOWN`: evidence is ambiguous or insufficient.

`PACKET_SENT` means the gateway sent the packet locally without an error. It does not prove that the target computer powered on.

### 6.7 Diagnostics

Required operation:

```text
GET /diagnostics
```

Diagnostics may show safe gateway information such as application version, runtime mode, interface, tunnel, service state, device information, and battery information. Secrets, raw shell output, credentials, and sensitive identifiers must not be displayed.

## 7. API and error requirements

All authenticated API requests use:

```http
Authorization: Bearer <api-token>
```

Known error handling:

| Condition | User-facing result |
|---|---|
| Empty name/base URL/token | Local validation error. |
| Invalid base URL | Base URL validation error. |
| Gateway unreachable | Gateway cannot be reached. |
| Timeout | Gateway request timed out. |
| `401` | API token is invalid. |
| `404` | Gateway endpoint/resource was not found. |
| `409` | Duplicate device conflict. |
| Other `4xx` | Request rejected with safe explanation. |
| `5xx` | Gateway/server error without secret details. |
| Malformed response | Invalid gateway response. |

The API error envelope is defined in `API_DOC.md` and must be mapped without exposing sensitive fields.

## 8. Data and security decisions

### Local storage

SQLite stores gateway records locally. Platform setup:

- Android: `sqflite`.
- Windows: `sqflite_common_ffi`.
- Web/WASM: `sqflite_common_ffi_web`, IndexedDB, SQLite WASM, and worker assets.

### Token decision

By explicit product decision, the API token is plaintext in local SQLite and, in the future, Firestore.

Controls:

- Token is not logged.
- Token is not included in error messages.
- Token is not reactive GetX UI state.
- Token input is obscured by default.
- Firebase Authentication and Firestore Rules protect cloud access after login.

This is access control, not encryption. A compromised authenticated account can expose that account's token; the user can replace the token through Edit Gateway after rotating it in the gateway application.

## 9. Responsive and accessibility requirements

- Use native Flutter layout primitives only.
- Mobile breakpoint: below `600` logical pixels.
- Tablet range: `600` to below `1024`.
- Desktop range: `1024` and above.
- Controls have visible labels or accessible tooltips.
- Long-press actions have an equivalent visible bottom-sheet action after the gesture.
- Forms support keyboard navigation on Windows/Web.
- Loading controls prevent duplicate submissions.
- Empty and error states provide a clear next action.

## 10. Non-goals

MVP does not include:

- Firebase authentication.
- Firebase synchronization.
- Token encryption.
- Token rotation UI or automatic rotation.
- Background polling.
- Push notifications.
- Shell execution or arbitrary process execution.
- Automatic persistence of discovery results.

## 11. Success criteria

MVP is successful when a user can:

1. Add a valid gateway and see it after app restart.
2. Receive a clear error for invalid URL, unreachable gateway, or invalid token.
3. Open exactly one gateway session.
4. Create a device through discovery or manual entry.
5. Edit and delete a device.
6. Check status and send a wake packet.
7. Use the app on Android, Windows, and Web/WASM builds.
