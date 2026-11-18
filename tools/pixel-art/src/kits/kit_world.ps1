<#  DARKSTAR kits: geode (planetoids / shrines), sepulchre (build altar + segment counter),
    shard (Mourning Glass ore + Null-Iron charges).                            #>

function Build-KitGeode {
  $items = @()
  $RAMP = @(7,8,9,10)   # BONE deep -> light
  # ---------- small geode, 3 damage states (mining feedback: outer modules visibly lost) ----------
  for ($f=1; $f -le 3; $f++) {
    $c = New-DS 64 64
    $r = 19; if ($f -eq 2) { $r = 15 }; if ($f -eq 3) { $r = 10 }
    $rock = New-DS 64 64
    DsBlob $rock 32 34 $r 8 7 0.34 ($f*1.1)
    DsShade $rock $RAMP -1 -1 4 1 1 10 0.7
    DsSpeckle $rock 7 0.16
    DsBlit $c $rock 0 0
    # fissure with the truth showing through (PHOS glass core)
    $cr = New-DS 64 64
    $n = 4 - $f
    for ($k=0; $k -lt $n; $k++) {
      DsShard $cr (19+$k*9) (30+($k%2)*7) (11-$f) (7-$f) 18 19 20 21 }
    DsBlit $c $cr 0 0
    if ($f -gt 1) { DsCrack $c 32 34 (6*$f) 1 }
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_geode_small__f{0:D2}" -f $f); c=$c; kit='geode'; part='small'; frames=3; note="damage state $f (1 = intact)" }
  }
  # exposed core when the shell is gone (over-fire detonation tell: cracks glow before it bursts)
  $core = New-DS 64 64
  DsBlob $core 32 32 11 19 6 0.22 0.4
  DsShadeRadial $core @(18,19,21,23) 32 32 11
  DsVeins $core 22 3 7 18 18 46 46 0.4
  DsSilhouetteOutline $core 0
  $items += @{ name='ds_geode_coreExposed'; c=$core; kit='geode'; part='coreExposed'; note='shell gone: PHOS core exposed' }
  # strata that looks like teeth (Warp Tier >=1 tell: ordinary rock becomes anatomy)
  $te = New-DS 64 64
  DsBlob $te 32 30 17 8 7 0.30 2.2
  DsShade $te $RAMP -1 -1 4 1 1 10 0.6
  for ($k=0; $k -lt 7; $k++) { $x=16+$k*5
    DsPoly $te @($x,34,($x+4),34,($x+2),44) 10 }
  for ($k=0; $k -lt 6; $k++) { $x=18+$k*5
    DsPoly $te @($x,20,($x+4),20,($x+2),11) 9 }
  DsLine $te 12 34 52 34 7 1
  DsSilhouetteOutline $te 0
  $items += @{ name='ds_geode_strataTeeth'; c=$te; kit='geode'; part='strataTeeth'; note='Warp>=1 variant: strata read as teeth' }
  # almost-a-face tell (never a literal skull: two hollows + a ridge, wrong plane)
  $sk = New-DS 64 64
  DsBlob $sk 32 34 18 8 8 0.26 4.0
  DsShade $sk $RAMP -1 -1 4 1 1 10 0.7
  DsDisc $sk 25 28 4 1; DsDisc $sk 41 31 3 1
  DsLine $sk 20 42 44 40 7 2
  DsSpeckle $sk 10 0.10
  DsSilhouetteOutline $sk 0
  $items += @{ name='ds_geode_faceWrong'; c=$sk; kit='geode'; part='faceWrong'; note='pareidolia tell: face on the wrong plane' }
  # coral / bone-growth overlay + shroud vein (world dressing)
  $co = New-DS 48 48
  for ($k=0; $k -lt 5; $k++) { $a=[Math]::PI*(0.15+0.17*$k)
    DsLimb $co 24 44 (24+[Math]::Cos($a)*18*($k%2+1)*0.8) (44-[Math]::Sin($a)*26) 4 1 9 2 8 }
  DsShade $co $RAMP -1 -1 4 1 1 10 0
  DsSilhouetteOutline $co 0
  $items += @{ name='ds_geode_coral'; c=$co; kit='geode'; part='coral'; note='bone coral dressing' }
  $sv = New-DS 64 64
  DsVeins $sv 19 5 16 2 2 61 61 0.7
  DsVeins $sv 21 2 9 12 12 51 51 0.5
  DsDither $sv 20 2
  $items += @{ name='ds_geode_shroudVein'; c=$sv; kit='geode'; part='shroudVein'; note='Shroud growth on rock (dithered)' }
  # ---------- medium (128) and large (192) geodes: assemblies of small modules ----------
  $m = New-DS 128 128
  foreach ($p in @(@(40,52,18),@(78,66,14),@(56,84,12),@(92,40,10))) {
    $rock = New-DS 128 128
    DsBlob $rock $p[0] $p[1] $p[2] 8 8 0.32 ($p[0]*0.2)
    DsShade $rock $RAMP -1 -1 4 1 1 10 0.6
    DsSpeckle $rock 7 0.14
    DsBlit $m $rock 0 0 }
  for ($k=0; $k -lt 7; $k++) { DsShard $m (44+$k*8) (60+($k%3)*12) (14-($k%3)*3) 7 18 19 20 22 }
  DsSilhouetteOutline $m 0
  $items += @{ name='ds_geode_medium'; c=$m; kit='geode'; part='medium'; note='2x2 module geode' }
  $L = New-DS 192 192
  foreach ($p in @(@(70,90,34),@(120,110,26),@(96,140,22),@(140,72,20),@(60,60,16),@(150,140,14))) {
    $rock = New-DS 192 192
    DsBlob $rock $p[0] $p[1] $p[2] 8 9 0.30 ($p[1]*0.15)
    DsShade $rock $RAMP -1 -1 4 1 1 10 0.6
    DsSpeckle $rock 7 0.13
    DsBlit $L $rock 0 0 }
  for ($k=0; $k -lt 14; $k++) { DsShard $L (66+($k%6)*14) (74+[int]($k/6)*18) (16-($k%4)*2) 8 18 19 20 22 }
  DsCrack $L 96 96 26 1
  DsSilhouetteOutline $L 0
  $items += @{ name='ds_geode_large'; c=$L; kit='geode'; part='large'; note='3x3 module geode (Seam boss arena set-piece)' }
  # ---------- monolith: an arch whose inner edge curves the wrong way ----------
  $mo = New-DS 64 128
  $slab = New-DS 64 128
  DsPoly $slab @(12,120,18,14,46,10,52,120) 8
  DsShade $slab $RAMP -1 -1 4 1 1 10 0.5
  DsBlit $mo $slab 0 0
  # the arch: concave on BOTH planes (impossible perspective), PHOS rim inside
  DsPoly $mo @(24,118,30,64,24,30,40,30,34,64,40,118) 1
  DsChalkArc $mo 32 64 16 ([Math]::PI*1.15) ([Math]::PI*1.85) 20 1 0.15
  DsChalkArc $mo 32 64 16 ([Math]::PI*0.15) ([Math]::PI*0.85) 19 1 0.2
  DsSpeckle $mo 7 0.14
  DsSilhouetteOutline $mo 0
  $items += @{ name='ds_geode_monolith'; c=$mo; kit='geode'; part='monolith'; note='non-Euclidean arch slab' }
  # ---------- Shrine (neutral) and its Hollow form (shape tell, no Choir colour) ----------
  foreach ($st in @(@{n='ds_geode_shrine'; hollow=$false}, @{n='ds_geode_shrineHollow'; hollow=$true})) {
    $s = New-DS 96 96
    for ($k=0; $k -lt 5; $k++) {
      $a = [Math]::PI*2*($k/5.0) - [Math]::PI/2
      $bx = 48 + [Math]::Cos($a)*30; $by = 52 + [Math]::Sin($a)*22
      $tilt = if ($st.hollow) { 8 } else { 0 }
      $sl = New-DS 96 96
      DsPoly $sl @(($bx-6),($by+16),($bx-4+$tilt),($by-16),($bx+4+$tilt),($by-16),($bx+6),($by+16)) 8
      DsShade $sl $RAMP -1 -1 4 1 1 10 0
      DsBlit $s $sl 0 0 }
    if ($st.hollow) {
      DsDisc $s 48 56 14 1; DsDither $s 2 2 30 38 66 74
      DsChalkCircle $s 48 56 20 7 1 0.55
      DsVeins $s 1 5 12 30 36 66 76 0.6 }
    else {
      DsDisc $s 48 56 9 19; DsDisc $s 48 56 5 21; DsDisc $s 48 56 2 23
      DsChalkCircle $s 48 56 22 10 1 0.25
      for ($k=0; $k -lt 7; $k++) { $a=[Math]::PI*2*($k/7.0)
        DsLine $s (48+[Math]::Cos($a)*24) (56+[Math]::Sin($a)*24) (48+[Math]::Cos($a)*28) (56+[Math]::Sin($a)*28) 10 1 } }
    DsSilhouetteOutline $s 0
    $items += @{ name=$st.n; c=$s; kit='geode'; part=$(if($st.hollow){'shrineHollow'}else{'shrine'}); note=$(if($st.hollow){'Consecrated: slabs bow inward, centre voided, chalk broken (shape tell, no Choir colour)'}else{'Ore conversion shrine: intact chalk ring, PHOS centre'}) }
  }
  return $items
}

