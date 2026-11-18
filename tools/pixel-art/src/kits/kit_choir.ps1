<#  DARKSTAR kit: choir faction units (grub, acolyte, deceiver, penitent).
    Palette lock: CHOIR ramps + BONE + VOID outline. NEVER GASLIGHT on Choir.   #>

function Build-KitGrub {
  $items = @()
  # ---------- Oubliette Grub: teardrop + 4 tiny limbs + carried shard (a genuflection) ----------
  for ($f=1; $f -le 2; $f++) {          # breathe (2-frame rule: living things always breathe)
    $c = New-DS 64 64
    $dy = 0; if ($f -eq 2) { $dy = 1 }
    # 4 limbs drawn first (behind body)
    $lim = New-DS 64 64
    foreach ($s in @(@(16,52),@(24,56),@(40,56),@(48,52))) {
      DsLimb $lim 32 (40+$dy) $s[0] ($s[1]+$dy) 3 1.4 13 2 7 }
    DsShade $lim @(12,12,13,14) -1 -1 15 1 1 15 0
    DsBlit $c $lim 0 0
    # body: teardrop (narrow top, wide bottom)
    $bod = New-DS 64 64
    DsEllipse $bod 32 (40+$dy) 13 12 13
    DsPoly $bod @(32,(22+$dy),22,(38+$dy),42,(38+$dy)) 13
    DsDisc $bod 32 (30+$dy) 7 13
    DsSpeckle $bod 12 0.10
    DsShade $bod @(12,13,14,15) -1 -1 16 1 1 17 0.9
    DsBlit $c $bod 0 0
    # hood drape (vestiment) + nape trim
    $hood = New-DS 64 64
    DsPoly $hood @(32,(24+$dy),25,(34+$dy),27,(40+$dy),37,(40+$dy),39,(34+$dy)) 14
    DsLine $hood 26 (36+$dy) 40 (37+$dy) 15 1
    DsShade $hood @(12,13,14,15) -1 -1 16 1 1 17 0
    DsBlit $c $hood 0 0
    # three small eyes (wrong count: 3 on a face that expects 2)
    DsEye $c 29 (31+$dy) 2.0 17 13 0
    DsEye $c 35 (31+$dy) 2.0 17 13 0
    DsEye $c 32 (27+$dy) 1.4 17 13 0
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_grub_core__f{0:D2}" -f $f); c=$c; kit='grub'; part='core'; frames=2; note='breathe cycle' }
  }
  # carried shard (held overhead - the readable 'worker' tell)
  $s = New-DS 32 32
  DsPoly $s @(16,3,22,14,16,27,10,14) 20
  DsPoly $s @(16,7,20,15,16,23,12,15) 21
  DsPoly $s @(16,11,18,16,16,20,14,16) 23
  DsSilhouetteOutline $s 0
  $items += @{ name='ds_grub_shardCarry'; c=$s; kit='grub'; part='shardCarry'; note='gripped shard, socket=grubTop' }
  # genuflect frame (bows when it deposits at a Sepulchre)
  $g = Copy-DSCanvas (Get-DSItem $items 'ds_grub_core__f01')
  for ($y=0; $y -lt 64; $y++) { for ($x=0; $x -lt 64; $x++) {
    $v = Get-DS $g $x $y; if ($v -lt 0) { continue }
    $ny = $y + [int][Math]::Round(6 * (1 - ($y/64.0)))
    Set-DS $g $x $ny $v; Set-DS $g $x $y -1 } }
  $items += @{ name='ds_grub_genuflect'; c=$g; kit='grub'; part='genuflect'; note='bow at Sepulchre (piety tag)' }
  # shell + hood swap parts (mutation / variant swaps)
  $sh = New-DS 48 48
  DsEllipse $sh 24 24 15 13 8; DsSpeckle $sh 7 0.2; DsLine $sh 10 24 38 24 7 2; DsLine $sh 24 12 24 36 7 2
  DsShade $sh @(6,7,8,9) -1 -1 4 1 1 10 0
  DsSilhouetteOutline $sh 0
  $items += @{ name='ds_grub_shell_01'; c=$sh; kit='grub'; part='shell'; note='stone-shell variant (Entropy>=4)' }
  $hd = New-DS 40 40
  DsPoly $hd @(20,4,8,26,14,34,26,34,32,26) 12
  DsPoly $hd @(20,10,13,26,27,26) 0
  DsLine $hd 12 28 28 28 15 1
  DsShade $hd @(12,13,14,15) -1 -1 16 1 1 17 0
  DsSilhouetteOutline $hd 0
  $items += @{ name='ds_grub_hood_01'; c=$hd; kit='grub'; part='hood'; note='mitre hood variant (Shrine-corrupted)' }
  # assembled
  $a = New-DS 64 96
  DsBlit $a (Get-DSItem $items 'ds_grub_core__f01') 0 32
  DsBlit $a (Get-DSItem $items 'ds_grub_shardCarry') 16 2
  $items += @{ name='ds_grub_ASSEMBLED_worker'; c=$a; kit='grub'; part='ASSEMBLED'; note='worker at a shrine' }
  return $items
}

