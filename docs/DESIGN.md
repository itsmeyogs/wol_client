# WoL Gateway Client — Technical Design

## 1. Architecture

The project uses a layer-first Clean Architecture layout:

```text
lib/
├── core/
│   ├── database/
│   ├── errors/
│   ├── logging/
│   ├── network/
│   ├── responsive/
│   ├── theme/
│   └── ui/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── bindings/
│   ├── controllers/
│   ├── pages/
│   │   ├── gateway/
│   │   ├── device/
│   │   ├── status/
│   │   ├── diagnostics/
│   │   ├── settings/
│   │   └── auth/
│   └── widgets/
└── main.dart
```

Page organization rules:

- Each feature owns a folder under `lib/presentation/pages/`.
- Each navigable page has one file and one primary page widget.
- Keep feature pages out of the `pages/` root.
- Name files with the feature and page action, for example `device_add_edit_page.dart` / `DeviceAddEditPage`.
- Do not combine pages from different features in one file.
- Add a feature folder only when that feature gets its first navigable page.

Current page ownership:

```text
lib/presentation/pages/gateway/
├── gateway_list_page.dart       GatewayListPage
├── gateway_form_page.dart       GatewayFormPage
└── gateway_dashboard_page.dart  GatewayDashboardPage

lib/presentation/pages/device/
├── discovery_scan_page.dart     DiscoveryScanPage
└── device_add_edit_page.dart    DeviceAddEditPage
```

Reserved future page folders: `status/`, `diagnostics/`, `settings/`, `auth/`.

Dependency direction:

```text
Presentation
  → Domain
    → Data
      → Core/platform services
```

Pages do not execute SQL or construct repositories. Controllers do not know Dio or SQLite implementation details. Repositories coordinate data sources and map infrastructure failures to application-safe failures.

## 2. GetX dependency injection

All shared dependencies are registered in `presentation/bindings/app_binding.dart`.

```text
AppDatabase + DioClient
→ GatewayLocalDataSource
→ GatewayRepository
→ GetGateways / SaveGateway / DeleteGateway
→ GatewayController
```

Rules:

- `main.dart` initializes Flutter and platform database support only.
- `AppBinding` owns dependency construction.
- Infrastructure and use cases use lazy registration with `fenix: true` where recreation is safe.
- `GatewaySessionController` is permanent for the current app session.
- Controllers receive use cases through constructors.
- Pages resolve controllers through `GetView` or `Get.find`.
- Tests can replace registered dependencies with fakes/mocks.

When a feature becomes independently navigable, add a feature binding instead of wiring dependencies inside a page.

## 3. Gateway session and navigation

```text
GatewayListPage
  → GatewaySessionController.open(gateway)
  → GatewayDashboardPage
  → Device pages and gateway actions use activeGateway
```

Only one `activeGateway` exists. There is no `isSelected` column and no simultaneous multi-gateway request context.

If an active gateway is deleted, the session must be cleared. Returning to the list is the supported way to choose another gateway.

## 4. Gateway URL contract

The form stores:

```text
scheme = http | https
baseUrl = host[:port][/optional-path]
```

The URL utility produces:

```text
{scheme}://{baseUrl}/api/v1
```

The user must not enter a scheme or `/api/v1`. URL validation rejects whitespace, duplicate schemes, empty hosts, queries, and fragments.

## 5. Gateway save data flow

```text
GatewayFormPage
  → GatewayController local validation
  → SaveGateway use case
  → GatewayRepository
  → DioClient.validateGateway
      → GET /health
      → GET /diagnostics + Bearer token
  → GatewayLocalDataSource
  → SQLite
```

Persistence happens only after both API checks succeed. A failed edit does not overwrite the previously saved record.

## 6. Dio design

`DioClient.instance` is the shared Dio service.

Configuration:

- Connect timeout: 8 seconds.
- Send timeout: 8 seconds.
- Receive timeout: 15 seconds.
- Successful responses: HTTP 2xx.
- Request/response/error interceptors use `AppLogger`.

Logging rules:

- Log method, safe path, status, and safe error category.
- Never log `Authorization` headers.
- Never log API tokens or raw credential payloads.
- Never include raw server error bodies in user notifications.

API response mapping belongs in the network/repository boundary, not in widgets.

## 7. SQLite design

Current gateway table:

```sql
CREATE TABLE gateways (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  scheme TEXT NOT NULL,
  base_url TEXT NOT NULL,
  api_token TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

Timestamps use Unix epoch milliseconds. Database migrations must increment the database version and preserve existing data.

Device data is owned by the gateway API in the MVP. Local device caching is a later decision and must not silently replace gateway state.

## 8. API model boundaries

Models map JSON/API field names at the data boundary. Domain use cases should consume typed models/entities rather than raw `Map<String, dynamic>` values.

Required gateway API groups:

```text
health
diagnostics
discovery
devices CRUD
device status
device wake
```

`POST /discovery/scan` returns candidates only. `POST /devices` is the persistence operation.

## 9. Add Device design

```text
GatewayDashboardPage
  → DiscoveryScanPage
      ├── select discovery candidate
      │     → DeviceAddEditPage(discovery: candidate)
      └── footer Add manually
            → DeviceAddEditPage()

