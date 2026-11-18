# DARKSTAR — Signals and Events

**Doc ID:** EVT-001 · **Version:** 1.0 · **Date:** 2026-11-17 · **Owner:** production
**Upstream:** TECH-001 §2 (scene tree) · **Downstream:** every script that declares or connects a signal

## 1. When to use what

| Situation | Use | Example |
|---|---|---|
| A child reports something to whoever owns it, and must not know who that is | **signal**, past tense | `HealthComponent.health_depleted` → `Vigil` |
| A parent tells a child it owns what to do | **direct call** through a typed `@export` or `%Unique` ref | `ScreenStack.push(screen)` |
| A screen asks for a top-level scene change | call `SceneRouter.go_to(&"route_id")` | `AttractMode` → `&"sector"` |
| Find "all things of a kind" | **group** | `"vigil"` |
| Shared configuration | **Resource** | `VigilMoveStats` |

Rules: signal names are past tense (`hull_breached`, `save_failed`), payloads are typed, and payloads carry invariant ids or numbers, never display text. Connect in code in the receiver's `_ready` (or in the scene for in-scene wiring); disconnect only when the receiver outlives the sender.

## 2. Signal register

| Sender | Signal | Payload | Listeners | Status |
|---|---|---|---|---|
| `HealthComponent` | `damaged` | `amount: int, remaining: int` | `SectorStub` (HUD refresh) | built |
| `HealthComponent` | `healed` | `amount: int, remaining: int` | — | built |
| `HealthComponent` | `health_depleted` | — | `Vigil` | built |
| `HealthComponent` | `hit_rejected` | `reason: StringName` (`depleted`, `same_window`, `invulnerable`, `no_damage`) | tests, future debug overlay | built |
| `HurtboxComponent` | `hit_received` | `hit: HitInfo, accepted: bool` | future VFX/audio feedback | built |
| `HitboxComponent` | `hit_landed` | `hurtbox: HurtboxComponent, accepted: bool` | future score/feedback | built |
| `Vigil` | `hull_breached` | — | `SectorStub` (HUD) | built |
| `SceneRouter` | `route_changed` | `route_id: StringName` | `Boot` (smoke path) | built |
| `SceneRouter` | `route_failed` | `route_id, reason: StringName` (`unknown_route`, `load_failed`) | future error toast via `PlayerMessages.route_message` | built |
| `SaveService` | `save_completed` | `slot: StringName` | future save indicator | built |
| `SaveService` | `save_failed` | `slot, reason: StringName` | future toast via `PlayerMessages.save_message` | built |
| `SaveService` | `load_failed` | `slot, reason: StringName` | same | built |
| `SettingsService` | `setting_changed` | `key: StringName, value: Variant` | none yet (the settings screen reads values on open); future HUD/warp (Steady Ledger, photosensitivity) | built |
| `Screen` | `closed` | — | the screen's opener | built |
| `ConfirmScreen` | `confirmed`, `cancelled` | — | the opener (`PauseScreen`) | built |
| `PauseScreen` | `abandon_requested` | — | `SectorStub` | built |
| `ScreenStack` | `screen_pushed`, `screen_popped`, `emptied` | `screen` / — | `SectorStub` (unpause on `emptied`) | built |
| `InputModeTracker` | `input_mode_changed` | `mode: Mode` | future glyph widgets, cursor visibility | built |

Add a row before you add a signal. Remove the row when you remove the signal.

## 3. No global event bus

There is no `EventBus` autoload. A global bus hides who depends on whom and makes the HUD-lie rules (WARP-001 §4.2) impossible to audit. When a far-away system needs to react (e.g. audio reacting to a hit), wire it from the scene that owns both ends (the `SectorHost`), or give the listener an `@export` reference. Revisit only with a TECH-001 §11 entry.

## 4. Animation events
Animation method tracks may *request* gameplay events (open a hitbox window, play a cue). The gameplay component validates and emits the signal; listeners never subscribe to animation frames (TECH-001 §2.5).

## 5. Telemetry and saves
Telemetry keys (SYS-001 §8) and save payloads use invariant ids. A signal payload that crosses into a save or telemetry record must already be an id or a number.
