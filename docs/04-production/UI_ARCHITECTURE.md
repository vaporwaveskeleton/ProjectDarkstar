# DARKSTAR — UI Architecture (menus, overlays, buttons)

**Doc ID:** UI-001 · **Version:** 1.2 · **Date:** 2026-11-19 · **Owner:** production
**Upstream:** GDD §10 (menus, accessibility), ART-001 §4 (palette) and §7 (UI art), WARP-001 §4 (HUD lie law, Steady Ledger), AUDIO-001 §6.2 (I06–I08 UI cues), SYS-001 §9 (safe area at 200 % text)
**Not here:** HUD lie content (WARP-001 §4), diegetic HUD implementation (TECH-001 §5, `DiegeticHud` row), player-text keys and English copy rules (L10N-001)

## 1. Screen inventory

| Screen | Required by | Status |
|---|---|---|
| Attract mode (title): the cabinet marquee (DARKSTAR in the Cabinet face), INSERT CREDIT (PRESS NEW VIGIL once credited), high score, drifting vector field, CRT glass; first attract of a launch opens with the power-on self-test (any input skips); four instruction cards cycle (pitch, how to play, mission, score table); a hazard-taped coin door on the right bezel (peel the tape, insert a coin); the menu is a physical control panel on the bezel (NEW VIGIL start button, a small SERVICE button that opens settings, and a POWER rocker under the coin door; one focus domain START → SERVICE → POWER → coin door; focus or mouse hover shows a plain caption, "Settings" or "Quit game"; POWER asks through `ConfirmScreen` first, and only the confirmed answer plays the CRT power-off and quits; `ui_cancel` and default focus unchanged; TECH-001 §2.10, Q-T34, pass 2c); New Vigil is dark and outside the focus loop until a credit is in, then spends it; 30 s idle (not while a credit waits or a peel is in progress) plays the autopilot demo, any input returns | GDD §10, WARP-001 W0-01/W0-03 | built — `scenes/attract/` |
| Settings: tabs Accessibility (large text, reduced motion, photosensitivity, Steady Ledger), Video (weapon muzzle flash), Controls (read-only bindings reference); a description line; cabinet or brass costume (§10). No language setting: English only, L10N-001 §1 | GDD §10, WARP-001 §4.4 | built (subset) — `scenes/settings/` |
| Pause: Resume, Settings, Abandon Run (Ruins: Leave for the Title); art panel; costume (§10) | GDD §4.1, WARP-001 §4.4 W4-07 | built — `scenes/sector/pause_screen.tscn` |
| Confirmation (two-choice, safe default); caution plate; costume (§10) | brief | built — `scenes/common/confirm_screen.tscn` |
| Loading / transition curtain | brief | built (fade) — `scenes/boot/boot.tscn` |
| Act 0 cabinet HUD: printed bezel around the 256×304 portrait screen, 1UP/score, Vigils (readouts on the screen's HUD strip, 40 px, 48 px proposed Q-T367, TECH-001 §2.10), glass-lamp Charge pips, Ledger Compass mini-map; READY card, the stage card (§11), banners, captions, credits, the entity's big type | WARP-001 W0-01/W0-02/W0-04, ART-001 §11.5 | built — `features/cabinet/` (TECH-001 §2.10) |
| HUD (diegetic, may lie) | WARP-001 §4 | Act 1+: stub (one honest hull label) |
| Rebinding, mouse sensitivity, aim assist, colourblind variants, subtitles, the rest of the AUDIO-001 §8.4 options (captions, chant indicator, mono, headphone field; Settings shows bindings read-only on its Controls page and has an Audio tab with the six volume sliders, TECH-001 Q-T270 closed, Q-T393 open) | GDD §10, AUDIO-001 §8.4 | planned |
| Death / cause-of-death screen | GDD §6.3, §8.9; AUDIO-001 §4.10 | planned |
| Ruins first arrival (title, the lit sapling, continue) | GDD §6.4 | stub — `scenes/ruins/` |
| Ruins hub, Lantern Tree, Chalk Desk, Codex, run summary | GDD §6.4, LOOP-001 §3, §7 | Lantern Tree station built (2026-11-19 overnight, TECH-001 Q-T326): `features/lantern_tree/lantern_tree_screen.tscn` + `lantern_tree_confirm.tscn` on the Ruins `ScreenStack`, from the second visit (the first visit has no menu, LOOP-001 §10.5); lamps are focusable `TreeLantern`s (wrapping neighbours, `%Lamp_<BRANCH>_<n>`), captions are `VectorLabel`, the confirm defaults to "Not yet"; the rest planned |
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

`FitScrollContainer` (`core/ui/fit_scroll_container.gd`) wraps every overlay's rows. It is as tall as its content until the content would leave the safe area, then it scrolls and follows focus. The panel title is not a row: it sits above the scroller in a `VBoxContainer` (`Panel/Layout/Title`, `Panel/Layout/Scroll/Rows`), and the scroller subtracts its VBox siblings' height from its limit, so 200 % text scrolls the rows and never the title (2026-11-19, TECH-001 Q-T244). Fixed controls outside its own VBox (the Settings title above the tab rail) are listed in `also_reserve` and kept on screen the same way (§10).

## 4. Interaction rules

| Rule | How it is met |
|---|---|
| One clear primary action | `default_focus`; attract → the coin door until a credit is in, then New Vigil (control-panel pushbuttons, TECH-001 §2.10) |
| Explicit focus neighbours, no dead ends | every button sets `focus_neighbor_top/bottom` (wrapping); Settings also sets left/right between its tab rail and the page (§10); tested |
| Reliable `ui_cancel` | `Screen._unhandled_input`; root screens ignore it; tested |
| Repeated input | busy state: New Vigil disables the menu; `SceneRouter.go_to` ignores calls while busy; Confirm disables itself on press |
| Transitions | 150–300 ms (`Boot.TRANSITION_S = 0.2` ✱). Instant when `reduced_motion` is on |
| Immediate feedback | Theme hover/pressed/focus styles. Audio cues I06 (confirm/back) and I07 (hover) from AUDIO-001 §6.2 are **not wired yet** |
| Input-method changes | `InputModeTracker` emits `input_mode_changed`. Glyph widgets are planned |
| Text scaling | `SettingsService.text_scale` 1.0 / 2.0 → `UiTheme.apply_text_scale` resizes the project Theme; the overlay menus' stroke text (`MenuText`) doubles live on the same setting (§10) |
| Safe area at 200 % text | all controls stay inside the 640×360 logical rect (SYS-001 §9; stays valid in logical units after Act 0); tested for attract, every Settings page, Pause and Confirm, in both costumes (§10) |
| Resolution / aspect | Root is `canvas_items` stretch, `expand` aspect, `fractional` scale (built, PR A, 2026-11-18): the whole app renders at native resolution, 640×360 is the logical space, and the bezel fills the window with no bars. Integer scaling binds only the Act 0 arcade screen (`ScreenFit`, TECH-001 §1.2–§1.3; screen grid 256×304, §1.1). Pause/settings overlays cover the whole cabinet at native res (root `Overlays`, §2.10). Post-Act 0 UI text is `VectorLabel` (TECH-001 §2.9a). Layouts use anchors/containers only. Post-Act 0 UI is modern game-UI structure and UX (hierarchy, primary vs secondary actions, focus, input glyphs, list/preview/detail) with chalk-and-brass as the skin (D-C) |
| Touch-safe targets | Windows-only, mouse targets ≥ ~22 logical px tall (✱ content margins). No touch support planned |
| Steady Ledger / Esc always pauses | the `pause` action opens the real pause screen whenever the overlay stack is empty (WARP-001 §4.4) |
| Accessibility rows never lie or hide | settings read live from `SettingsService` (WARP-001 §4.7) |
| Photosensitivity | stored; read live. Today it turns off the Cabinet's muzzle star (S4, TECH-001 §2.10); the separate `muzzle_flash` setting (default on) also turns that star off (AUDIO-001 §8.3 ruling). Must never hide information (GDD §10) |

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

Theme variations: `HeaderLabel`, `HintLabel`, `ErrorLabel`, `TruthLabel`, `DimPanel`. Every colour is a palette entry (tested by `core/ui/tests/test_theme_palette.gd`). Settings, Pause and Confirm no longer use these Theme styles: they draw their own states in the cabinet or brass costume with the same role laws (focus GAS, §10). Not yet done: the ±1 px chalk wobble (ART-001 §7) and the bitmap font (ART-001 has no font section; TECH-001 §11 Q-T02).

## 6. Player-readable output
Everything on screen comes from a `tr()` key in `locale/en.po` (L10N-001). Failure codes go through `PlayerMessages`, which maps them to a sentence saying what happened, whether progress is safe, and what to do next. Raw codes, paths, enum names and exceptions go to `push_warning`/`push_error` only. Authored HUD lies (WARP-001 §4.2) are content, not bugs. A raw key, debug value or error string on screen is a bug.

## 7. Tests
`scenes/tests/test_attract_mode.gd`, `scenes/tests/test_attract_coin_slot.gd` (tape peel by hold/drag/pad A, coin → credit → New Vigil, power-on skip, page cycle, binding labels) `scenes/tests/test_sector_and_pause.gd` and `scenes/tests/test_menu_layout.gd` (§10) cover focus on open, focus loops, modal stacking up to three deep, focus restoration, `ui_cancel` and the `pause` action, repeated input, safe area at 200 % text, and no raw keys on screen. `tests/test_boot_flow.gd` covers input-mode switching. Window-size variation is **not** automated yet. Automation scenarios (TECH-001 §9.1) find controls by id: every focusable Control on a Screen needs a scene-unique `%Name`, and that name is its automation id `<route>/ui/<Name>`.

## 8. Adding a screen
1. Create `scenes/<area>/<name>_screen.tscn` with a `Control` root using a script that `extends Screen`. Wrap the rows in `FitScrollContainer`.
2. Set `default_focus` and the focus neighbours of every control. Give every focusable Control a scene-unique `%Name`; it is its automation id `<route>/ui/<Name>` (TECH-001 §9.1).
3. Use Theme variations only; no inline colours outside the palette. An overlay menu (a panel over play) uses the menu kit instead: `MenuFrame` panel, `MenuText`, `MenuRow`, `MenuRule`, `MenuOrnament`, so it wears the scene's costume (§10).
4. Put every string in `locale/en.po` with a context note.
5. Open it with `stack.push(scene.instantiate())` from the owning scene.
6. Add a test: focus on open, `ui_cancel`, safe area at 200 % text.

## 9. Open questions
* None open. Focus, error and font questions were ruled 2026-11-17 (TECH-001 §11.1a R-02, R-09); the full spec is ART-001 §11 (typography) and §12 (UI states). Until the bitmap faces are drawn, the code uses Godot's fallback font at ✱ 14/28 px; when Ledger lands, `UiTheme.BASE_FONT_SIZE` becomes the Ledger cell height and text scale stays an exact ×2.

## 10. Overlay menus: layout and costumes (2026-11-19)
Owner direction 2026-11-19 ("too narrow, not enough artwork"); built by the PM under that direction (TECH-001 §2.9b, §11.2). Settings, Pause and Confirm share one menu kit in `core/ui/` and draw their own art. They no longer use the Theme's slate panel or the fallback font.

**Layout.**
* **Settings** is a wide panel: about 470 logical px at 100 % text, up to the full 640 at 200 %.
  * Header: the title, plus `Service Mode` on the cabinet, then a heavy rule.
  * Body: a **tab rail** on the left (Accessibility, Video, Audio, Controls, an art panel, then Back) and the **active page** on the right. Under the page, one line describes the focused row (`*_DESC` keys).
  * *Accessibility* page: Large Text, Reduced Motion, Photosensitivity Mode, Steady Ledger.
  * *Video* page: Weapon Muzzle Flash.
  * *Controls* page: a read-only table (action, keyboard, gamepad). It reads the live `InputMap` through `InputLabels`, so it always shows the real bindings. At 200 % text each row stacks the label, the keyboard binding and the gamepad binding on three lines, so the table never leaves the frame.
  * *Audio* page (2026-11-19, TECH-001 Q-T390): six volume sliders in AUDIO-001 §8.4 order and words, Master, Music, Choir, Entity voice, UI and readouts, Foley and ambience. Each row is a bar plus its number (never the bar alone). Left and right step it by 5, a click or drag on the bar sets it, `ui_cancel` on a slider returns to the Audio tab (a second one closes), 0 mutes the bus, and Entity voice and Foley and ambience stop at 40 (the bar shows a tick at the floor). Changes apply live and play a short preview cue after 0.18 s. At 200 % text the bar drops under the label. Music and Entity voice have no preview cue. The saved keys are the `vol_*` rows in TECH-001 §7.3.
  * The rows read and write `SettingsService`. The Audio page adds six keys (`vol_*`); no other setting, key, default or saved value changed.
* **Pause:** an art panel on the left; Resume, Settings and Abandon Run on the right (in the Ruins, Leave for the Title).
* **Confirm:** the title, a heavy rule, a caution plate beside the body text, then Cancel (default focus) and Confirm.

**Focus (§4).**
* The Settings rail is a wrapping ring. Each page is its own wrapping ring.
* Focusing a tab shows its page. `ui_accept` on a tab, or right from anywhere on the rail, moves to the page's first row. Left from a row returns to its tab, except on the Audio page, where left and right belong to the slider and `ui_cancel` returns to the tab.
* Default focus is the Accessibility tab. `ui_cancel` closes, as on every overlay.
* The Controls table header is not a focus stop. Its rows are, so a pad can scroll the table.

**Costumes (`MenuSkin`).** Each scene's `ScreenStack.costume` picks the costume. `Auto` follows the fidelity ladder (`Look.t`); the sector and the Ruins name `Brass`.
* **Cabinet (Act 0)** is the cabinet's operator service mode, a period test-mode screen:
  * neon on black through `Look.c`, and upper-case stroke text;
  * a tube-shaped frame with registration marks, a faint convergence crosshatch and static scan lines;
  * a 16-bar colour strip as the header rule, dashed rules between rows, and a block cursor on the focused row;
  * an art panel showing the bezel's world in line art: a ringed planet, stars and the Vigil dart.
* **Brass (Aether)** uses the sector HUD's instrument plates (`Brass`, ART-001 §16.6h):
  * a riveted, bevelled case around a smoked-glass face, with engraved double rules and corner filigree;
  * glass lamps for toggles;
  * an art panel showing an orrery of crystal spheres in a graduated brass ring.
* **Role laws in both:**
  * Focus is GAS (R-09).
  * ON is phosphor (an honest state) and is always printed as `On` or `Off` too, never shown by colour alone.
  * SIGNAL is never used.

**Restyle (2026-11-20, Fable art-direction review; TECH-001 §2.9b).**
* Cabinet: every menu word is the cabinet's 5 × 7 pixel font at an integer scale, snapped to the logical pixel grid, with CRT scanlines. The colour bar is the cabinet's 16 colour registers in register order.
* Brass: a fogged-glass face (slow drift at low contrast, a vignette), an engraved hairline inside the brass, slightly irregular rivets and an engraved-capital title. Body text stays plain.
* Both: a **preview window** in the lower right shows the focused setting live (text size sample, the motion dart, a dimmed flash sample, the muzzle flash, a lying HUD digit beside the honest Steady Ledger digit, a level meter for each volume slider). It hides at 200 % text. OFF is brighter and the lamps are twice the size.
* The menu is still an overlay over the cabinet in Act 0 (an in-tube service screen is TECH-001 Q-T271).

**Readability.**
* All menu text is `VectorLabel` stroke text (`MenuText`), sized by role. Large Text doubles it live.
* At 200 % the art panels give their room to the text, and the rows scroll inside `FitScrollContainer`. The title and tab rail stay fixed (`also_reserve`).
* The cabinet cursor blinks, the brass fog drifts and the Reduced Motion preview dart moves. Under Reduced Motion or Photosensitivity all three hold still. Nothing else in the menus moves.
* The focused row always scrolls fully into view, including after the description line changes the panel height.

**Tests:** `scenes/tests/test_menu_layout.gd` covers:
* the rail and page rings, and real `ui_*` input;
* the description line, On/Off, and the costume's letter case;
* no raw keys and no missing glyphs;
* the controls table;
* the safe area at 200 %, inside a 640×360 viewport, for every page and menu in both costumes;
* visible art at 100 %;
* the costume choice per stack, and the still cursor.

`scenes/tests/test_settings_audio.gd` covers the Audio page: the tab order, the six rows in both costumes, the closed focus ring, left/right stepping with real input, the Entity floor, mute at 0, Back on a slider, the preview, and the translations. `core/audio/tests/test_user_volume.gd` covers the curve, the persistence round trip and the bus effect.

## 11. The Act 0 stage card (owner direction 2026-11-19; PM under owner direction, 2026-11-19 overnight push, TECH-001 Q-T371–Q-T374; PROPOSED)

Owner: "At the beginning of each arcade stage the game should pause and give a reminder along the lines of 'Unmake the presence' with a short reminder of mechanics along with a list of enemies in the stage and a Press Fire To Continue prompt."

**What it is.** The card is part of the Cabinet costume. It is drawn on the arcade screen by `CabinetMessages` with `PixelText` in the 16 colour registers. It is **not** a `Screen` and is not pushed on the `ScreenStack`, because it lives inside the 256 × 304 SubViewport (TECH-001 §2.10). It opens at the start of every stage, including after CONTINUE, and the world does not tick while it is up (Hourglass and score untouched).

**Layout, top to bottom, inside the 256 × 256 play view:**
1. Zone line (`CAB_ZONE_*`, small) and stage title (`CAB_STAGE_A0_n`, 2×).
2. **The order:** `CAB_BRIEF_ORDER_WAKE` "UNMAKE THE SEPULCHRE" on the waking stages, `CAB_BRIEF_ORDER_COLD` "BREAK THE SEPULCHRE" on the cold ones. It uses the phosphor (truth) register.
3. **Two reminders:** `CAB_BRIEF_A0_n_1`, `_2`, each at most 30 characters.
4. **In this stage:** `CAB_BRIEF_ROSTER`, then one row per unit present: icon (the unit's own drawing at 1×), name (`CAB_UNIT_*`) and count from the stage data. Rows: geodes, Grubs, Acolytes (start + guard), Sepulchre. Never a unit the stage does not have.
5. **Progress:** `CAB_BRIEF_UNMAKINGS` "UNMAKINGS {n} / {total}", shown from A0-3 on.
6. **The prompt:** `CAB_BRIEF_PRESS_FIRE` "PRESS FIRE TO CONTINUE", blinking at `ds_cabinet.brief.prompt_blink_hz` (steady under photosensitivity or reduced motion).

**Input (honours the input map, GDD §4.1/§4.3; `tests/test_input_map.gd` is unchanged).**

| Action | On the card |
|---|---|
| `fire_lance` (Arc-Lance) | A fresh press, after `ds_cabinet.brief.arm_s`, dismisses the card: a short READY, then play. It is the **only** dismiss |
| `pause` / `ui_cancel` | Opens the pause screen (the same overlay as in play, with ABANDON). On return the card is still up. `ui_cancel` never skips the card |
| anything else | ignored |

The card waits with no timeout (it is a pause). `--autopilot` and `--smoke` dismiss it after `ds_cabinet.brief.autopilot_s`. Focus: none needed (no controls on the card; the arcade screen owns input while it is up).
