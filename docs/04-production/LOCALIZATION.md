# DARKSTAR — Localization

**Doc ID:** L10N-001 · **Version:** 1.0 · **Date:** 2026-11-17 · **Owner:** production (system); writer (English source); translators (their `.po`)
**Upstream:** GDD §2 (locales), GDD §10 (text rules), GDD §19 (glossary), TECH-001 §1.4 (`localize_extract`)

## 1. Locales

| Locale | Status | Notes |
|---|---|---|
| `en` | **launch, source and fallback** | `locale/en.po` |
| `de`, `fr`, `es`, `pt_BR` | planned (1.0 or +1 month, GDD §2) | Latin script; the current fallback font covers them only if the chosen bitmap font does |
| `zh_CN`, `ja` | planned | blocked on a CJK bitmap font. ART-001 has no font section yet (TECH-001 §11 Q-T02) |
| RTL (ar, he…) | not planned | the architecture must not block it; one RTL layout test exists |

`SettingsService.SUPPORTED_LOCALES` is the runtime list. Add a locale there only after its `.po` passes §6.

## 2. Keys and files

* Every player-visible string is a **key** in `locale/<locale>.po`: `msgid` = key, `msgstr` = text.
* Key format: `UPPER_SNAKE`, prefixed by surface: `GAME_`, `MENU_`, `PAUSE_`, `CONFIRM_`, `SETTINGS_`, `LANGUAGE_NAME_`, `HUD_`, `MSG_`. A new prefix must be added to `KEY_PREFIXES` in `core/i18n/tests/test_localization.gd`.
* Plurals: `msgid "KEY"` + `msgid_plural "KEY_PLURAL"` + `msgstr[n]`, with the locale's `Plural-Forms` header. Call `LocFormat.tr_count("KEY", n)`, which fills `{count}` with a locale-formatted number.
* Placeholders use `{name}` and are replaced in code. Never concatenate translated fragments.
* `#.` comment lines above an entry are **translator notes**: what it is, where it shows, length limits, glossary terms. Every new key gets one when the meaning is not obvious.
* Glossary words (GDD §19: Vigil, Arc-Lance, Surgelight, Composure, Choir…) are fixed terms. Translators keep a per-locale term list; the name "DARKSTAR" is never translated.
* Scenes: put the key in `text` and leave auto-translate on. Labels that show runtime-built text set `auto_translate_mode = Disabled` and call `tr()` / `LocFormat` themselves.
* Language names are always shown in their own language (`LANGUAGE_NAME_EN` = "English").

## 3. Fallback and missing keys
* Project fallback locale: `en` (`internationalization/locale/fallback`).
* `SettingsService.resolve_locale`: an empty setting follows the OS language if supported; otherwise `en`. `en_GB` → `en`.
* A missing key in another locale falls back to English. A key missing from `en.po` fails the test suite, so it never ships.

## 4. Invariant data
Saves, telemetry keys (SYS-001 §8), route ids, `ds_` keys, enum values and seeds are language-independent ids. Never store `tr()` output. Save payloads and signals carry ids; the UI turns them into text at the last moment.

## 5. Formatting
Godot has no ICU. `core/i18n/loc_format.gd` holds the rules:
* `format_int` / `format_decimal`: group and decimal separators per language (group / decimal: `en` `,` `.` · `de` `.` `,` · `fr` narrow no-break space `,` · `es` `.` `,` · `pt` `.` `,` · `zh` `,` `.` · `ja` `,` `.`). Add a row with each new locale.
* Dates, times and currency are not shown anywhere yet. Add helpers here when they are. The game is single-purchase, with no in-game currency formatting beyond integers.
* Durations (the Hourglass Clock) are planned to use `m:ss` with locale digits.

## 6. Validation (runs with the normal test suite)
`core/i18n/tests/test_localization.gd`:
| Check | Fails when |
|---|---|
| missing keys | a key-shaped string literal in `scenes/`, `features/`, `core/`, `autoload/` is not in `en.po` |
| unused keys | an `en.po` key is referenced nowhere (dynamic `LANGUAGE_NAME_*` and `*_PLURAL` are allowed) |
| placeholders | an entry is empty or contains TODO/TBD |
| fallback | an unknown locale does not resolve to English |
| plurals | `tr_count` gives the wrong form or separator |
| number formats | `en`/`de`/`fr` grouping or decimals are wrong |
| pseudolocalization | expansion does not lengthen text |
| glyph coverage | the UI font lacks a character used in `en.po` |
`scenes/tests/test_attract_mode.gd` adds: pseudolocalized text stays on screen, RTL layout stays on screen, no raw key is ever shown.

Not automated yet: per-locale screenshots (there is only one locale), glyph coverage for locales other than English.

## 7. Workflow: adding or updating a language
1. Copy `locale/en.po` to `locale/<code>.po`, set `Language:` and the correct `Plural-Forms` header, and translate the `msgstr` lines (keep `msgid`).
2. Add the path to `internationalization/locale/translations` in `project.godot`.
3. Add `LANGUAGE_NAME_<CODE>` to **every** `.po` (each in its own language) and the code to `SettingsService.SUPPORTED_LOCALES`.
4. Add separator rows to `LocFormat`.
5. Run the test command (TECH-001 §9). Fix every failure.
6. Check the screens at 200 % text in the new locale (manual until screenshot tests exist).
7. For CJK: do not ship before the bitmap-font pass (Q-T02).

Updating English text: edit `msgstr` in `en.po` only. Changing the meaning of a string means a **new key**, so stale translations cannot carry the old meaning.

## 8. Commands
```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a core -a features -a scenes -a tests --ignoreHeadlessMode -c
```
Extraction to a `.pot` (`localize_extract`, TECH-001 §1.4) is planned. Until then `en.po` is the template.

## 9. Fonts, audio, subtitles, input
* Fonts: no game font is defined (Q-T02). The UI uses Godot's fallback font; glyph coverage is tested against whatever font the Theme sets.
* Warp text effects (WARP-001) must operate on the translated string, never on the key. Pseudolocale must pass under T0–T2 warp (planned with `WarpComposer`).
* Localized audio: entity lines are subtitled big type (GDD §10). Voice localization is not planned; subtitles cover it.
* IME: no text entry exists (seed codes are 12-character invariant codes, not translated). If a name field is ever added, it must accept IME input.
* Platform: Steam provides the OS language. Godot's `OS.get_locale_language()` is used on first launch only; the player's choice persists in `user://settings.cfg`.
