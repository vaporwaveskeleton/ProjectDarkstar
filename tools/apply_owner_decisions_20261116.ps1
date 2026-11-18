# Applies owner decisions of 2026-11-16 (Twin Vigil / Anchor / Salt Pouch) across
# SYS-001, GDD-001 and LOOP-001. Tokens stand in for non-ASCII characters so this
# file stays pure ASCII:  {S}=section  {EM}=em dash  {ST}=asterisk marker  {AR}=arrow  {AP}=apostrophe
# Idempotent: each step names a marker string; if that marker is already present the step is skipped.
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$tok = @{ '{S}'=[char]0x00A7; '{EM}'=[char]0x2014; '{ST}'=[char]0x2731; '{AR}'=[char]0x2192; '{AP}'=[char]0x0027 }

function Sub([string]$text) {
  $out = $text
  foreach ($k in $tok.Keys) { $out = $out.Replace($k, [string]$tok[$k]) }
  return $out
}

function Apply([string]$path, [string]$old, [string]$new, [string]$skipIf, [string]$tag) {
  $old = Sub $old; $new = Sub $new; if ($skipIf) { $skipIf = Sub $skipIf }
  $leaf = Split-Path $path -Leaf
  if ($skipIf -and $t0.Contains($skipIf)) { Write-Output ("skip " + $tag + "  (" + $leaf + ")"); return }
  $t = [System.IO.File]::ReadAllText($path, $enc)
  $n = ([regex]::Matches($t, [regex]::Escape($old))).Count
  if ($n -ne 1) { Write-Output ("FAIL x" + $n + " " + $tag + " (" + $leaf + ")"); return }
  [System.IO.File]::WriteAllText($path, $t.Replace($old, $new), $enc)
  Write-Output ("ok   " + $tag + "  (" + $leaf + ")")
}

$sysPath  = 'E:\GameDev\ProjectDarkstar\docs\01-design\SYSTEMS_BIBLE_STATS.md'
$gddPath  = 'E:\GameDev\ProjectDarkstar\docs\01-design\GDD_DARKSTAR_v0.2.md'
$loopPath = 'E:\GameDev\ProjectDarkstar\docs\01-design\ROGUELIKE_LOOP_AND_LANTERN_TREE.md'

# ---------- SYS-001: the Anchor field gets real rows ----------
$t0 = [System.IO.File]::ReadAllText($sysPath, $enc)
Apply $sysPath @'
| Surgelight Shroud burn | clears a 56 px sphere, 0.4 s | {ST} | Shroud HP equivalent, {S}9 |
'@ @'
| Surgelight Shroud burn | clears a 56 px sphere, 0.4 s | {ST} | Shroud HP equivalent, {S}9 |
| `anchor` ring radius (HULL-9 chain) | 190 px | 256 px (HULL-10, +35%); 436 px ceiling (HULL-13) | {ST} first-pass. The ring deliberately out-reaches the 340 px lantern ceiling once paid for. |
| `anchor_freeze` duration | 6.0 s | 8.0 s (HULL-16) | {ST} Choir units inside stop moving, chanting and firing; elites and Heralds freeze for half duration. It never damages: a stall, not a kill, per GDD-001 {S}8.7. |
| `anchor_rearm` | 20 s | 14 s (HULL-12) | {ST} the timer starts when the freeze lands, not when the field is raised. |
| `anchor` exclusions and cap | Sepulchre and The Penitent are never frozen; max 6 units per cast | {EM} | {ST} frozen units still count against {S}4 spawn budgets and the {S}9 contact budget. Stopping a deposit is WARD-6{AP}s job, not the ring{AP}s. |
'@ 'anchor_freeze' 'SYS anchor rows'

# ---------- GDD-001: source doc corrected, decisions locked ----------
$t0 = [System.IO.File]::ReadAllText($gddPath, $enc)
Apply $gddPath @'
*Twin Vigil* twin charges
'@ @'
*Twin Vigil* (a second charge-capacity upgrade may stack in one run; paired Charge fire is the Run Sigil *Twin Flint*)
'@ 'paired Charge fire is the Run Sigil' 'GDD twin vigil'
Apply $gddPath @'
| D-09 | Coop | **Out of scope for 1.0** |
'@ @'
| D-09 | Coop | **Out of scope for 1.0** |
| D-10 | *Twin Vigil* is the charge-capacity stacking chain, not paired fire; paired Charge fire lives in the Run Sigil *Twin Flint* | **Locked** (owner decision 2026-11-16) |
| D-11 | *Anchor* is a six-second freeze field with its own rows in the systems bible, not a sub-second pulse | **Locked** (owner decision 2026-11-16) |
| D-12 | Salt Glass stays as the WARD-2 Tree node and Pact placement; the *Salt Pouch* Run Sigil is cut | **Locked** (owner decision 2026-11-16) |
'@ '| D-10 |' 'GDD decision log'

