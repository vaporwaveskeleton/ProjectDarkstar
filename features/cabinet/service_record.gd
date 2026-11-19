class_name ServiceRecord
extends RefCounted
## Act 0 service record (S7): honest, run-wide counts of what the player did, in memory only.
## Created once by CabinetGame (same lifetime as ScoreKeeper, so it spans stage 1 and 2) and
## handed to ArcadeWorld. Never saved, never a lie (Steady Ledger-safe).

var grubs_destroyed: int = 0    ## Grubs the player killed (not ones the entity ate)
var glass_mined: int = 0        ## Mourning Glass shards freed by the player's mining
var charges_thrown: int = 0     ## Null-Iron Charges launched
var glass_carried: int = 0      ## shards the Choir delivered to the Sepulchre


func reset() -> void:
	grubs_destroyed = 0
	glass_mined = 0
	charges_thrown = 0
	glass_carried = 0
