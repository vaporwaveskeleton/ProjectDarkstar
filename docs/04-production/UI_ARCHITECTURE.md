# DARKSTAR — UI Architecture (menus, overlays, buttons)

**Doc ID:** UI-001 · **Version:** 1.0 · **Date:** 2026-11-17 · **Owner:** production
**Upstream:** GDD §10 (menus, accessibility), ART-001 §4 (palette) and §7 (UI art), WARP-001 §4 (HUD lie law, Steady Ledger), AUDIO-001 §6.2 (I06–I08 UI cues), SYS-001 §9 (safe area at 200 % text)
**Not here:** HUD lie content (WARP-001 §4), diegetic HUD implementation (TECH-001 §5.2), localization (L10N-001)

## 1. Screen inventory

| Screen | Required by | Status |
|---|---|---|
| Attract mode (title): New Vigil, Settings, Quit | GDD §10 (three clicks to play) | built — `scenes/attract/` |
| Settings: language, large text, reduced motion, photosensitivity, Steady Ledger | GDD §10, WARP-001 §4.4 | built (subset) — `scenes/settings/` |
| Pause: Resume, Settings, Abandon Run | GDD §4.1, WARP-001 §4.4 W4-07 | built — `scenes/sector/pause_screen.tscn` |
| Confirmation (two-choice, safe default) | brief | built — `scenes/common/confirm_screen.tscn` |
| Loading / transition curtain | brief | built (fade) — `scenes/boot/boot.tscn` |
| HUD (diegetic, may lie) | WARP-001 §4 | stub: one honest hull label |
| Rebinding, mouse sensitivity, aim assist, colourblind variants, subtitles, audio options | GDD §10, AUDIO-001 §8.4 | planned |
| Death / cause-of-death screen | GDD §6.3, §8.9; AUDIO-001 §4.10 | planned |
| Ruins hub, Lantern Tree, Chalk Desk, Codex, run summary | GDD §6.4, LOOP-001 §3, §7 | planned |
| Endings / credits | GDD §9.3 | planned |
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
| One clear primary action | `default_focus`; attract → New Vigil |
| Explicit focus neighbours, no dead ends | every button sets `focus_neighbor_top/bottom` (wrapping); tested |
| Reliable `ui_cancel` | `Screen._unhandled_input`; root screens ignore it; tested |
| Repeated input | busy state: New Vigil disables the menu; `SceneRouter.go_to` ignores calls while busy; Confirm disables itself on press |
| Transitions | 150–300 ms (`Boot.TRANSITION_S = 0.2` ✱). Instant when `reduced_motion` is on |
| Immediate feedback | Theme hover/pressed/focus styles. Audio cues I06 (confirm/back) and I07 (hover) from AUDIO-001 §6.2 are **not wired yet** |
| Input-method changes | `InputModeTracker` emits `input_mode_changed`. Glyph widgets are planned |
| Text scaling | `SettingsService.text_scale` 1.0 / 2.0 → `UiTheme.apply_text_scale` resizes the project Theme |
| Safe area at 200 % text | all controls stay inside the 640×360 logical rect (SYS-001 §9); tested for attract and settings |
| Resolution / aspect | `viewport` stretch, `keep` aspect, integer scale (TECH-001 §1.2–§1.3). Layouts use anchors/containers only |
| Touch-safe targets | Windows-only, mouse targets ≥ ~22 logical px tall (✱ content margins). No touch support planned |
| Steady Ledger / Esc always pauses | the `pause` action opens the real pause screen whenever the overlay stack is empty (WARP-001 §4.4) |
| Accessibility rows never lie or hide | settings read live from `SettingsService` (WARP-001 §4.7) |
| Photosensitivity | stored; no flicker exists yet to suppress. Must never hide information (GDD §10) |

## 5. Control states

| State | Look (Theme `data/ui/darkstar_theme.tres`) | Status |
|---|---|---|
| idle | VOID-1 fill, 1 px BONE-1 keyline, BONE-5 text ("chalk on slate", ART-001 §7) | built |
| hover | VOID-2 fill, BONE-3 keyline | built |
| focus | 2 px GAS-3 outline (✱, see §9) | built |
| pressed / selected | VOID-3 fill, BONE-5 keyline | built |
| disabled | VOID-0 fill, BONE-0 keyline, BONE-1 text | built |
| busy / loading | disabled look while routing; the curtain covers the change | built |
| error | `ErrorLabel` variation, SIGNAL text (✱, see §9) | theme only |
| cooldown | planned with Surgelight (radial fill over the button/HUD glyph) | planned |

Theme variations: `HeaderLabel`, `HintLabel`, `ErrorLabel`, `DimPanel`. Every colour is a palette entry (tested by `core/ui/tests/test_theme_palette.gd`). Not yet done: the ±1 px chalk wobble (ART-001 §7), the Act 0 cabinet-bezel costume layer, and the bitmap font (ART-001 has no font section; TECH-001 §11 Q-T02).

## 6. Player-readable output
Everything on screen comes from a `tr()` key in `locale/en.po` (L10N-001). Failure codes go through `PlayerMessages`, which maps them to a sentence saying what happened, whether progress is safe, and what to do next. Raw codes, paths, enum names and exceptions go to `push_warning`/`push_error` only. Authored HUD lies (WARP-001 §4.2) are content, not bugs. A raw key, debug value or error string on screen is a bug.

## 7. Tests
`scenes/tests/test_attract_mode.gd` and `scenes/tests/test_sector_and_pause.gd` cover focus on open, focus loops, modal stacking up to three deep, focus restoration, `ui_cancel` and the `pause` action, repeated input, safe area at 200 % text, RTL layout, pseudolocalized fit, and no raw keys on screen. `tests/test_boot_flow.gd` covers input-mode switching. Window-size variation and per-locale screenshots are **not** automated yet.

## 8. Adding a screen
1. Create `scenes/<area>/<name>_screen.tscn` with a `Control` root using a script that `extends Screen`. Wrap the rows in `FitScrollContainer`.
2. Set `default_focus` and the focus neighbours of every control.
3. Use Theme variations only; no inline colours outside the palette.
4. Put every string in `locale/en.po` with a translator note.
5. Open it with `stack.push(scene.instantiate())` from the owning scene.
6. Add a test: focus on open, `ui_cancel`, safe area at 200 % text.

## 9. Open questions
* Focus colour: ART-001 reserves GASLIGHT for the player; the UI focus outline uses GAS-3 (TECH-001 §11 Q-T09).
* Error colour: SIGNAL is "danger tell only" in ART-001 §4; `ErrorLabel` uses it pending an art ruling.
* Font: none specified (Q-T02). Font sizes 14/28 are ✱.
