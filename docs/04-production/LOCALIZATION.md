# DARKSTAR — Player Text (English) and Future Localization

**Doc ID:** L10N-001 · **Version:** 2.0 · **Date:** 2026-11-17 · **Owner:** production (system); writer (English text)
**Upstream:** GDD §2 (language scope), GDD §10 (text rules), GDD §19 (glossary)
**Rev 2.0 (2026-11-17, owner decision):** the game is **English only** for now. Every non-English plan, table, test and code path was removed. Localization is deferred, not designed; §7 says what to keep so it stays cheap to add later.

## 1. Language scope

| Language | Status |
|---|---|
| English (`en`) | **the only shipped language**: `locale/en.po` |
| Any other language | **deferred** (owner decision 2026-11-17). Not planned, not scheduled, not listed on the store page (MARKET-001 §3) |

There is no language setting in the game. `SettingsService` sets the locale to `en` at boot.

## 2. Why player text still goes through keys
English-only does not mean hard-coded text. Every player-visible string is a key in `locale/en.po`, because that is what lets us:
* enforce the player-readable output rules in one place (no raw codes, enum names or paths on screen — CLAUDE.md §3, UI-001 §6);
* test every screen's text for missing or unused strings automatically (§5);
* rewrite copy without touching scenes or code;
* add a language later without a code pass (§7).

## 3. Keys and the `en.po` file
* `msgid` = the key, `msgstr` = the English text.
* Key format: `UPPER_SNAKE`, prefixed by surface: `GAME_`, `MENU_`, `PAUSE_`, `CONFIRM_`, `SETTINGS_`, `HUD_`, `MSG_`; narrative surfaces (NARR-001 §7–§8): `NARR_EAT_`, `NARR_SABLE_`, `NARR_ILSE_`, `NARR_WICK_`, `NARR_KEEPER_`, `NARR_CAB_`, `NARR_OFFICE_`, `NARR_LUNE_`, `NARR_REPORT_`, `CX_` (Codex, ID = the `cx_` entry id upper-cased); achievements `ACH_` + the LOOP-001 §11.9 `ach_` id. Keys enter `en.po` when the code that shows them lands (the unused-key test forbids orphans). A new prefix must be added to `KEY_PREFIXES` in `core/i18n/tests/test_localization.gd`.
* Plurals: `msgid "KEY"` + `msgid_plural "KEY_PLURAL"` + `msgstr[0]`/`msgstr[1]`. Call `LocFormat.tr_count("KEY", n)`, which fills `{count}` with a formatted number.
* Placeholders use `{name}` and are replaced in code. Never concatenate fragments into a sentence.
* `#.` lines above an entry are **context notes**: where the text shows, length limits, glossary terms.
* Glossary words (GDD §19) are fixed terms. "DARKSTAR" is a name.
* Scenes: put the key in `text` and leave auto-translate on. Labels that show runtime-built text set `auto_translate_mode = Disabled` and call `tr()` / `LocFormat` themselves.
* Entity lines (big type, ART-001 §11 Litany face) must fit **560 px** wide at 1×.

## 4. Invariant data
Saves, telemetry keys (SYS-001 §8), route ids, `ds_` keys, enum values and seeds are ids, never text. Never store `tr()` output in a save or a signal payload.

## 5. Validation (runs with the normal test suite)
`core/i18n/tests/test_localization.gd`:

| Check | Fails when |
|---|---|
| missing keys | a key-shaped string literal in `scenes/`, `features/`, `core/`, `autoload/` is not in `en.po` |
| unused keys | an `en.po` key is referenced nowhere (`*_PLURAL` ids are allowed) |
| placeholders | an entry is empty or contains TODO/TBD |
| English fallback | the locale is not `en`, or an unknown locale does not show English text |
| plurals | `tr_count` gives the wrong form or separator |
| number format | English grouping or decimals are wrong |
| glyph coverage | the UI font lacks a character used in `en.po` |

`scenes/tests/test_attract_mode.gd` adds: no raw key is ever shown, and all text stays inside the screen at 200 % text size.

## 6. Formatting
`core/i18n/loc_format.gd`: English `format_int` (`1,234,567`) and `format_decimal` (`1,234.5`). Dates, times and currency are not shown anywhere yet. Durations (the Hourglass Clock) are planned as `m:ss`.

## 7. If languages are added later
Nothing here is scheduled. What keeps that door cheap, and must not be undone:
1. Every player string stays a key (§2–§3), with a context note when the meaning is not obvious.
2. No text is baked into textures except the art-owned faces' glyph sheets (ART-001 §11).
3. Saves and signals stay text-free (§4).
4. Changing the meaning of a string means a **new key**, never an edited one.

When a language is added, the work is: a new `.po`, a language setting in `SettingsService` and the settings screen, number-format rules in `LocFormat`, font coverage for that script (ART-001 §11), and new tests for text expansion and layout. Write that plan here at that time.

## 8. Commands
```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a core -a features -a scenes -a tests --ignoreHeadlessMode -c
```

## 9. Fonts, audio, subtitles
* Fonts: ART-001 §11 defines three bitmap faces (Ledger, Litany, Cabinet) with English coverage. Until they are drawn, the UI uses Godot's fallback font; glyph coverage is tested against whatever font the Theme sets.
* Warp text effects (WARP-001) operate on the displayed string, never on the key.
* Entity lines are spoken and shown as big-type subtitles (GDD §10).