function Build-KitSepulchre {
  $items = @()
  $RAMP = @(6,7,8,9)
  # single vertebra module (x20 = the build counter, Sinistar's 20 pieces made legible)
  foreach ($v in 1..4) {
    $t = New-DS 24 24
    DsBlob $t 12 12 7 8 6 0.22 ($v*1.7)
    DsRect $t 9 4 15 8 9 -Fill
    DsDisc $t 12 15 4 9
    DsShade $t $RAMP -1 -1 4 1 1 10 0
    DsLine $t 7 12 17 12 7 1
    DsSilhouetteOutline $t 0
    $items += @{ name=("ds_sepulchre_vertebra_{0:D2}" -f $v); c=$t; kit='sepulchre'; part='vertebra'; note='one Segment node (stack 20 = AWAKENING)' }
  }
  $d = New-DS 24 24
  DsBlob $d 12 12 7 6 6 0.22 2.3
  DsShade $d @(1,2,3,4) -1 -1 $null 1 1 $null 0
  DsCrack $d 12 12 9 2
  DsSilhouetteOutline $d 0
  $items += @{ name='ds_sepulchre_vertebraDark'; c=$d; kit='sepulchre'; part='vertebraDark'; note='a node removed by a Null-Iron hit (regrowth timer tell)' }
  # the cold hollow at the centre (4-frame inhale: the Sepulchre breathes in deposited shards)
  for ($f=1; $f -le 4; $f++) {
    $h = New-DS 48 48
    $rr = 12 + $f
    DsDisc $h 24 24 $rr 1
    DsDisc $h 24 24 ($rr-3) 2
    DsChalkArc $h 24 24 ($rr+4) 0 ([Math]::PI*2) 9 1 0.35
    if ($f -ge 3) { DsVeins $h 21 2 6 16 16 32 32 0.5 }
    $items += @{ name=("ds_sepulchre_hollow__f{0:D2}" -f $f); c=$h; kit='sepulchre'; part='hollow'; frames=4; note='inhale cycle (piety tag)' }
  }
  # chalk sigil plate (drawn by the Choir, redrawn by you: Ward Pulse counterplay)
  $sg = New-DS 64 64
  DsChalkCircle $sg 32 32 26 9 1 0.22
  DsChalkCircle $sg 32 32 19 10 1 0.30
  for ($k=0; $k -lt 7; $k++) { $a=[Math]::PI*2*($k/7.0)+0.3
    DsChalk $sg (32+[Math]::Cos($a)*20) (32+[Math]::Sin($a)*20) (32+[Math]::Cos($a)*27) (32+[Math]::Sin($a)*27) 9 0.1 0.5 }
  DsChalk $sg 12 40 52 36 10 0.28 0.8
  $items += @{ name='ds_sepulchre_sigil'; c=$sg; kit='sepulchre'; part='sigil'; note='7-tick chalk sigil (lore: seven ticks, one for each sky)' }
  # base altar + assembled progress states at 6 / 12 / 20 segments
  $base = New-DS 128 128
  $plinth = New-DS 128 128
  DsPoly $plinth @(24,116,104,116,96,92,32,92) 7
  DsRect $plinth 36 88 92 96 8 -Fill
  DsShade $plinth $RAMP -1 -1 4 1 1 10 0.4
  DsBlit $base $plinth 0 0
  DsSpeckle $base 6 0.12
  DsSilhouetteOutline $base 0
  $items += @{ name='ds_sepulchre_base'; c=$base; kit='sepulchre'; part='base'; note='fused-vertebra plinth' }
  $vertebrae = @(); foreach ($v in 1..4) { $vertebrae += (Get-DSItemGlobal $items ("ds_sepulchre_vertebra_{0:D2}" -f $v)) }
  foreach ($cnt in 6,12,20) {
    $a = New-DS 128 128
    DsBlit $a $base 0 0
    DsBlit $a (Get-DSItemGlobal $items 'ds_sepulchre_hollow__f02') 40 34
    $n = $cnt
    for ($k=0; $k -lt $n; $k++) {
      $ring = [int][Math]::Floor($k / 10); $idx = $k % 10
      $a2 = [Math]::PI*2*($idx/10.0) - [Math]::PI/2 + $ring*0.31
      $rr = 22 + $ring*13
      $x = 64 + [Math]::Cos($a2)*$rr - 12; $y = 70 + [Math]::Sin($a2)*$rr*0.86 - 12
      DsBlit $a $vertebrae[($k % 4)] ([int]$x) ([int]$y) }
    if ($cnt -ge 12) { DsVeins $a 21 3 10 40 40 88 96 0.6 }   # Quickening: it starts to glow
    DsSilhouetteOutline $a 0
    $tag = if ($cnt -eq 6) { 'partial' } elseif ($cnt -eq 12) { 'quickening' } else { 'awake' }
    $items += @{ name=("ds_sepulchre_ASSEMBLED_{0}" -f $tag); c=$a; kit='sepulchre'; part='ASSEMBLED'; note="$cnt of 20 Segments ($tag)" }
  }
  return $items
}

