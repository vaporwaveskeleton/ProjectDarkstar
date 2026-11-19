class_name SeamReport
extends RefCounted
## What a sector hands back at Seam clear (TECH-001 §4.2a): the only write-back path from a sector
## into the run. Numbers only. Built by `SectorHost` from its live nodes (`report_into`).

## Composure at the Seam's end (0–10, SYS-001 §1.5).
var composure: float = -1.0
## Charges in the magazine at the Seam's end.
var charges: int = 0
## Ember earned in the Seam from score (SYS-001 §7.1); the Seam clear Ember (SYS-001 §7.2) is
## added by the core, not here.
var ember_earned: int = 0