function Build-KitAcolyte {
  $items = @()
  # ---------- Acolyte / Censer Knight: bell vestment + rotating censer turret ----------
  for ($f=1; $f -le 2; $f++) {
    $c = New-DS 64 128
    $dy = 0; if ($f -eq 2) { $dy = 1 }
    # vestment (bell): narrow shoulders, wide hem
    $v = New-DS 64 128
    DsPoly $v @(22,(40+$dy),42,(40+$dy),52,(120+$dy),12,(120+$dy)) 13
    DsEllipse $v 32 (44+$dy) 12 8 13
    DsSpeckle $v 12 0.07
    DsShade $v @(12,13,14,15) -1 -1 16 1 1 17 0.55
    DsBlit $c $v 0 0
    # stole (ritual paint band down the front) + hem trim
    $stole = New-DS 64 128
    DsPoly $stole @(28,(46+$dy),36,(46+$dy),38,(116+$dy),26,(116+$dy)) 15
    DsSpeckle $stole 16 0.18
    DsLine $stole 24 112 40 112 16 1
    DsBlit $c $stole 0 0
    # chitin shoulders (bone pauldrons)
    $sh = New-DS 64 128
    DsEllipse $sh 20 (40+$dy) 8 6 9
    DsEllipse $sh 44 (40+$dy) 8 6 9
    DsShade $sh @(6,7,8,9) -1 -1 4 1 1 10 0
    DsBlit $c $sh 0 0
    # cowl head with a face void (no face: the horror is the emptiness) + 2 eyes low
    $hd = New-DS 64 128
    DsPoly $hd @(32,(20+$dy),21,(36+$dy),24,(48+$dy),40,(48+$dy),43,(36+$dy)) 13
    DsPoly $hd @(32,(28+$dy),25,(40+$dy),39,(40+$dy)) 0
    DsShade $hd @(12,13,14,15) -1 -1 16 1 1 17 0
    DsBlit $c $hd 0 0
    DsEye $c 28 (41+$dy) 2.2 17 13 0
    DsEye $c 36 (41+$dy) 2.2 17 13 0
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_acolyte_veil__f{0:D2}" -f $f); c=$c; kit='acolyte'; part='veil'; frames=2; note='body+breathe' }
  }
  # censer turret (engine-rotated about socket shoulderR; the 0.25s tell)
  foreach ($ang in 0,1,2,3) {
    $cs = New-DS 40 56
    DsLine $cs 20 0 20 22 8 1
    DsLine $cs 16 0 16 20 8 1
    $body = New-DS 40 56
    DsDisc $body 20 32 9 8
    DsRect $body 14 26 26 34 9 -Fill
    DsDisc $body 20 32 5 19
    DsDisc $body 20 32 3 21
    $off = @(-4,-2,2,4)[$ang]
    DsDisc $body (20+$off) 32 2 22
    DsShade $body @(6,7,8,9) -1 -1 4 1 1 10 0
    DsBlit $cs $body 0 0
    DsSilhouetteOutline $cs 0
    $items += @{ name=("ds_acolyte_censer_animswing{0:D2}" -f $ang); c=$cs; kit='acolyte'; part='censer'; frames=4; note='swing cycle, socket=shoulderR' }
  }
  # broken halo + thurible smoke wisp (parts)
  $halo = New-DS 48 24
  for ($i=0; $i -lt 96; $i++) { $a = [Math]::PI*($i/96.0) + 0.4
    if ($i -in 34,35,60,61) { continue }
    Set-DS $halo ([int][Math]::Round(24+[Math]::Cos($a)*21)) ([int][Math]::Round(12-[Math]::Sin($a)*9)) 9 }
  for ($i=0; $i -lt 96; $i++) { $a = [Math]::PI*($i/96.0) + 0.4
    if ($i -in 34,35,60,61) { continue }
    Set-DS $halo ([int][Math]::Round(24+[Math]::Cos($a)*19)) ([int][Math]::Round(12-[Math]::Sin($a)*7)) 27 }
  $items += @{ name='ds_acolyte_haloBroken'; c=$halo; kit='acolyte'; part='haloBroken'; note='broken ring over head' }
  $th = New-DS 32 48
  DsSpiral $th 16 40 2 10 1.6 8 1.4 0
  DsDither $th 9 2
  DsSilhouetteOutline $th 0
  $items += @{ name='ds_acolyte_thurible'; c=$th; kit='acolyte'; part='thurible'; note='smoke wisp (Censer Knight elite)' }
  $cowl = New-DS 48 48
  DsPoly $cowl @(24,6,10,28,14,44,34,44,38,28) 12
  DsPoly $cowl @(24,16,15,32,33,32) 0
  DsShade $cowl @(12,13,14,15) -1 -1 16 1 1 17 0
  DsSilhouetteOutline $cowl 0
  $items += @{ name='ds_acolyte_cowl_01'; c=$cowl; kit='acolyte'; part='cowl'; note='variant cowl (mutation slot)' }
  $a = New-DS 96 128
  DsBlit $a (Get-DSItem $items 'ds_acolyte_veil__f01') 16 0
  DsBlit $a (Get-DSItem $items 'ds_acolyte_censer_animswing01') 52 30
  DsBlit $a (Get-DSItem $items 'ds_acolyte_haloBroken') 24 6
  $items += @{ name='ds_acolyte_ASSEMBLED_base'; c=$a; kit='acolyte'; part='ASSEMBLED'; note='warrior, censer turret live' }
  return $items
}

