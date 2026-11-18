# DARKSTAR — UI Architecture (menus, overlays, buttons)

**Doc ID:** UI-001 · **Version:** 1.1 · **Date:** 2026-11-17 · **Owner:** production
**Upstream:** GDD §10 (menus, accessibility), ART-001 §4 (palette) and §7 (UI art), WARP-001 §4 (HUD lie law, Steady Ledger), AUDIO-001 §6.2 (I06–I08 UI cues), SYS-001 §9 (safe area at 200 % text)
**Not here:** HUD lie content (WARP-001 §4), diegetic HUD implementation (TECH-001 §5, `DiegeticHud` row), player-text keys and English copy rules (L10N-001)

## 1. Screen inventory

| Screen | Required by | Status |
|---|---|---|
| Attract mode (title): the cabinet marquee (DARKSTAR in the Cabinet face), INSERT CREDIT (PRESS NEW VIGIL once credited), high score, drifting vector field, CRT glass; first attract of a launch opens with the power-on self-test (any input skips); four instruction cards cycle (pitch, how to play, mission, score table); a hazard-taped coin door on the right bezel (peel the tape, insert a coin); New Vigil is greyed and outside the focus loop until a credit is in, then spends it; Settings, Quit; 30 s idle (not while a credit waits or a peel is in progress) plays the autopilot demo, any input returns | GDD §10, WARP-001 W0-01/W0-03 | built — `scenes/attract/` |
| Settings: large text, reduced motion, photosensitivity, Steady Ledger (no language setting: English only, L10N-001 §1) | GDD §10, WARP-001 §4.4 | built (subset) — `scenes/settings/` |
| Pause: Resume, Settings, Abandon Run | GDD §4.1, WARP-001 §4.4 W4-07 | built — `scenes/sector/pause_screen.tscn` |
| Confirmation (two-choice, safe default) | brief | built — `scenes/common/confirm_screen.tscn` |
| Loading / transition curtain | brief | built (fade) — `scenes/boot/boot.tscn` |
| Act 0 cabinet HUD: 4:3 bezel, 1UP/score, Vigils, glass-lamp Charge pips, Ledger Compass mini-map; READY card, banners, captions, credits, the entity's big type | WARP-001 W0-01/W0-02/W0-04, ART-001 §11.5 | built — `features/cabinet/` (TECH-001 §2.10) |
| HUD (diegetic, may lie) | WARP-001 §4 | Act 1+: stub (one honest hull label) |
| Rebinding, mouse sensitivity, aim assist, colourblind variants, subtitles, audio options | GDD §10, AUDIO-001 §8.4 | planned |
| Death / cause-of-death screen | GDD §6.3, §8.9; AUDIO-001 §4.10 | planned |
| Ruins first arrival (title, the lit sapling, continue) | GDD §6.4 | stub — `scenes/ruins/` |
| Ruins hub, Lantern Tree, Chalk Desk, Codex, run summary | GDD §6.4, LOOP-001 §3, §7 | planned |
| Endings / credits | GDD §9.3 | planned |
| Act 0 high-score screen ("honour roll"): three-letter initials entry after any Act 0 clear, Cabinet face (ART-001 §11); from Hard Unmaking 3 the table also lists `T.L. — 0 WARD 0 SURGE` | NARR-001 §14 Q-03, LOOP-001 §11.6 | planned |
| Streamer mode (settings toggle): SeedCode shown on the HUD and the pause screen, Vigil Index on pause, no OS user name anywhere | MARKET-001 §8.2 | planned |
| Save failure / recovery notice | brief | text keys exist (`MSG_SAVE_*`); no toast widget yet |
| Shop, equipment, skills, classic inventory, quest log | brief | **N/A** — no such systems in the GDD |

## 2. Structure

```
Route scene (e.g. AttractMode : Screen)        one per SceneRouter route
├─ its Controls (primary action = default_focus)
├─ Overlays : ScreenStack (CanvasLayer)         modal stack for THIS scene only
│    └─ SettingsScreen / PauseScreen / ConfirmScreen …  (each a Screen)
└─ InputModeTracker
```

* No UI autoload. Each route scene owns one `ScreenStack`. Overlays never reach across scenes.
* Screens hold **no game state**. They read services (`SettingsService`) or resources and emit intent signals (`abandon_requested`), or call `SceneRouter.go_to`.
* The scene that owns the stack owns side effects such as pausing (`SectorStub` pauses on push and unpauses on `emptied`).

## 3. The `Screen` contract (`core/ui/screen.gd`)

| Member | Rule |
|---|---|
| `default_focus` | the one primary action; focused on open. Destructive dialogs default to the **safe** choice |
| `remember_focus()` / `focus_entered_screen()` | the stack calls these, so closing an overlay restores focus to the control that opened it |
| `ui_cancel` | only the top screen answers it. Overlays close. The root screen sets `cancel_closes = false` (cancel does nothing, never quits) |
| `close()` | pops from the owning stack, or frees itself if it has none |

`FitScrollContainer` (`core/ui/fit_scroll_container.gd`) wraps every overlay's rows. It is as tall as its content until the content would leave the safe area, then it scrolls and follows focus.

## 4. Interaction rules