GatewayDashboardPage long press device
  → DeviceAddEditPage(device: existing)

DeviceAddEditPage
  → DeviceRepository.save
```

Page files remain separate by responsibility:

```text
lib/presentation/pages/device/discovery_scan_page.dart
  DiscoveryScanPage

lib/presentation/pages/device/device_add_edit_page.dart
  DeviceAddEditPage
```

`DeviceAddEditPage` handles both add and edit. It is named after the feature action, not `form`, to avoid confusing a reusable form widget with a navigable page. Edit opens only this page; discovery controls exist only on `DiscoveryScanPage`.

Discovery candidates may have a null MAC address. `DeviceAddEditPage` must allow completion before submitting the device create request. Empty discovery results must preserve a usable manual path through the scan page footer.

## 10. Future feature page ownership

New page flows follow the same structure:

```text
lib/presentation/pages/status/
  device_status_page.dart
  device_wake_page.dart

lib/presentation/pages/diagnostics/
  diagnostics_page.dart

lib/presentation/pages/settings/
  settings_page.dart

lib/presentation/pages/auth/
  sign_in_page.dart
```

Exact names may change with feature design. Folder-per-feature and one-page-per-file rules remain mandatory.

## 11. Theme and colors

Theme tokens live in:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_theme.dart
```

Rules:

- `main.dart` consumes `AppTheme.light`.
- Application-specific colors use `AppColors`.
- Material state colors use `Theme.of(context).colorScheme`.
- No scattered hex colors in pages, widgets, controllers, or utilities.
- Current visual direction: light framed sheet, flat surfaces, quiet borders, one teal action color, no gradients, and no resting shadows.

## 12. Responsive design

Use `MediaQuery`, `LayoutBuilder`, `ConstrainedBox`, `Expanded`, `Flexible`, and `Wrap`.

```text
mobile:  < 600
tablet:  600–1023
desktop: >= 1024
```

Wide forms are constrained. Phone content uses tighter horizontal padding. No responsive package is required.

## 13. Widget extraction

Start with the smallest local helper. A repeated widget used only within one page remains private to that page. Extract a widget to `lib/presentation/widgets/` only when multiple pages reuse the same behavior and visual contract.

Example:

```text
lib/presentation/widgets/app_text_field.dart
class AppTextField extends StatelessWidget
```

Do not create generic abstractions for one caller.

## 14. Form and feedback conventions

- Use a custom `Text` label above each field.
- Do not use `InputDecoration.labelText`.
- Keep field helper text close to its field.
- Use `AppSnackbar`, backed by `Get.snackbar`.
- Do not use `ScaffoldMessenger` for application feedback.
- Disable submit controls during async saves.
- Confirm destructive actions.

## 15. Firebase sync design — post-MVP

Firebase is not required for guest MVP usage. It begins after the gateway API workflow is verified.

### Authentication

- Firebase email/password.
- Google sign-in.
- Session restoration.
- Logout.
- Guest mode remains available.

### Firestore structure

```text
users/{uid}/gateways/{gatewayId}
```

Document fields:

```text
name
scheme
baseUrl
apiToken
ownerId
createdAt
updatedAt
```

The token is plaintext by explicit product decision. Firebase Auth and Firestore Rules provide access control; they do not encrypt the token.

### Firestore Rules intent

```text
request.auth != null
AND request.auth.uid == path uid
AND ownerId cannot change
```

User A must not read or write `users/{userB}/gateways/*`. Create, update, delete, and read rules must validate ownership independently.

### Sync behavior

```text
Firebase login/app start
→ pull cloud gateways
→ merge local records
→ upload local changes
→ update local SQLite cache
```

- Automatic sync on login/app start.
- Manual refresh action.
- Last-write-wins using `updatedAt`.
- Editing an API token through Edit Gateway is a normal gateway update.
- No token rotation feature is implemented in the client.
- Token changes must not be logged.

### Infrastructure boundary

The existing Firebase project is connected only when the sync checkpoint begins. No Cloud Functions, KMS, encryption service, or sync passphrase is required under the current product decision.

## 16. Testing strategy

### Unit tests

- URL construction and validation.
- Model mapping.
- Use case behavior.
- Error mapping.

### Widget tests

- Gateway empty/list states.
- Add/edit form labels and validation.
- Long-press action sheet.
- Loading and disabled save state.

### Live/API verification

Use an available gateway to verify every endpoint and failure condition listed in `API_DOC.md`. Separate live evidence from local unit/test evidence.
