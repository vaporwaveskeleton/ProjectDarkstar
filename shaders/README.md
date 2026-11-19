# shaders

Index (TECH-001 §5.1 WarpComposer, §5.5 rendering ladder):

- `crt.gdshader`, `crt_attract.gdshader`, `crt_common.gdshaderinc`: the Act 0 CRT and register-quantize pass (TECH-001 §2.10). Owner: Visual Design.
- `aether_fog.gdshader`: the **cabinet reveal fog** used by THE PRETENCE (`Look.t` morph). Owner: Visual Design. Not an Aether layer.
- `aether/*`: the Aether layers of `features/aether` (fog band, crystal sphere, light shafts, leviathan, entity presence, life, sky cracks, grade, HDR present). Design and rules: ART-001 §16.6; layer stack and cost: TECH-001 §2.9, §8.