function Build-KitShard {
  $items = @()
  # Mourning Glass shards: 3 sizes (the ore you mine and the bombs you forge)
  foreach ($s in @(@{n='small';sz=16;h=12}, @{n='med';sz=24;h=18}, @{n='large';sz=32;h=26})) {
    $c = New-DS $s.sz $s.sz
    DsShard $c ($s.sz/2.0) ($s.sz/2.0) ($s.h) (($s.h)*0.62) 18 19 20 23
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_shard_{0}_01" -f $s.n); c=$c; kit='shard'; part=$s.n; note='Mourning Glass ore' }
    $c2 = Copy-DSCanvas $c
    DsCrack $c2 ($s.sz/2.0) ($s.sz/2.0) 5 21
    $items += @{ name=("ds_shard_{0}_02" -f $s.n); c=$c2; kit='shard'; part=$s.n; note='cracked variant (over-fire tell)' }
  }
  # glow frames for the ore (2-frame breathe rule applies: glass pulses, slowly)
  for ($f=1; $f -le 2; $f++) {
    $c = New-DS 32 32
    DsDisc $c 16 16 (5+$f) 19; DsDisc $c 16 16 (3+$f) 21; DsDisc $c 16 16 1 23
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_shard_glow__f{0:D2}" -f $f); c=$c; kit='shard'; part='glow'; frames=2; note='vein-glow cycle on deposited shards' }
  }
  # Null-Iron Charge: brass cage + glass core + wisp fuse (RMB payload)
  foreach ($f in 1,2) {
    $c = New-DS 32 32
    $cage = New-DS 32 32
    DsArc $cage 16 18 9 0 ([Math]::PI*2) 27 2
    DsLine $cage 7 18 25 18 26 1; DsLine $cage 16 9 16 27 26 1
    DsRect $cage 14 6 18 10 25 -Fill
    DsShade $cage @(24,25,26,27) -1 -1 $null 1 1 28 0
    DsBlit $c $cage 0 0
    DsDisc $c 16 18 (4+$f) 19; DsDisc $c 16 18 (2+$f) 21; DsDisc $c 16 18 1 23
    DsChalk $c 16 6 20 (2-$f) 28 0.25 0.7
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_shard_chargeIdle__f{0:D2}" -f $f); c=$c; kit='shard'; part='chargeIdle'; frames=2; note='Null-Iron Charge in the cradle' }
  }
  # charge tail (its brass-lamp trail while it homes)
  for ($f=1; $f -le 4; $f++) {
    $c = New-DS 24 24
    for ($k=0; $k -lt 4; $k++) { $p=($k/3.0)
      $rr = 3.2 - $p*2.4
      $ph = $k + $f
      DsDisc $c (12-$p*9) (12+[Math]::Sin($ph*0.9)*2.2) $rr $(if($k -lt 2){27}else{26}) }
    $items += @{ name=("ds_shard_chargeTail__f{0:D2}" -f $f); c=$c; kit='shard'; part='chargeTail'; frames=4; note='homing trail' }
  }
  return $items
}
function Get-DSItemGlobal { param($items,[string]$name) foreach ($i in $items) { if ($i.name -eq $name) { return $i.c } } return (New-DS 1 1) }
