<#
  DARKSTAR pixel-art core library  (tools/pixel-art/src/ds_pixcore.ps1)
  ------------------------------------------------------------------
  Palette-indexed canvas ops in PowerShell + System.Drawing.
  Source of truth for colours: assets/palettes/darkstar_palette.json
  Every generated sprite is palette-locked, outline-clean and deterministic (seeded).
  Dot-source this file:  . ..\src\ds_pixcore.ps1
#>

Add-Type -AssemblyName System.Drawing

$script:PALPATH = 'E:\GameDev\ProjectDarkstar\assets\palettes\darkstar_palette.json'
$script:PAL      = $null
$script:PALNAMES = $null

function DsLoadPalette {
  param([string]$Path = $script:PALPATH)
  $j = Get-Content $Path -Raw | ConvertFrom-Json
  $argb = New-Object 'int[]' 32
  $name = New-Object 'string[]' 32
  foreach ($e in $j.index) {
    $h = $e.hex.TrimStart('#')
    $r = [Convert]::ToInt32($h.Substring(0,2),16); $g = [Convert]::ToInt32($h.Substring(2,2),16); $b = [Convert]::ToInt32($h.Substring(4,2),16)
    $argb[$e.i] = ([int]255 -shl 24) -bor ($r -shl 16) -bor ($g -shl 8) -bor $b
    $name[$e.i] = $e.name
  }
  $script:PAL = $argb; $script:PALNAMES = $name; $script:PALJ = $j
}
if ($null -eq $script:PAL) { DsLoadPalette }

# ---------- canvas ----------
function New-DS { param([int]$W=64,[int]$H=64)
  $px = New-Object 'int[]' ($W*$H)
  for ($i=0; $i -lt $px.Length; $i++) { $px[$i] = -1 }
  return @{ W=$W; H=$H; Px=$px }
}
function DSin { param($c,[int]$x,[int]$y) return ($x -ge 0 -and $x -lt $c.W -and $y -ge 0 -and $y -lt $c.H) }
function Set-DS { param($c,[int]$x,[int]$y,[int]$v) if (DSin $c $x $y) { $c.Px[$y*$c.W+$x] = $v } }
function Get-DS { param($c,[int]$x,[int]$y) if (DSin $c $x $y) { return $c.Px[$y*$c.W+$x] } return -1 }
function Test-DSBody { param($c,[int]$x,[int]$y) $p = Get-DS $c $x $y; return ($p -ge 0) }
function Copy-DSCanvas { param($c) return @{ W=$c.W; H=$c.H; Px=($c.Px.Clone()) } }

# ---------- seeded rng (deterministic across runs) ----------
$script:RNGState = 1
function DsSeed { param([int]$s) if ($s -le 0) { $s = 1 }; $script:RNGState = $s }
function DsRand { $script:RNGState = [int](([int64]$script:RNGState * 48271) % 2147483647); return ($script:RNGState % 10000) / 10000.0 }
function DsRandR { param([double]$a,[double]$b) return ($a + (DsRand) * ($b - $a)) }
function DsChance { param([double]$p) return ((DsRand) -lt $p) }

