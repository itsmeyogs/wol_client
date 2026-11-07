# WoL Gateway Client — Design

```text
Presentation (GetX)
  → Domain (use cases/repository contracts)
    → Data (repository/data sources/models)
      → Core (Dio, logger, database, responsive)
```

## Dependency injection

All application dependencies are registered in `presentation/bindings/app_binding.dart` through GetX `Bindings`. `main.dart` only initializes Flutter/platform database support and starts the app.

Dependency graph:

```text
AppDatabase + DioClient
→ GatewayLocalDataSource
→ GatewayRepository
→ GetGateways / SaveGateway / DeleteGateway
→ GatewayController
```

`GatewaySessionController` is registered as a permanent session dependency. Infrastructure and use cases use lazy registration with `fenix: true`; controllers resolve their constructor dependencies through `Get.find<T>()`. Pages resolve controllers through GetX (`GetView`/`Get.find`), not manual construction.

Save flow:

```text
Local validation
→ GET {scheme}://{baseUrl}/api/v1/health
→ GET {scheme}://{baseUrl}/api/v1/diagnostics with Bearer token
→ SQLite only after both succeed
```

One gateway is active in `GatewaySessionController.activeGateway`; no `isSelected` field.

## UI direction

The app uses a light framed-sheet direction: tinted app ground, quiet white work surfaces, flat borders, one teal action colour, no gradients, no resting shadows, and no decorative dashboard metrics. Gateway cards expose the connection target and the two useful actions: open and edit. The primary add action is a compact `+` FAB with an accessible tooltip.

Responsive rules use native Flutter layout primitives. Content is constrained on wide screens and padded more tightly on phones. Empty, loading, error, disabled, and confirmation states are explicit.

## Theme and colors

Theme tokens live in `lib/core/theme/`:

```text
app_colors.dart  semantic color constants
app_theme.dart   ThemeData and Material component themes
```

Use `AppTheme.light` from `main.dart`. Use `AppColors` for application-specific colors and `Theme.of(context).colorScheme` for Material state-aware colors. Do not add hex colors directly inside pages, widgets, controllers, or utilities.

## Interaction conventions

- Gateway card tap opens the gateway session.
- Gateway card long press opens Edit/Delete actions.
- Scheme selection uses a horizontal radio group; Base URL follows below it.
- Form fields use an explicit `Text` label above each field; `InputDecoration.labelText` is not used.
- Transient feedback uses `AppSnackbar`, backed by `Get.snackbar`, without `ScaffoldMessenger` or `BuildContext`.

## Widget extraction

Keep a repeated widget as a private page helper when its usage and styling are page-specific. Move a widget to `lib/presentation/widgets/` only when the same behavior and visual contract are reused across multiple pages. Name shared files and classes after the component, for example `app_text_field.dart` / `AppTextField`.