function Build-KitDeceiver {
  $items = @()
  for ($f=1; $f -le 2; $f++) {
    $c = New-DS 128 64
    $dy = 0; if ($f -eq 2) { $dy = 1 }
    $bod = New-DS 128 64
    DsEllipse $bod 74 (34+$dy) 22 13 13                      # elongated body
    DsPoly $bod @(52,(34+$dy),30,(26+$dy),28,(44+$dy),52,(44+$dy)) 13  # trailing sleeve
    DsSpeckle $bod 12 0.08
    DsShade $bod @(12,13,14,15) -1 -1 16 1 1 17 0.6
    DsBlit $c $bod 0 0
    # long empty arms reaching forward (theft silhouette), hook at the wrist
    $arm = New-DS 128 64
    DsLimb $arm 66 (28+$dy) 22 (18+$dy) 5 2 14 3 12
    DsLimb $arm 66 (40+$dy) 24 (48+$dy) 5 2 14 -3 12
    DsMandible $arm 22 (18+$dy) ([Math]::PI*1.15) 9 3 15
    DsMandible $arm 24 (48+$dy) ([Math]::PI*0.85) 9 3 15
    DsShade $arm @(12,13,14,15) -1 -1 16 1 1 17 0
    DsBlit $c $arm 0 0
    # head: no mouth plane where the mouth should be; one eye low + a wrong ear-eye
    DsDisc $c 52 (30+$dy) 8 13
    DsEye $c 48 (31+$dy) 2.6 17 13 0
    DsEye $c 56 (24+$dy) 1.6 17 13 0
    DsLine $c 46 (38+$dy) 58 (38+$dy) 12 1
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_deceiver_core__f{0:D2}" -f $f); c=$c; kit='deceiver'; part='core'; frames=2; note='breathe; hands empty' }
  }
  # offering lamp (a stolen lantern: the ONE documented GASLIGHT exception, and it is GAS-1 dark brass only)
  $ol = New-DS 32 32
  DsRect $ol 12 12 20 22 25 -Fill
  DsPoly $ol @(10,12,22,12,16,4) 24
  DsDisc $ol 16 17 3 26
  DsSilhouetteOutline $ol 0
  $items += @{ name='ds_deceiver_offeringLamp'; c=$ol; kit='deceiver'; part='offeringLamp'; note='stolen lantern (palette exception, documented)' }
  $hk = New-DS 32 32
  DsMandible $hk 16 26 ([Math]::PI*1.25) 18 5 14
  DsMandible $hk 16 26 ([Math]::PI*0.75) 16 4 14
  DsShade $hk @(12,13,14,15) -1 -1 16 1 1 17 0
  DsSilhouetteOutline $hk 0
  $items += @{ name='ds_deceiver_hook'; c=$hk; kit='deceiver'; part='hook'; note='swap part (mutation)' }
  return $items
}