# ---------- primitives ----------
function DsRect { param($c,[int]$x0,[int]$y0,[int]$x1,[int]$y1,[int]$v,[switch]$Fill)
  if ($Fill) { for ($y=$y0; $y -le $y1; $y++) { for ($x=$x0; $x -le $x1; $x++) { Set-DS $c $x $y $v } } }
  else { for ($x=$x0; $x -le $x1; $x++) { Set-DS $c $x $y0 $v; Set-DS $c $x $y1 $v }
         for ($y=$y0; $y -le $y1; $y++) { Set-DS $c $x0 $y $v; Set-DS $c $x1 $y $v } }
}
function DsDisc { param($c,[double]$cx,[double]$cy,[double]$r,[int]$v)
  $ri = [Math]::Ceiling($r)
  for ($y=[int][Math]::Floor($cy-$ri); $y -le [int][Math]::Ceiling($cy+$ri); $y++) {
    for ($x=[int][Math]::Floor($cx-$ri); $x -le [int][Math]::Ceiling($cx+$ri); $x++) {
      $dx=$x-$cx; $dy=$y-$cy
      if (($dx*$dx + $dy*$dy) -le ($r*$r + 0.25)) { Set-DS $c $x $y $v }
    } }
}
function DsEllipse { param($c,[double]$cx,[double]$cy,[double]$rx,[double]$ry,[int]$v)
  for ($y=[int][Math]::Floor($cy-[Math]::Ceiling($ry)); $y -le [int][Math]::Ceiling($cy+[Math]::Ceiling($ry)); $y++) {
    for ($x=[int][Math]::Floor($cx-[Math]::Ceiling($rx)); $x -le [int][Math]::Ceiling($cx+[Math]::Ceiling($rx)); $x++) {
      $dx=($x-$cx)/[Math]::Max($rx,0.001); $dy=($y-$cy)/[Math]::Max($ry,0.001)
      if (($dx*$dx + $dy*$dy) -le 1.06) { Set-DS $c $x $y $v } } }
}
function DsLine { param($c,[double]$x0,[double]$y0,[double]$x1,[double]$y1,[int]$v,[double]$t=1.0)
  $d = [Math]::Max([Math]::Abs($x1-$x0),[Math]::Abs($y1-$y0)); $n = [Math]::Max(1,[int][Math]::Ceiling($d))
  for ($i=0; $i -le $n; $i++) { $p = $i/$n
    if ($t -le 1.0) { Set-DS $c ([int][Math]::Round($x0 + ($x1-$x0)*$p)) ([int][Math]::Round($y0 + ($y1-$y0)*$p)) $v }
    else { DsDisc $c ($x0 + ($x1-$x0)*$p) ($y0 + ($y1-$y0)*$p) ($t/2.0) $v } }
}
# tapered limb / tentacle: w0 -> w1, optional bow (perpendicular offset amplitude), segment jitter
function DsLimb { param($c,[double]$x0,[double]$y0,[double]$x1,[double]$y1,[double]$w0,[double]$w1,[int]$v,
                   [double]$bow=0.0,[int]$segs=10,[double]$taperPow=1.0)
  $dx=$x1-$x0; $dy=$y1-$y0; $len=[Math]::Max(1.0,[Math]::Sqrt($dx*$dx+$dy*$dy))
  $nx=-$dy/$len; $ny=$dx/$len
  for ($i=0; $i -le $segs; $i++) {
    $p=$i/$segs; $w = $w0 + ($w1-$w0)*[Math]::Pow($p,$taperPow)
    $off = $bow * [Math]::Sin([Math]::PI*$p)
    $cx = $x0 + $dx*$p + $nx*$off; $cy = $y0 + $dy*$p + $ny*$off
    $r = [Math]::Max(0.45,$w/2.0)
    DsDisc $c $cx $cy $r $v
  }
  if ($w0 -ge 1.5) { DsDisc $c $x0 $y0 ([Math]::Max(0.45,$w0/2.0)) $v }
  if ($w1 -ge 1.5) { DsDisc $c $x1 $y1 ([Math]::Max(0.45,$w1/2.0)) $v }
}
function DsFlatCoords { param($x)
  $out = @()
  if ($x -is [System.Array]) { foreach ($e in $x) { $out += DsFlatCoords $e } }
  else { $out += [double]$x }
  return $out }
