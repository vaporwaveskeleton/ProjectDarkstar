class_name CabinetStage
extends Resource
## One authored Act 0 level (GDD §6.1). Content, not tuning: which units, how the Sepulchre starts,
## and what ends the stage. Numbers inside stay within SYS-001 §4's Seam 1 T0 budget (8–12 pts:
## Grub = 1, Acolyte = 4).

enum Goal { CLEAR_SEPULCHRE, UNMAKE_ENTITY }

@export var id: StringName = &"a0_1"
@export var title_key: String = ""                  ## shown on the READY card
@export var subtitle_key: String = ""
@export var field_size: Vector2 = Vector2(1920, 720) ## ✱ torus field: 6 kit-screens (SYS-001 §6: 3–7 kits)
@export var geodes: int = 10                         ## ≥ 24 shards of supply (SYS-001 §4 lint)
@export var grubs: int = 4
@export var acolytes: int = 1
@export var guard_acolytes: int = 1                  ## join at the Guard phase
@export var sepulchre_start_segments: int = 0
@export var sepulchre_wakes: bool = true             ## false = Cold Sepulchre (W0-05)
@export var chant: bool = true                       ## A0-2 rule: the chant is heard under the music
@export var goal: Goal = Goal.UNMAKE_ENTITY
@export var seed: int = 1
@export var spine_stars: bool = false                ## S8: 20 faint stars trace the entity's spine (THE LAST NORMAL DAY only)
