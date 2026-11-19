class_name ProcessionSandbox
extends Node
## Places the M1 sector sandbox's Sepulchre and starts its Grub procession (no kit assembly yet;
## SeamAssembler replaces this later). Deterministic: positions come from ProcessionSandboxStats,
## no RNG. The Sepulchre goes under the sector's %Actors, so SectorWrap keeps it (and the Grubs)
## on the image nearest the Vigil, the one re-imaging mechanism for actors.

const SEPULCHRE_SCENE := preload("res://features/sepulchre/sepulchre.tscn")
const COMPASS_KIND := &"sepulchre"
## Compass order: the Sepulchre right after the Vigil (the cap of 8 still applies).
const COMPASS_RANK := 0

@export var stats: ProcessionSandboxStats
@export var sepulchre_stats: SepulchreStats
@export var grubs: GrubProcession

var sepulchre: Sepulchre


## Spawns the Sepulchre into `actors` and starts the procession. `lantern` is the Vigil.
func populate(torus: Torus, actors: Node, lantern: Node2D) -> void:
	if is_instance_valid(sepulchre):
		sepulchre.queue_free()
	sepulchre = SEPULCHRE_SCENE.instantiate() as Sepulchre
	sepulchre.configure(sepulchre_stats, torus, stats.sepulchre_pos)
	actors.add_child(sepulchre)
	LedgerCompass.register(sepulchre, COMPASS_KIND, COMPASS_RANK)
	if grubs != null:
		grubs.begin(torus, actors, lantern, sepulchre, route_on(torus), stats.grub_count, stats.grub_spawn_ring_px)


## The route's waypoints wrapped into the torus.
func route_on(torus: Torus) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in stats.route:
		out.append(torus.wrap(p))
	return out
