class_name ChargeMagazine
extends Node
## Null-Iron Charge pips (GDD §8.3, SYS-001 §1.4): one collected shard = one Charge, up to the cap.
## Sector-side holder until RunSession owns run state (TECH-001 §4.2). ChargeLauncher spends from it.

@export var stats: ChargeMagazineStats

var count: int = 0


func capacity() -> int:
	return stats.capacity if stats else 0


func is_full() -> bool:
	return count >= capacity()


## Adds up to `n` Charges; returns how many fit. Cues: charge_armed per gain, magazine_full when the
## gain fills the magazine.
func try_add(n: int = 1) -> int:
	var added := clampi(n, 0, maxi(0, capacity() - count))
	if added <= 0:
		return 0
	count += added
	AudioService.play(&"charge_armed")
	if is_full():
		AudioService.play(&"magazine_full")
	return added


## Spends `n` Charges. False (nothing spent) when fewer than `n` are loaded. No cue here: the
## launcher plays charge_fire or dry_fire.
func try_spend(n: int = 1) -> bool:
	if n <= 0 or count < n:
		return false
	count -= n
	return true


func reset() -> void:
	count = 0
