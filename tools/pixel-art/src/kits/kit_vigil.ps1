<#  DARKSTAR kit: vigil (player ship).  Palette lock: GASLIGHT + BONE + VOID-0 outline.
    Forward is UP. Engine-rotated in-game. Modules: core / bow / flankL / flankR / stern
    + upgrade modules (wingUp, wingDark, cowl) + lamp globe states.            ART-002 Â§4 #>

function Build-KitVigil {
  $items = @()
  # ---------- core hull (brass wedge + bone plating + lamp globe) ----------
  $c = New-DS 64 64
  # brass wedge hull
  $hull = New-DS 64 64
  DsPoly $hull @(32,10,25,30,24,44,40,44,39,30) 26
  DsRect $hull 29 44 35 52 26 -Fill                 # keel / engine neck
  DsDisc $hull 32 44 7 26
  DsShade $hull @(24,25,26,27) -1 -1 $null 1 1 28 0.9   # deep,shadow,base,light + spec
  DsBlit $c $hull 0 0
  # bone shoulder plating
  $pl = New-DS 64 64
  DsPoly $pl @(24,28,18,34,19,42,25,40) 9
  DsPoly $pl @(40,28,46,34,45,42,39,40) 9
  DsRect $pl 27 45 37 50 8 -Fill                     # engine block
  DsRect $pl 28 46 36 49 9 -Fill
  DsShade $pl @(6,7,8,9) -1 -1 4 1 1 10 0.8
  DsBlit $c $pl 0 0
  # ribs (burnt brass seams)
  foreach ($y in 33,38) { DsLine $c 26 $y 38 $y 25 1 }
  DsLine $c 32 30 32 44 25 1
  # lamp globe = brightest warm pixel in the game (GAS-5 core)
  $lamp = New-DS 64 64
  DsDisc $lamp 32 24 7 27; DsDisc $lamp 32 24 5 28; DsDisc $lamp 32 24 3 29
  DsBlit $c $lamp 0 0
  DsSilhouetteOutline $c 0
  $items += @{ name='ds_vigil_core'; c=$c; kit='vigil'; part='core'; note='hull+lamp, forward up' }

  # ---------- lamp globe states (Lantern / Surgelight / dark / broken) ----------
  foreach ($st in @(
      @{ n='ds_vigil_lampGlobe';   r=6; core=29; mid=28; rim=27; note='Lantern state: bright' },
      @{ n='ds_vigil_lampGlobeDim';r=5; core=28; mid=27; rim=26; note='low lantern / dim' },
      @{ n='ds_vigil_lampGlobeDark';r=4;core=26; mid=25; rim=24; note='lamp out (T4+ Inverted scenes)' },
      @{ n='ds_vigil_lampGlobeBurn';r=6; core=24; mid=29; rim=28; note='Surgelight flare (over-charge)' })) {
    $L = New-DS 32 32
    DsDisc $L 16 16 $st.r $st.rim; DsDisc $L 16 16 ($st.r-2) $st.mid; DsDisc $L 16 16 ($st.r-4) $st.core
    DsSilhouetteOutline $L 0
    $items += @{ name=$st.n; c=$L; kit='vigil'; part='lampGlobe'; note=$st.note }
  }

  # ---------- bow module (Arc-Lance mount, sits over the hull tip) ----------
  $b = New-DS 32 32
  DsRect $b 13 6 18 24 9 -Fill
  DsPoly $b @(12,6,19,6,17,2,14,2) 10
  DsRect $b 12 20 19 26 26 -Fill
  DsDisc $b 15.5 8 2.6 27
  DsShade $b @(6,7,8,9) -1 -1 4 1 1 10 0
  DsSilhouetteOutline $b 0
  $items += @{ name='ds_vigil_bow'; c=$b; kit='vigil'; part='bow'; note='Arc-Lance mount, socket=hullTip' }

  # ---------- flank modules (symmetric about socket axis; engine-rotatable) ----------
  $fl = New-DS 32 32
  DsPoly $fl @(2,10,28,6,30,14,4,20) 9      # swept plate
  DsLine $fl 4 12 28 9 26 2                              # brass rib
  DsRect $fl 26 6 31 16 8 -Fill                          # socket skirt (4px overlap)
  DsDisc $fl 8 13 2 10
  DsShade $fl @(6,7,8,9) -1 -1 4 1 1 10 0
  DsSilhouetteOutline $fl 0
  $items += @{ name='ds_vigil_flankL'; c=$fl; kit='vigil'; part='flankL'; note='port wing, socket=hullPort' }
  $fr = Copy-DSCanvas $fl; for ($y=0;$y -lt 32;$y++){for($x=0;$x -lt 32;$x++){ Set-DS $fr (31-$x) $y (Get-DS $fl $x $y) } }
  $items += @{ name='ds_vigil_flankR'; c=$fr; kit='vigil'; part='flankR'; note='starboard wing (mirrored)' }

  # ---------- stern module (thruster; 4 flame frames) ----------
  $st = New-DS 32 32
  $nozz = New-DS 32 32
  DsPoly $nozz @(10,0,22,0,24,14,8,14) 7
  DsRect $nozz 9 0 23 4 9 -Fill
  DsShade $nozz @(6,7,8,9) -1 -1 4 1 1 10 0
  DsBlit $st $nozz 0 0
  for ($f=1; $f -le 4; $f++) {
    $s2 = Copy-DSCanvas $st
    $len = 8 + (4 - [Math]::Abs($f-2.5))*3
    DsLimb $s2 16 13 16 (13+$len) 8 2 27 0 6 1.4
    DsLimb $s2 16 13 16 (13+$len*0.6) 5 1 28 0 5 1.4
    DsLimb $s2 16 13 16 (13+$len*0.3) 3 1 29 0 4 1.4
    DsSilhouetteOutline $s2 0
    $items += @{ name=("ds_vigil_stern__f{0:D2}" -f $f); c=$s2; kit='vigil'; part='stern'; frames=4; note='thrust flame cycle (move tag)' }
  }

  # ---------- upgrade modules (Lantern Tree visuals) ----------
  # wingUp: Ward-laced wing (adds a bone prong + ward chalk)
  $wu = New-DS 32 32
  DsBlit $wu $fl 0 0
  DsPoly $wu @(6,10,4,0,9,2,11,11) 10
  DsLine $wu 5 2 10 11 11 1
  $items += @{ name='ds_vigil_wingUp'; c=$wu; kit='vigil'; part='wingUp'; note='Ward-branch wing module' }
  # wingDark: Mad/Composure-burnt wing (charred, phosphor leak)
  $wd = New-DS 32 32
  DsPoly $wd @(2,10,28,6,30,14,4,20) 7
  DsLine $wd 4 12 28 9 24 2
  DsSpeckle $wd 19 0.16; DsWarpNoise $wd 20 0.10
  DsSilhouetteOutline $wd 0
  $items += @{ name='ds_vigil_wingDark'; c=$wd; kit='vigil'; part='wingDark'; note='Madness-branch wing (MADNESS purchase)' }
  # cowl: Hull-branch armour cowl over the lamp (cost: lamp radius down)
  $cw = New-DS 64 64
  DsPoly $cw @(24,18,32,12,40,18,42,30,22,30) 8
  DsPoly $cw @(28,20,32,16,36,20,36,28,28,28) 25
  DsDisc $cw 32 24 4 26; DsDisc $cw 32 24 2 27
  DsShade $cw @(6,7,8,9) -1 -1 4 1 1 10 0
  DsSilhouetteOutline $cw 0
  $items += @{ name='ds_vigil_cowl'; c=$cw; kit='vigil'; part='cowl'; note='Hull-branch cowl module (overlay on core)' }

  # ---------- assembled previews ----------
  $a = New-DS 128 96
  DsBlit $a $fl 16 34; DsBlit $a $fr 64 34
  DsBlit $a (Get-DSItem $items 'ds_vigil_core') 32 16
  DsBlit $a (Get-DSItem $items 'ds_vigil_bow') 48 8
  DsBlit $a (Get-DSItem $items 'ds_vigil_stern__f02') 48 58
  $items += @{ name='ds_vigil_ASSEMBLED_base'; c=$a; kit='vigil'; part='ASSEMBLED'; note='base loadout composite' }
  $b2 = New-DS 128 96
  DsBlit $b2 $wu 16 34; DsBlit $b2 $fl 64 34
  DsBlit $b2 (Get-DSItem $items 'ds_vigil_core') 32 16
  DsBlit $b2 (Get-DSItem $items 'ds_vigil_bow') 48 8
  DsBlit $b2 (Get-DSItem $items 'ds_vigil_cowl') 32 16
  DsBlit $b2 (Get-DSItem $items 'ds_vigil_stern__f03') 48 58
  $items += @{ name='ds_vigil_ASSEMBLED_warded'; c=$b2; kit='vigil'; part='ASSEMBLED'; note='warded loadout (late run)' }
  return $items
}
function Get-DSItem { param($items,[string]$name) foreach ($i in $items) { if ($i.name -eq $name) { return $i.c } } return (New-DS 1 1) }
