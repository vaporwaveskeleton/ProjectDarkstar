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
| `LanceProjectile` | `lance_hit` | `target: Node` | tests; future hit-spark VFX/audio | built |
| `ArcLanceEmitter` | `lance_fired` | `direction: Vector2` | tests; future fire cue (AudioService) | built |
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
| `ArcadeWorld` (Act 0) | `score_awarded` | `points: int, at: Vector2` | `CabinetGame` → `ScoreKeeper` | built |
| `ArcadeWorld` | `vigil_destroyed` | — | `CabinetGame` (respawn / game over) | built |
| `ArcadeWorld` | `charges_changed` | `count: int` | `CabinetGame` → HUD lamps | built |
| `ArcadeWorld` | `segments_changed`, `phase_changed` | `count: int` / `phase: int` | tests; future music escalation | built |
| `ArcadeWorld` | `entity_line`, `caption` | `key: String` (an `en.po` key, never text) | `CabinetGame` → `CabinetMessages` | built |
| `ArcadeWorld` | `entity_unmade`, `sepulchre_cleared` | — | `CabinetGame` (stage flow) | built |
| `ArcadeWorld` | `hitstop_started` | `beat: StringName` (`charge_hits_entity`, `entity_unmade`, `vigil_death`, `it_wakes`, `modules_knocked`); emitted when a freeze starts or extends | `AudioService` cues (audio chat); no other listeners | built |
| `ArcadeWorld` | `slowmo_changed` | `scale: float` (the new `sim_scale`; emitted on every change, including exactly 1.0 at the end; Reduced Motion never emits below 1.0) | `CabinetGame` → `AudioService.set_bed_pitch_scale(scale)` (audio chat's chant-bed pitch, AUDIO-001 §12.11); `CabinetGame` also resets it to 1.0 on exit and stage start | built |
| `CabinetMessages` | `credits_stat_shown` | `index: int` (the stat line's index in the roll; emitted once per stat line as it scrolls into view) | `CabinetGame` (plays AudioService cue `tally_blip`) | built |
| `ScoreKeeper` | `score_changed`, `lives_changed`, `extra_life_awarded` | `int` / `int` / — | `CabinetGame` → HUD | built |
| `PretenceReveal` | `finished` | — | `CabinetGame` (save flags, route to the Ruins) | built |
| `CoinSlot` | `tape_peeled` | — | `AttractMode` (saves `cabinet_tape_peeled`, reason `cabinet_tape`) | built |
| `CoinSlot` | `credit_inserted` | — | `AttractMode` (enables New Vigil, marquee text, CREDIT counter) | built |
| `PowerOnTest` | `finished` | — | `AttractMode` (reveals the attract screen) | built |
| `ScenarioRunner` (dev/QA only, `core/automation`) | `scenario_finished` | `outcome: StringName` (`pass`, `fail`, `timeout`, `invalid`, `refused`) | GdUnit adapter (`tests/test_scenarios.gd`), dev/QA builds only | built |

Add a row before you add a signal. Remove the row when you remove the signal.

## 3. No global event bus

There is no `EventBus` autoload. A global bus hides who depends on whom and makes the HUD-lie rules (WARP-001 §4.2) impossible to audit. When a far-away system needs to react (e.g. audio reacting to a hit), wire it from the scene that owns both ends (the `SectorHost`), or give the listener an `@export` reference. Revisit only with a TECH-001 §11 entry.

## 4. Animation events
Animation method tracks may *request* gameplay events (open a hitbox window, play a cue). The gameplay component validates and emits the signal; listeners never subscribe to animation frames (TECH-001 §2.5).

## 5. Telemetry and saves
Telemetry keys (SYS-001 §8) and save payloads use invariant ids. A signal payload that crosses into a save or telemetry record must already be an id or a number.