# ---------- LOOP-001 ----------
$t0 = [System.IO.File]::ReadAllText($loopPath, $enc)
Apply $loopPath @'
**Twin Vigil** {EM} Charges fire in pairs
'@ @'
**Twin Vigil** {EM} a second charge-capacity upgrade may stack
'@ 'a second charge-capacity upgrade may stack' 'LOOP 3.2 ordnance cell'

Apply $loopPath @'
; a Salt Glass row entirely (SIG-W-03 hands the player a carried Salt Glass mine and SYS-001 has no such object)
'@ '' 'Salt Glass row entirely' 'LOOP gap footnote'

Apply $loopPath @'
Holding Space plants the skiff and emits a ring (proposed 190 px, row needed [^gap]) that freezes nearby Choir for 0.8 s on a 6 s cycle.
'@ @'
Holding Space plants the skiff and drops the Anchor field: SYS-001 {S}1.1 `anchor` rows, ring 190 px, freezing nearby Choir for 6.0 s on a 20 s rearm.
'@ 'Anchor field: SYS-001' 'LOOP HULL-9'

Apply $loopPath @'
The Anchor ring{AP}s freeze cycle 6 {AR} 4 s (`{ST}`, same row as HULL-9).
'@ @'
The Anchor field{AP}s rearm 20 {AR} 14 s (SYS-001 {S}1.1 `anchor` rows).
'@ 'rearm 20' 'LOOP HULL-12'

Apply $loopPath @'
The Anchor ring{AP}s freeze 0.8 {AR} 1.4 s, with the ring at its ceiling.
'@ @'
The Anchor field{AP}s freeze 6.0 {AR} 8.0 s, with the ring at its 436 px ceiling (SYS-001 {S}1.1 `anchor` rows).
'@ 'freeze 6.0' 'LOOP HULL-16'

Apply $loopPath @'
holding the brake key plants the skiff and emits a ring that freezes nearby Choir for 0.8 s on a 6 s cycle
'@ @'
holding the brake key plants the skiff and drops a six-second freeze field (SYS-001 {S}1.1 `anchor` rows)
'@ 'six-second freeze field' 'LOOP 3.4 anchor row'

Apply $loopPath @'
and the GDD{AP}s name stays on both nodes.
'@ @'
and the GDD{AP}s name stays on both nodes. Both disagreements are resolved by owner decision on 2026-11-16, recorded in GDD-001 {S}18 as D-10 and D-11: Twin Vigil is the capacity chain and paired Charge fire belongs to SIG-O-15 *Twin Flint*; Anchor is the six-second freeze field, and its numbers are now rows in SYS-001 {S}1.1.
'@ 'resolved by owner decision on 2026-11-16' 'LOOP conflict note'

Apply $loopPath @'
| SIG-W-03 | Salt Pouch | Common | You carry +1 Salt Glass mine (no SYS-001 row yet; this doc defines it, see [^gap]) | A pouch on the flank module | |
'@ @'
| SIG-W-03 | Penitent{AP}s Distance | Common | A Penitent in the sector will not raise its censer within 200 px of you unless you fire first (SYS-001 {S}3 `The Penitent`, {S}1.3) | The robed figure lowers its censer and walks a wider circle around your lamp | |
'@ "Penitent{AP}s Distance" 'LOOP SIG-W-03'

Write-Output '--- residue check (want 0) ---'
foreach ($f in $sysPath, $gddPath, $loopPath) {
  $hits = @(Select-String -Path $f -Pattern 'Salt Pouch', 'twin charges', '0\.8 s', 'freeze cycle 6', '\{S\}', '\{ST\}', '\{EM\}', '\{AR\}', '\{AP\}')
  Write-Output ((Split-Path $f -Leaf) + '  residue=' + $hits.Count + '  bytes=' + (Get-Item $f).Length)
}