function DsPoly { param($c,$pts,[int]$v)
  # normalise input: accepts a flat coordinate list (x0,y0,x1,y1,...) or nested pairs at any depth.
  # (PowerShell array literals are inconsistent about nesting, so normalise defensively.)
  $flat = DsFlatCoords $pts
  $n = [int]($flat.Count / 2)
  if ($n -lt 3) { return }
  $P = New-Object 'object[]' $n
  for ($i=0; $i -lt $n; $i++) { $P[$i] = @($flat[2*$i], $flat[2*$i+1]) }
  $minY = $P[0][1]; $maxY = $P[0][1]
  for ($i=1; $i -lt $n; $i++) { if ($P[$i][1] -lt $minY) { $minY=$P[$i][1] }; if ($P[$i][1] -gt $maxY) { $maxY=$P[$i][1] } }
  for ($y=[int][Math]::Floor($minY); $y -le [int][Math]::Ceiling($maxY); $y++) {
    $inter = @()
    for ($i=0; $i -lt $n; $i++) {
      $a=$P[$i]; $b=$P[($i+1)%$n]
      if (($a[1] -le $y -and $b[1] -gt $y) -or ($b[1] -le $y -and $a[1] -gt $y)) {
        $t = ($y - $a[1]) / ($b[1] - $a[1])
        $iv = $a[0] + ($b[0]-$a[0])*$t
        $inter += $iv } }
    if ($inter.Count -lt 2) { continue }
    $sorted = @(($inter | ForEach-Object { [double]$_ } | Sort-Object))
    for ($k=0; $k+1 -lt $sorted.Count; $k+=2) {
      for ($x=[int][Math]::Ceiling($sorted[$k]); $x -le [int][Math]::Floor($sorted[$k+1]); $x++) { Set-DS $c $x $y $v } } }
}
function DsSpiral { param($c,[double]$cx,[double]$cy,[double]$r0,[double]$r1,[double]$turns,[int]$v,[double]$w=1.0,[double]$phase=0)
  $n = [int][Math]::Ceiling($turns*24)
  $px=$cx; $py=$cy
  for ($i=0; $i -le $n; $i++) { $p=$i/$n; $ang=$phase + $p*$turns*2*[Math]::PI; $r=$r0+($r1-$r0)*$p
    $nx=$cx+[Math]::Cos($ang)*$r; $ny=$cy+[Math]::Sin($ang)*$r
    DsLine $c $px $py $nx $ny $v $w; $px=$nx; $py=$ny }
}

# ---------- symmetry (draw a quadrant/eighth, then mirror) ----------
function DsMirrorX { param($c) for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt [int]($c.W/2); $x++) {
  $v = Get-DS $c $x $y; if ($v -ge 0) { Set-DS $c ($c.W-1-$x) $y $v } } } }
function DsMirrorY { param($c) for ($y=0; $y -lt [int]($c.H/2); $y++) { for ($x=0; $x -lt $c.W; $x++) {
  $v = Get-DS $c $x $y; if ($v -ge 0) { Set-DS $c $x ($c.H-1-$y) $v } } } }
function DsRotate90 { param($c) $o = Copy-DSCanvas $c
  for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt $c.W; $x++) { Set-DS $c $y ($c.W-1-$x) (Get-DS $o $x $y) } } }
# radial: place a source canvas rotated n times around (cx,cy) onto dest
function DsRadial { param($d,$src,[double]$cx,[double]$cy,[int]$count,[double]$startAng=0)
  for ($k=0; $k -lt $count; $k++) {
    $a = $startAng + ($k * 2*[Math]::PI / $count); $ca=[Math]::Cos($a); $sa=[Math]::Sin($a)
    for ($y=0; $y -lt $src.H; $y++) { for ($x=0; $x -lt $src.W; $x++) {
      $v = Get-DS $src $x $y; if ($v -lt 0) { continue }
      $ux = $x - $src.W/2.0; $uy = $y - $src.H/2.0
      $rx = $ca*$ux - $sa*$uy + $cx; $ry = $sa*$ux + $ca*$uy + $cy
      Set-DS $d ([int][Math]::Round($rx)) ([int][Math]::Round($ry)) $v } } }
}

# ---------- assembly ----------
function DsBlit { param($d,$s,[int]$dx,[int]$dy,[switch]$OverTransparentOnly)
  for ($y=0; $y -lt $s.H; $y++) { for ($x=0; $x -lt $s.W; $x++) {
    $v = Get-DS $s $x $y; if ($v -lt 0) { continue }
    $tx=$dx+$x; $ty=$dy+$y
    if ($OverTransparentOnly -and (Get-DS $d $tx $ty) -ge 0) { continue }
    Set-DS $d $tx $ty $v } }
}
function DsTrim { param($c)   # returns bounds of non-empty region
  $x0=99999;$y0=99999;$x1=-1;$y1=-1
  for ($y=0;$y -lt $c.H;$y++){for($x=0;$x -lt $c.W;$x++){ if ($c.Px[$y*$c.W+$x] -ge 0) { if($x -lt $x0){$x0=$x}; if($x -gt $x1){$x1=$x}; if($y -lt $y0){$y0=$y}; if($y -gt $y1){$y1=$y} } }}
  return @{X0=$x0;Y0=$y0;X1=$x1;Y1=$y1;W=($x1-$x0+1);H=($y1-$y0+1)}
}

