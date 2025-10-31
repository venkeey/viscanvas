## Automated Testable Features Catalog

This document enumerates the kinds of features an automated test can validate in this app (and Flutter apps generally). Each item lists suitable test levels: Unit (U), Widget (W), Integration (I), End‑to‑End (E2E), Visual/Golden (V).

### Core Functionality
- Business logic and domain rules — U, W
- Data transformations, parsing/serialization (JSON, codecs) — U
- Validation rules (forms, inputs) — U, W, I
- State management flows (providers, blocs, notifiers) — U, W, I
- Feature flags and configuration gating — U, W, I

### UI/UX Behavior
- Widget rendering and layout structure — W, V
- Navigation (stack, deep links, guarded routes) — W, I, E2E
- Gestures (tap, drag, long‑press, scroll, pinch) — W, I, E2E
- Keyboard input and shortcuts (desktop/web) — W, I
- Focus traversal and tab order — W, I
- Animations (timing, curves, end‑state) — W, V, I
- Responsive layouts (phone/tablet/desktop, orientation) — W, I, V
- Theming (light/dark, high contrast) — W, V, I
- Localization (i18n strings), RTL layouts — W, V, I
- Accessibility semantics (labels, roles, actions) — W, I
- Error and empty states (placeholders, retries) — W, I, V
- Context menus, tooltips, hover states — W, I, V
- Drag & drop and clipboard interactions — W, I, E2E

### Visual Correctness
- Golden snapshots of widgets/screens — V
- Pixel‑diff of entire flows/screens — V, I, E2E
- Iconography, typography, spacing scales — V
- Color tokens and contrast thresholds — V

### Data and Persistence
- Local storage (shared prefs, files, secure storage) — U, I, E2E
- Database operations/migrations (schema, indices) — U, I
- Caching layers (in‑memory, disk) — U, I
- Data sync, conflict resolution, merge policies — U, I, E2E
- Offline/online transitions and replay — I, E2E

### Networking and API
- HTTP requests (methods, headers, auth) — U, I
- Error handling (timeouts, 4xx/5xx, backoff) — U, I
- Retries, debouncing, throttling — U, I
- Pagination, filtering, sorting, search — U, I, E2E
- Contract/schema compatibility (DTOs) — U

### Performance and Reliability
- Frame timings (build/raster times, jank) — I
- Startup time (cold/warm), shader warm‑up — I
- Memory usage patterns/leak detection heuristics — I
- CPU/GPU hotspots under load — I
- Long‑list virtualization and scrolling smoothness — W, I
- Stability under flaky network/chaos (packet loss, latency) — I, E2E

### Platform and Device Features
- Permissions prompts and flows — I, E2E
- Notifications (foreground/background handling) — I, E2E
- Deep links and app links (cold/warm state) — I, E2E
- Background/lifecycle transitions (resume, pause, kill) — I, E2E
- File system access (open/save/share) — I, E2E
- Camera, gallery, media pickers — I, E2E
- Sensors (accelerometer, geolocation) — I, E2E
- Platform channels/plugins behavior — U, I

### Security and Compliance
- Static analysis (lints, dangerous APIs) — U
- Sensitive data handling (no logs, masked UI) — W, I, V
- Input sanitization and output encoding — U, W
- Transport security (HTTPS enforced) — U, I
- AuthN/AuthZ flows, token refresh, session expiry — U, I, E2E

### Error Handling and Observability
- Exceptions mapped to user‑friendly messages — U, W
- Retry surfaces and safe fallbacks — U, W, I
- Logging levels and redaction — U, I
- Analytics events fired with correct payloads — U, I, E2E

### Build/Env/Config
- Env switching (dev/stage/prod) — U, I
- Feature toggles per environment — U, I
- Compile‑time flags and flavors — U

### Accessibility (A11y)
- Semantics tree completeness — W
- Labels, hints, actions coverage — W
- Minimum tap target sizes — W, V
- Screen reader navigation and order — I

### Usability Details
- Undo/redo behaviors — U, W, I
- Autosave, draft recovery — I, E2E
- Conflict dialogs and confirmations — W, I, V
- Progress indicators and loading states — W, I, V

### Concurrency and Race Conditions
- Debounce/coalesce user actions — U, W
- Concurrent requests, cancellation — U, I
- Idempotent operations and deduplication — U, I

### Time, Scheduling, and Background Work
- Timers and periodic tasks — U, I
- Time zone and locale formatting — U, W
- Date math edge cases (DST, leap years) — U

### Complex UI Patterns
- Forms: validation, save/submit/reset — U, W, I
- Lists/grids: recycling, animated updates — W, I, V
- Canvas/graphics: drawing, hit‑testing, zoom/pan — W, I, V
- Rich text editors/command menus — W, I, V

### Cross‑Platform Compatibility
- Platform‑specific widgets and behaviors — W, I
- Desktop windowing, resizing, DPI scaling — I, V
- Web differences (pointer/hover, keyboard) — W, I

### What to Test vs. Where to Test
- Pure logic: prefer Unit
- Rendering and interactions: Widget
- Device/platform, plugins, lifecycle: Integration
- Full journeys and external systems: E2E
- Visual fidelity and regressions: Visual/Golden

### Example Assertions by Category
- Visual: "Screen matches golden", "No unexpected diffs"
- UX: "Tapping button navigates to detail screen"
- Data: "Saving item persists across relaunch"
- Network: "Retries stop after backoff budget"
- Performance: "Average raster time < 16ms"
- A11y: "Primary actions have semantics labels"
- Security: "Logs do not contain access tokens"

### Coverage Strategy
- Aim for high unit coverage on core logic
- Target critical paths with widget/integration tests
- Keep a curated golden set for key screens/states
- Add E2E smoke tests for main user journeys
- Measure and enforce performance budgets in CI

### Related Docs
- See `test/README.md` for how to run each suite
- See `analysis_options.yaml` for static checks configuration


