# shaders

Index (TECH-001 §5.1 WarpComposer, §5.5 rendering ladder):

- `crt.gdshader`, `crt_common.gdshaderinc`: the Act 0 CRT and register-quantize pass (TECH-001 §2.10), used by the game and by attract alike (the attract-only `crt_attract.gdshader` is retired, Q-T80). Owner: Visual Design.
- `aether_fog.gdshader`: the **cabinet reveal fog** used by THE PRETENCE (`Look.t` morph). Owner: Visual Design. Not an Aether layer.
- `menu_glass.gdshader`: the Aether overlay menus fogged-glass face (`MenuFrame`, BRASS costume; TECH-001 §2.9b, UI-001 §10). Pal colours as uniforms; the drift clock stops under Reduced Motion or Photosensitivity. Owner: Visual Design.
- `aether/*`: the Aether layers of `features/aether` (fog band, crystal sphere, light shafts, leviathan, entity presence, life, sky cracks, grade, HDR present). Design and rules: ART-001 §16.6; layer stack and cost: TECH-001 §2.9, §8.
- `cabinet/*`: the Act 0 bezel's physical parts (ART-001 §12.7a, TECH-001 §2.10); all values come from `CabinetSurface`. Owner: Visual Design.
  - `cabinet_material.gdshaderinc`: shared noise, shape SDFs, the one cabinet light and wear helpers.
  - `coin_door.gdshader`: the coin door (SDF shapes, height-field lighting, causal wear, lit price plate).
  - `bezel_print.gdshader`: reverse-printed ink under glass (fade, mottle, halftone, scuffs, flakes) for the field, columns and sticker text.
  - `bezel_glass.gdshader`: sheen, dust, fingerprints and scratches over the printed bezel.
  - `arcade_button.gdshader`: the control panel's pushbuttons (translucent cap, lamp, chrome ring, focus halo; Q-T34).
  - Pass 2c (2026-11-19): `control_panel.gdshader` (the angled laminate panel slab: lip, front shadow, contact shadows, grain, palm polish), `panel_decal.gdshader` (printed decals with wear, never dimmed by a disabled button), `power_rocker.gdshader` (the POWER rocker switch on the right cabinet side), `hazard_tape.gdshader` (the coin door's printed-vinyl hazard tape and its adhesive side). `bezel_glass.gdshader` now carries the thumb smear beside the left screen edge, gated by the screen light. `crt.gdshader` gained the `collapse` and `collapse_fade` uniforms (the power-off line and dot; a plain fade when `collapse_fade` is 1).
  - `bezel_vent.gdshader`: perforated black-metal speaker grilles.
  - `bezel_sticker.gdshader`: the worn vinyl NEW! sticker with a lifted corner.
  - `contact_shadow.gdshader`: the soft shadow and occlusion under a raised part.
  - Pass 2 (2026-11-19; the global uniform `cab_screen_light` is declared in `cabinet_material.gdshaderinc` and registered in `project.godot` `[shader_globals]`):
    - `bezel_frame.gdshader`: the printed border round the rounded screen opening.
    - `screen_tube.gdshader`: the overlay after the screen: rounded tube mask and a very faint, alpha-clamped glass layer (never alters the CRT or register quantize).
    - `bezel_marquee.gdshader`: the backlit marquee sign (uneven backlight, dead tube band, dust).
    - `cabinet_trim.gdshader`: the T-molding.
    - `bezel_bolt.gdshader`: the zinc bolts.
    - `cabinet_room.gdshader`: the cabinet's side panel just beyond the printed sheet (transparent past it).
    - `arcade_backdrop.gdshader`: the defocused 80s arcade floor behind the cabinet (`ArcadeBackdrop`): soft cabinet silhouettes, neon and tungsten bokeh, carpet, haze, film grain; procedural, no textures.