# ---------- silhouette + shading ----------
# flat-fill helper: set every pixel of a mask list
function DsSilhouetteOutline { param($c,[int]$ink=0,[int[]]$except=$null)
  $o = Copy-DSCanvas $c
  for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt $c.W; $x++) {
    if ((Get-DS $o $x $y) -ge 0) { continue }
    $near = $false
    for ($dy=-1; $dy -le 1 -and -not $near; $dy++) { for ($dx=-1; $dx -le 1; $dx++) {
      if ((Get-DS $o ($x+$dx) ($y+$dy)) -ge 0) { $near = $true; break } } }
    if ($near) { Set-DS $c $x $y $ink } } }
}
# 3-step directional shade + optional vertical gradient + rim light.
# $ramp = 4 palette indices: [deepShadow, shadow, base, light] ; $spec optional 5th for specular
function DsShade { param($c,[int[]]$ramp,[double]$lx=-1.0,[double]$ly=-1.0,$rim=$null,[double]$rimx=1.0,[double]$rimy=1.0,$spec=$null,[double]$gradAmt=0.0)
  $o = Copy-DSCanvas $c
  for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt $c.W; $x++) {
    $v = Get-DS $o $x $y; if ($v -lt 0) { continue }
    $l = 0; $d = 0
    $fx=[int][Math]::Round($x+$lx); $fy=[int][Math]::Round($y+$ly)
    $bx=[int][Math]::Round($x-$lx); $by=[int][Math]::Round($y-$ly)
    if ((Get-DS $o $fx $fy) -lt 0) { $l = 1 }
    if ((Get-DS $o $bx $by) -lt 0) { $d = 1 }
    $t = 2 + $l - $d
    if ($gradAmt -gt 0) { $gy = [int][Math]::Floor(($y / [Math]::Max(1,$c.H-1)) * $gradAmt)
      if ($t -gt 1) { $t -= $gy } }
    if ($t -lt 0) { $t = 0 }; if ($t -gt 3) { $t = 3 }
    $nv = $ramp[$t]
    if ($null -ne $spec -and $l -eq 1 -and $d -eq 0) {
      $s1 = (Get-DS $o ($x+[int][Math]::Round(-$ly)) ($y+[int][Math]::Round($lx))) -lt 0
      $s2 = (Get-DS $o ($x+[int][Math]::Round($ly))  ($y+[int][Math]::Round(-$lx))) -lt 0
      if ($s1 -and $s2) { $nv = $spec } }
    if ($null -ne $rim -and $d -eq 1 -and $l -eq 0) {
      if ((Get-DS $o ([int][Math]::Round($x+$rimx)) ([int][Math]::Round($y+$rimy))) -lt 0) { $nv = $rim } }
    Set-DS $c $x $y $nv } }
}
# recolour a whole region by radial distance from (cx,cy) - used for glass/glow cores
function DsShadeRadial { param($c,[int[]]$ramp,[double]$cx,[double]$cy,[double]$rmax)
  $o = Copy-DSCanvas $c
  for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt $c.W; $x++) {
    if ((Get-DS $o $x $y) -lt 0) { continue }
    $dd=[Math]::Sqrt(($x-$cx)*($x-$cx)+($y-$cy)*($y-$cy))
    $t = 3 - [int][Math]::Floor(($dd/[Math]::Max(0.001,$rmax)) * 3.99)
    if ($t -lt 0) { $t = 0 }; if ($t -gt 3) { $t = 3 }
    Set-DS $c $x $y $ramp[$t] } }
}
function DsSpeckle { param($c,[int]$v,[double]$p,[int]$x0=0,[int]$y0=0,[int]$x1=-1,[int]$y1=-1)
  if ($x1 -lt 0) { $x1=$c.W-1 }; if ($y1 -lt 0) { $y1=$c.H-1 }
  $o = Copy-DSCanvas $c
  for ($y=$y0; $y -le $y1; $y++) { for ($x=$x0; $x -le $x1; $x++) {
    if ((Get-DS $o $x $y) -lt 0) { continue }
    if (DsChance $p) { Set-DS $c $x $y $v } } }
}
function DsDither { param($c,[int]$v,[int]$cell=2,[int]$x0=0,[int]$y0=0,[int]$x1=-1,[int]$y1=-1)
  if ($x1 -lt 0) { $x1=$c.W-1 }; if ($y1 -lt 0) { $y1=$c.H-1 }
  $o = Copy-DSCanvas $c
  for ($y=$y0; $y -le $y1; $y++) { for ($x=$x0; $x -le $x1; $x++) {
    if ((Get-DS $o $x $y) -lt 0) { continue }
    if ((((($x -shl 1) -bxor $y) -band 1) -eq 0)) { Set-DS $c $x $y $v } } }
}
function DsWarpNoise { param($c,[int]$v,[double]$p)  # adds pixels just outside silhouette (fuzz / shroud edge)
  $o = Copy-DSCanvas $c
  for ($y=1; $y -lt $c.H-1; $y++) { for ($x=1; $x -lt $c.W-1; $x++) {
    if ((Get-DS $o $x $y) -ge 0) { continue }
    $n=0
    if ((Get-DS $o ($x+1) $y) -ge 0) { $n++ }
    if ((Get-DS $o ($x-1) $y) -ge 0) { $n++ }
    if ((Get-DS $o $x ($y+1)) -ge 0) { $n++ }
    if ((Get-DS $o $x ($y-1)) -ge 0) { $n++ }
    if ($n -ge 1 -and (DsChance $p)) { Set-DS $c $x $y $v } } }
}
function DsEye { param($c,[double]$cx,[double]$cy,[double]$r,[int]$sclera,[int]$iris,[int]$pupil,[int]$glint=11)
  DsDisc $c $cx $cy $r $sclera
  $ir=[Math]::Max(0.6,$r*0.62); DsDisc $c ($cx+0.15) ($cy+0.1) $ir $iris
  $pr=[Math]::Max(0.4,$r*0.3);  DsDisc $c ($cx+0.2) ($cy+0.15) $pr $pupil
  if ($r -ge 1.6) { Set-DS $c ([int][Math]::Round($cx-[Math]::Floor($r*0.4))) ([int][Math]::Round($cy-[Math]::Floor($r*0.4))) $glint }
}
function DsMandible { param($c,[double]$cx,[double]$cy,[double]$ang,[double]$len,[double]$w,[int]$v)
  $ex=$cx+[Math]::Cos($ang)*$len; $ey=$cy+[Math]::Sin($ang)*$len
  $mx=$cx+[Math]::Cos($ang-0.55)*$len*0.55; $my=$cy+[Math]::Sin($ang-0.55)*$len*0.55
  DsLimb $c $cx $cy $mx $my $w ($w*0.8) $v 1.5 6
  DsLimb $c $mx $my $ex $ey ($w*0.8) 0.8 $v -1.2 6
}

