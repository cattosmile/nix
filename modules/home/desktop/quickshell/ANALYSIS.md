# Quickshell Config Analysis

## Docs / Best Practices Found

- **Singleton root type**: Docs say singletons should use `Singleton { }` as root, not `QtObject`.
- **ComponentBehavior: Bound**: Recommended for all QML files. You already do this.
- **Process usage**: Avoid process-per-widget. Prefer event-driven APIs (Pipewire, rfkill event, mullvad listen) over polling.
- **Transparent windows**: Use `mask: Region {}` on fully transparent `PanelWindow`s. You do this.
- **State survival**: `PersistentProperties` survives config reloads. `IpcHandler` exposes controls to external scripts.
- **Hyprland IPC**: Reference configs manually refresh `workspaces`/`monitors`/`toplevels` on `Hyprland.rawEvent` to avoid stale state.
- **Time**: `SystemClock` builtin is preferred over spawning `date`.
- **Layershell**: Set unique `WlrLayershell.namespace` per window type. You do this.

## What Your Config Does Well

- `pragma ComponentBehavior: Bound` on all QML files.
- Services in `services/` are real singletons with `qmldir`.
- Event-driven updates: Bluetooth (`rfkill event`), VPN (`mullvad status listen`).
- Proper `mask: Region {}` on border, bar, and exclusion windows.
- Dynamic exclusion zone width synced to animated bar width.
- Clean separation: `border/` for UI, `services/` for data.

## Issues / Gaps

### 1. Theme.qml root type
`Theme.qml` roots in `QtObject`. Docs recommend `Singleton` type for singletons.

### 2. Hyprland state refresh missing
Your `WorkspaceSwitcher` reads `Hyprland.monitors`/`workspaces` directly without refreshing on events. The reference `Hypr.qml` adds a `Connections { target: Hyprland; onRawEvent: ... }` block that explicitly calls `refreshWorkspaces()`, `refreshMonitors()`, `refreshToplevels()` depending on event name. Without this, workspace/monitor state can lag.

### 3. Recorder service polls instead of listening
`Recorder.qml` runs a `pgrep`/`pw-cli` shell every 7.5 s. The reference `Audio.qml` tracks `Pipewire.nodes` with `PwObjectTracker` and reacts to value changes. You could filter `Pipewire.nodes` for nodes whose properties match `screen|desktop|screencast` and eliminate polling.

### 4. Bluetooth lacks fallback timer
`Bluetooth.qml` relies only on `rfkill event`. `Wifi.qml` has a 10 s fallback `Timer`. Bluetooth should have the same safety net in case the event stream stalls.

### 5. No PersistentProperties / IpcHandler
Bar expanded state, menu scroll position, etc. are lost on quickshell reload. The reference uses `PersistentProperties` (backed by QSettings) to survive restarts and `IpcHandler` so external commands can query/toggle state.

### 6. MenuIsland infinite-scroll model is wasteful
`model: 10800` with `ListView` and modulo math works but creates a huge internal model. A `PathView` or wrapping logic on a 9-item model is cleaner and lighter.

### 7. Unnecessary Loader in MenuIsland
`Loader` always loads `textComponent`. The `Text` can live directly inside the root `Rectangle`.

### 8. Missing features present in reference
- **Idle inhibitor**: Reference uses `IdleInhibitor` with a zero-size `PanelWindow`.
- **Notification server**: Reference implements `NotificationServer` with popups and history.
- **Global shortcuts / IPC**: Reference exposes `CustomShortcut`s and `IpcHandler` targets for media control, DND, etc.
- **SystemClock**: Not needed now, but better than `Process` if you add a clock later.

### 9. StatusIsland process spawning
Right-click menus spawn `Process` objects via `Component.createObject` with `destroy()` on exit. This is acceptable but easy to leak if `onRunningChanged` ever misfires. Not a bug now, just fragile.

## Recommendations (No changes made yet)

1. **Fix `Theme.qml`**: change root from `QtObject` to `Singleton`.
2. **Add Hyprland refresh logic**: mirror the reference `Connections` on `Hyprland.rawEvent` to keep workspace/monitor state fresh.
3. **Event-driven Recorder**: replace polling with `Pipewire.nodes` bindings + `PwObjectTracker`.
4. **Add fallback Timer to Bluetooth**: match `Wifi.qml`.
5. **Add `PersistentProperties`**: at least for bar expanded state so it survives reload.
6. **Simplify MenuIsland**: remove `Loader`, shrink model.
7. **Evaluate adding `IdleInhibitor` / `NotificationServer` / `CustomShortcut`**: only if you want those features.