| Rule | How it is met |
|---|---|
| One clear primary action | `default_focus`; attract → the coin door until a credit is in, then New Vigil |
| Explicit focus neighbours, no dead ends | every button sets `focus_neighbor_top/bottom` (wrapping); tested |
| Reliable `ui_cancel` | `Screen._unhandled_input`; root screens ignore it; tested |
| Repeated input | busy state: New Vigil disables the menu; `SceneRouter.go_to` ignores calls while busy; Confirm disables itself on press |
| Transitions | 150–300 ms (`Boot.TRANSITION_S = 0.2` ✱). Instant when `reduced_motion` is on |
| Immediate feedback | Theme hover/pressed/focus styles. Audio cues I06 (confirm/back) and I07 (hover) from AUDIO-001 §6.2 are **not wired yet** |
| Input-method changes | `InputModeTracker` emits `input_mode_changed`. Glyph widgets are planned |
| Text scaling | `SettingsService.text_scale` 1.0 / 2.0 → `UiTheme.apply_text_scale` resizes the project Theme |
| Safe area at 200 % text | all controls stay inside the 640×360 logical rect (SYS-001 §9; stays valid in logical units after Act 0); tested for attract and settings |
| Resolution / aspect | `viewport` stretch, `keep` aspect, integer scale (TECH-001 §1.2–§1.3) is the current code. Owner, 2026-11-18: after Act 0 the UI renders at native resolution (decided, not yet implemented; TECH-001 §1.1, Q-T23). Layouts use anchors/containers only. Post-Act 0 UI is modern game-UI structure and UX (hierarchy, primary vs secondary actions, focus, input glyphs, list/preview/detail) with chalk-and-brass as the skin (D-C) |
| Touch-safe targets | Windows-only, mouse targets ≥ ~22 logical px tall (✱ content margins). No touch support planned |
| Steady Ledger / Esc always pauses | the `pause` action opens the real pause screen whenever the overlay stack is empty (WARP-001 §4.4) |
| Accessibility rows never lie or hide | settings read live from `SettingsService` (WARP-001 §4.7) |
| Photosensitivity | stored; no flicker exists yet to suppress. Must never hide information (GDD §10) |

## 5. Control states

| State | Look (Theme `data/ui/darkstar_theme.tres`) | Status |
|---|---|---|
| idle | VOID-1 fill, 1 px BONE-1 keyline, BONE-5 text ("chalk on slate", ART-001 §7) | built |
| hover | VOID-2 fill, BONE-3 keyline | built |
| focus | 2 px GAS-3 outline — the cursor is the player's lamp (ruling R-09, ART-001 §12) | built |
| pressed / selected | VOID-3 fill, 2 px GAS-2 bottom keyline (R-09) | built |
| disabled | VOID-0 fill, BONE-0 keyline, BONE-1 text | built |
| busy / loading | disabled look while routing; the curtain covers the change | built |
| error | `ErrorLabel` BONE-5 text + chalk-strike icon (shape-coded, never SIGNAL); reassurance line in `TruthLabel` PHOS-4 (R-09) | theme built; icon planned |
| cooldown | GAS-2 sweep over VOID-2 on the button or HUD glyph (R-09) | planned with Surgelight |

Theme variations: `HeaderLabel`, `HintLabel`, `ErrorLabel`, `TruthLabel`, `DimPanel`. Every colour is a palette entry (tested by `core/ui/tests/test_theme_palette.gd`). Not yet done: the ±1 px chalk wobble (ART-001 §7), the Act 0 cabinet-bezel costume layer, and the bitmap font (ART-001 has no font section; TECH-001 §11 Q-T02).

## 6. Player-readable output
Everything on screen comes from a `tr()` key in `locale/en.po` (L10N-001). Failure codes go through `PlayerMessages`, which maps them to a sentence saying what happened, whether progress is safe, and what to do next. Raw codes, paths, enum names and exceptions go to `push_warning`/`push_error` only. Authored HUD lies (WARP-001 §4.2) are content, not bugs. A raw key, debug value or error string on screen is a bug.

## 7. Tests
`scenes/tests/test_attract_mode.gd`, `scenes/tests/test_attract_coin_slot.gd` (tape peel by hold/drag/pad A, coin → credit → New Vigil, power-on skip, page cycle, binding labels) and `scenes/tests/test_sector_and_pause.gd` cover focus on open, focus loops, modal stacking up to three deep, focus restoration, `ui_cancel` and the `pause` action, repeated input, safe area at 200 % text, and no raw keys on screen. `tests/test_boot_flow.gd` covers input-mode switching. Window-size variation is **not** automated yet.

## 8. Adding a screen
1. Create `scenes/<area>/<name>_screen.tscn` with a `Control` root using a script that `extends Screen`. Wrap the rows in `FitScrollContainer`.
2. Set `default_focus` and the focus neighbours of every control.
3. Use Theme variations only; no inline colours outside the palette.
4. Put every string in `locale/en.po` with a context note.
5. Open it with `stack.push(scene.instantiate())` from the owning scene.
6. Add a test: focus on open, `ui_cancel`, safe area at 200 % text.

## 9. Open questions
* None open. Focus, error and font questions were ruled 2026-11-17 (TECH-001 §11.1a R-02, R-09); the full spec is ART-001 §11 (typography) and §12 (UI states). Until the bitmap faces are drawn, the code uses Godot's fallback font at ✱ 14/28 px; when Ledger lands, `UiTheme.BASE_FONT_SIZE` becomes the Ledger cell height and text scale stays an exact ×2.