# ---------- output ----------
function Save-DSPng { param($c,[string]$Path)
  $dir = Split-Path $Path -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp = New-Object System.Drawing.Bitmap $c.W, $c.H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y=0; $y -lt $c.H; $y++) { for ($x=0; $x -lt $c.W; $x++) {
    $v = $c.Px[$y*$c.W+$x]
    if ($v -lt 0) { $bmp.SetPixel($x,$y,[System.Drawing.Color]::Transparent) }
    else { $bmp.SetPixel($x,$y,[System.Drawing.Color]::FromArgb($script:PAL[$v] -bor ([int]255 -shl 24))) } } }
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
function Load-DSPng { param([string]$Path)
  $bmp = New-Object System.Drawing.Bitmap $Path
  $c = New-DS $bmp.Width $bmp.Height
  for ($y=0;$y -lt $bmp.Height;$y++){for($x=0;$x -lt $bmp.Width;$x++){
    $p=$bmp.GetPixel($x,$y)
    if ($p.A -lt 8) { continue }
    $best=-1; $bd=1e9
    for ($i=0;$i -lt 32;$i++){ $q=$script:PAL[$i]; $dr=$p.R-(($q -shr 16) -band 255); $dg=$p.G-(($q -shr 8) -band 255); $db=$p.B-($q -band 255)
      $dd=$dr*$dr+$dg*$dg+$db*$db; if ($dd -lt $bd){$bd=$dd;$best=$i} }
    $c.Px[$y*$c.W+$x]=$best }}
  $bmp.Dispose(); return $c
}
function Scale-DSC { param($c,[int]$f) $o = New-DS ($c.W*$f) ($c.H*$f)
  for ($y=0;$y -lt $c.H;$y++){for($x=0;$x -lt $c.W;$x++){ $v=Get-DS $c $x $y; if($v -lt 0){continue}
    for ($j=0;$j -lt $f;$j++){for($i=0;$i -lt $f;$i++){ Set-DS $o ($x*$f+$i) ($y*$f+$j) $v }}}}
  return $o }