function Build-KitPenitent {
  $items = @()
  for ($f=1; $f -le 2; $f++) {
    $c = New-DS 64 64
    $dy = 0; if ($f -eq 2) { $dy = -1 }
    $h = New-DS 64 64
    DsPoly $h @(32,(10+$dy),18,(30+$dy),20,(56+$dy),44,(56+$dy),46,(30+$dy)) 10
    DsPoly $h @(32,(16+$dy),23,(32+$dy),41,(32+$dy)) 1   # face void (only lit by YOUR lantern)
    DsShade $h @(8,9,10,11) -1 -1 3 1 1 11 0.4
    DsBlit $c $h 0 0
    DsDither $c 1 2 0 0 63 63                                  # translucency via ordered dither, not alpha
    # folded hands + tear streaks (bone)
    DsLimb $c 26 44 32 50 3 2 10 1 6
    DsLimb $c 38 44 32 50 3 2 10 -1 6
    foreach ($x in 28,36) { DsLine $c $x 34 ($x-1) 44 9 1 }
    DsSilhouetteOutline $c 0
    $items += @{ name=("ds_penitent_core__f{0:D2}" -f $f); c=$c; kit='penitent'; part='core'; frames=2; note='translucent via dither' }
  }
  $rg = New-DS 56 28
  for ($i=0; $i -lt 120; $i++) { $a=[Math]::PI*2*($i/120.0)
    if ($i -in 8,9,10,52,53,90) { continue }
    Set-DS $rg ([int][Math]::Round(28+[Math]::Cos($a)*25)) ([int][Math]::Round(14+[Math]::Sin($a)*11)) 28 }
  $items += @{ name='ds_penitent_ringBroken'; c=$rg; kit='penitent'; part='ringBroken'; note='broken halo ring' }
  $t = New-DS 16 32
  DsLine $t 8 4 7 26 10 1; DsDisc $t 7 27 1.6 10
  DsSilhouetteOutline $t 0
  $items += @{ name='ds_penitent_tears'; c=$t; kit='penitent'; part='tears'; note='tear streak part (swap)' }
  return $items
}