function Save-DSThumbnail { param([string]$Src,[string]$Dst,[int]$Scale)
  $src = New-Object System.Drawing.Bitmap $Src
  $w = $src.Width*$Scale; $h = $src.Height*$Scale
  $bmp = New-Object System.Drawing.Bitmap $w,$h,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.DrawImage($src, 0, 0, $w, $h)
  $g.Dispose(); $src.Dispose()
  $dir = Split-Path $Dst -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($Dst,[System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
# contact sheet: dark VOID-1 grid background, labelled by filename (label = plain text, small)
function Save-DSContactSheet { param([string[]]$Files,[string]$OutPath,[int]$Cell=128,[int]$Cols=6,[int]$Scale=2)
  $cols=[Math]::Min($Cols,[Math]::Max(1,$Files.Count)); $rows=[Math]::Ceiling($Files.Count/$cols)
  $cellH = $Cell*$Scale + 18
  $W = $cols*$cellH + 8; $H = $rows*$cellH + 8
  $bmp = New-Object System.Drawing.Bitmap $W,$H,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::FromArgb(255,19,20,40))
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $font = New-Object System.Drawing.Font 'Consolas',8
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,185,184,174))
  $idx=0
  foreach ($f in $Files) { if (-not (Test-Path $f)) { continue }
    $im = New-Object System.Drawing.Bitmap $f
    $sw = [Math]::Min($Cell*$Scale, [Math]::Ceiling($im.Width*$Scale))
    $sh = [Math]::Min($Cell*$Scale, [Math]::Ceiling($im.Height*$Scale))
    if ($im.Width*$Scale -gt $Cell*$Scale -or $im.Height*$Scale -gt $Cell*$Scale) {
      $sc=[Math]::Min(($Cell*$Scale)/$im.Width,($Cell*$Scale)/$im.Height); $sw=[int][Math]::Floor($im.Width*$sc); $sh=[int][Math]::Floor($im.Height*$sc) }
    $cx = ($idx % $cols)*$cellH + 4; $cy = [int][Math]::Floor($idx/$cols)*$cellH + 4
    $g.DrawImage($im,$cx,$cy,$sw,$sh)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($f); if ($name.Length -gt 22) { $name = $name.Substring(0,22) }
    $g.DrawString($name,$font,$brush,$cx,($cy + $sh + 2))
    $im.Dispose(); $idx++ }
  $g.Dispose(); $font.Dispose(); $brush.Dispose()
  $dir = Split-Path $OutPath -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($OutPath,[System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
function Write-DSSummary { param($c)
  $set=@{}; for ($i=0;$i -lt $c.Px.Length;$i++){ $v=$c.Px[$i]; if($v -ge 0){ $set[$v]=1 } }
  $names = $set.Keys | Sort-Object | ForEach-Object { $script:PALNAMES[$_] }
  "colours=$($set.Keys.Count) [$($names -join ' ')] size=$($c.W)x$($c.H)"
}
