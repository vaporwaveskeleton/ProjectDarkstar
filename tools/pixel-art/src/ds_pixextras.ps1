<#  DARKSTAR pixel-art extras (tools/pixel-art/src/ds_pixextras.ps1)
    Arcs, chalk strokes, organic rock blobs, slicing, and the 5x7 pixel font
    used by the UI kit, the score readout and the title wordmark.            #>

function DsArc { param($c,[double]$cx,[double]$cy,[double]$r,[double]$a0,[double]$a1,[int]$v,[double]$w=1.0)
  $steps = [int][Math]::Max(6,[Math]::Ceiling([Math]::Abs($a1-$a0) * $r * 2))
  $px=$null;$py=$null
  for ($i=0; $i -le $steps; $i++) { $a=$a0+($a1-$a0)*($i/$steps)
    $x=$cx+[Math]::Cos($a)*$r; $y=$cy+[Math]::Sin($a)*$r
    if ($null -ne $px) { DsLine $c $px $py $x $y $v $w } else { DsDisc $c $x $y ($w/2.0) $v }
    $px=$x; $py=$y }
}
# broken chalk stroke: jittered, gapped, tapered - used for wards, sigils, UI keylines
function DsChalk { param($c,[double]$x0,[double]$y0,[double]$x1,[double]$y1,[int]$v,[double]$gapP=0.18,[double]$jit=0.7)
  $d=[Math]::Max([Math]::Abs($x1-$x0),[Math]::Abs($y1-$y0)); $n=[Math]::Max(2,[int][Math]::Ceiling($d))
  for ($i=0;$i -le $n;$i++){ if (DsChance $gapP) { continue }
    $p=$i/$n; $jx=(DsRand - 0.5)*2*$jit; $jy=(DsRand - 0.5)*2*$jit
    Set-DS $c ([int][Math]::Round($x0+($x1-$x0)*$p+$jx)) ([int][Math]::Round($y0+($y1-$y0)*$p+$jy)) $v } }
function DsChalkCircle { param($c,[double]$cx,[double]$cy,[double]$r,[int]$v,[double]$w=1.0,[double]$gapP=0.22)
  DsChalkArc $c $cx $cy $r 0 ([Math]::PI*2) $v $w $gapP }
function DsChalkArc { param($c,[double]$cx,[double]$cy,[double]$r,[double]$a0,[double]$a1,[int]$v,[double]$w=1.0,[double]$gapP=0.22)
  $steps=[int][Math]::Max(10,[Math]::Ceiling([Math]::Abs($a1-$a0)*$r*2))
  for ($i=0;$i -le $steps;$i++){ if (DsChance $gapP) { continue }
    $a=$a0+($a1-$a0)*($i/$steps); $rr=$r+(DsRand - 0.5)*1.4
    Set-DS $c ([int][Math]::Round($cx+[Math]::Cos($a)*$rr)) ([int][Math]::Round($cy+[Math]::Sin($a)*$rr)) $v
    if ($w -gt 1) { Set-DS $c ([int][Math]::Round($cx+[Math]::Cos($a)*($rr+1))) ([int][Math]::Round($cy+[Math]::Sin($a)*($rr+1))) $v } } }
# organic / rocky blob: radial value noise around a centre -> irregular polygon fill
function DsBlob { param($c,[double]$cx,[double]$cy,[double]$r,[int]$v,[int]$lobes=7,[double]$rough=0.30,[double]$phase=0.0,[int]$samples=64)
  $pts=@()
  for ($i=0; $i -lt $lobes; $i++) {
    $a=$phase + ($i/$lobes)*[Math]::PI*2
    $rr=$r*(1 + $rough*[Math]::Sin($i*2.399 + $phase*3) + $rough*0.5*[Math]::Cos($i*5.1))
    $pax = $cx + [Math]::Cos($a)*$rr; $pay = $cy + [Math]::Sin($a)*$rr
    $pts += (,@($pax,$pay)) }
  DsPoly $c $pts $v
  # soften: fill any pixel whose 4-neighbourhood is mostly inside the polygon-ish region
  for ($i=0;$i -lt $samples;$i++){ $a=(DsRand)*[Math]::PI*2; $rr=$r*(1+$rough*0.6*[Math]::Sin($i*1.7))
    DsDisc $c ($cx+[Math]::Cos($a)*$rr*0.82) ($cy+[Math]::Sin($a)*$rr*0.82) (0.7+$rough) $v }
}
function Get-DSCrop { param($c,[int]$x,[int]$y,[int]$W,[int]$H)
  $o = New-DS $W $H
  for ($j=0;$j -lt $H;$j++){for($i=0;$i -lt $W;$i++){ $v=Get-DS $c ($x+$i) ($y+$j); if($v -ge 0){ Set-DS $o $i $j $v } }}
  return $o }
function DsVeins { param($c,[int]$v,[int]$count,[double]$len,[int]$x0=0,[int]$y0=0,[int]$x1=-1,[int]$y1=-1,[double]$branch=0.5)
  if ($x1 -lt 0) { $x1=$c.W-1 }; if ($y1 -lt 0) { $y1=$c.H-1 }
  for ($k=0; $k -lt $count; $k++) {
    $x=[double](DsRandR $x0 $x1); $y=[double](DsRandR $y0 $y1); $a=(DsRand)*[Math]::PI*2
    for ($s=0; $s -lt $len; $s++) {
      Set-DS $c ([int][Math]::Round($x)) ([int][Math]::Round($y)) $v
      $a += (DsRand - 0.5)*1.5; $x += [Math]::Cos($a); $y += [Math]::Sin($a)
      if (DsChance $branch) { $bx=$x; $by=$y; $ba=$a+(DsRand - 0.5)*2
        for ($t=0;$t -lt 4;$t++){ $bx+=[Math]::Cos($ba); $by+=[Math]::Sin($ba); Set-DS $c ([int][Math]::Round($bx)) ([int][Math]::Round($by)) $v } } } }
}
# crystalline shard helper (used by shard kit, geode cores, grub cargo, bursts)
function DsShard { param($c,[double]$cx,[double]$cy,[double]$h,[double]$w,[int]$dark,[int]$mid,[int]$lite,[int]$core)
  DsPoly $c @($cx,($cy-$h*0.5),($cx+$w*0.5),$cy,$cx,($cy+$h*0.5),($cx-$w*0.5),$cy) $mid
  DsPoly $c @($cx,($cy-$h*0.5),($cx+$w*0.5),$cy,$cx,($cy+$h*0.12)) $lite
  DsPoly $c @($cx,($cy-$h*0.5),($cx-$w*0.5),$cy,$cx,($cy+$h*0.12)) $dark
  DsPoly $c @($cx,($cy-$h*0.22),($cx+$w*0.20),($cy+$h*0.04),$cx,($cy+$h*0.28),($cx-$w*0.20),($cy+$h*0.04)) $core
}
function DsCrack { param($c,[double]$x,[double]$y,[int]$len,[int]$v,[double]$a0=$null)
  if ($null -eq $a0) { $a0=(DsRand)*[Math]::PI*2 }
  for ($k=0; $k -lt 2; $k++) {
    $a=$a0+$k*[Math]::PI + (DsRand - 0.5); $px=$x; $py=$y
    for ($s=0; $s -lt $len; $s++) { Set-DS $c ([int][Math]::Round($px)) ([int][Math]::Round($py)) $v
      $a += (DsRand - 0.5)*1.1; $px += [Math]::Cos($a); $py += [Math]::Sin($a) } }
}

# ---------- 5x7 pixel font (uppercase A-Z, 0-9, limited punctuation) ----------
$script:FONT5x7 = @{
 'A'='.####/#....#/#....#/######/#....#/#....#/#....#'
 'B'='#####/#....#/#....#/######/#....#/#....#/#####'
 'C'='.####/#....#/#..../#..../#..../#....#/.####'
 'D'='####./#...#./#...#./#...#./#...#./#...#./####.'
 'E'='######/#..../#..../####./#..../#..../######'
 'F'='######/#..../#..../####./#..../#..../#....'
 'G'='.####/#....#/#..../#..##/#...#./#....#/.####'
 'H'='#....#/#....#/#....#/######/#....#/#....#/#....#'
 'I'='..##../..##../..##../..##../..##../..##../..##..'
 'J'='..####/....#./....#./....#./#...#./#...#./.##..'
 'K'='#...#./#..#./#.#../##.../#.#../#..#./#...#.'
 'L'='#..../#..../#..../#..../#..../#..../######'
 'M'='#...#./##.##/##.##/#.#.#/#...#./#...#./#...#.'
 'N'='#...#./##..#/#.#.#/#..##/#...#./#...#./#...#.'
 'O'='.####/#....#/#....#/#....#/#....#/#....#/.####'
 'P'='#####/#....#/#....#/#####/#..../#..../#....'
 'Q'='.####/#....#/#....#/#....#/#.#.#/#..#../.##.#'
 'R'='#####/#....#/#....#/#####/#.#../#..#./#...#.'
 'S'='.####/#....#/#..../.###./....#/#....#/.####'
 'T'='######/..##../..##../..##../..##../..##../..##..'
 'U'='#....#/#....#/#....#/#....#/#....#/#....#/.####'
 'V'='#....#/#....#/#....#/#....#/#....#/.#..#./..##.'
 'W'='#...#./#...#./#...#./#.#.#/##.##/##.##/#...#.'
 'X'='#...#./#...#./.#.#../..#../.#.#../#...#./#...#.'
 'Y'='#...#./#...#/.#.#../..#../..#../..#../..#..'
 'Z'='######/....#./...#./..#../.#.../#..../######'
 '0'='.####/#...##/#..#.#/#.#.##/##..#/#...#./.####'
 '1'='..#../.##../.#.#../..#../..#../..#../######'
 '2'='.####/#....#/....#./...#./..#../.#.../######'
 '3'='#####/....#./....#/.###./....#/#....#/#####'
 '4'='...#../..#../.#.#./#..#./######/...#./...#.'
 '5'='######/#..../####./....#/#....#/#....#/.####'
 '6'='..##../.#.../#..../####./#...#./#...#./.##..'
 '7'='######/....#./...#./..#../.#.../.#.../.#....'
 '8'='.####/#....#/#....#/.####./#....#/#....#/.####'
 '9'='.####/#....#/#....#/.#####/....#./...##/..##..'
 ' '='.....#/.....#/.....#/.....#/.....#/.....#/.....#'
 '-'='...../...../...../#####/...../...../...../'
 '.'='...../...../...../...../...../.##../.##../'
 ':'='...../..##./..##./...../..##./..##./...../'
 '!'='..##../..##../..##../..##../..##../...../..##../'
 '/'='....#./....#./...#../..#../.#.../#..../#..../'
 "'"='..##./..##./...../...../...../...../...../'
 '%'=('#...#./#...#./...#./..#../.#.../#...#./#...#.')
}
function DsText { param($c,[string]$text,[int]$x,[int]$y,[int]$v,[int]$scale=1,[int]$spacing=1)
  $cx=$x
  foreach ($ch in $text.ToUpper().ToCharArray()) {
    $key=[string]$ch; if (-not $script:FONT5x7.ContainsKey($key)) { $cx += 6*$scale; continue }
    $rows=$script:FONT5x7[$key].Split('/')
    for ($r=0; $r -lt $rows.Length; $r++) { for ($q=0; $q -lt $rows[$r].Length; $q++) {
      if ($rows[$r][$q] -eq '#') {
        for ($j=0;$j -lt $scale;$j++){for($i=0;$i -lt $scale;$i++){ Set-DS $c ($cx+$q*$scale+$i) ($y+$r*$scale+$j) $v } } } } }
    $cx += (($script:FONT5x7[$key].Split('/')[0].Length) + $spacing) * $scale }
  return $cx }
function New-DSTextCanvas { param([string]$text,[int]$scale=1,[int]$v=11,[int]$pad=2,[int]$bg=-1)
  $len = 0; foreach ($ch in $text.ToUpper().ToCharArray()) { $k=[string]$ch
    if ($script:FONT5x7.ContainsKey($k)) { $len += $script:FONT5x7[$k].Split('/')[0].Length + 1 } else { $len += 6 } }
  $w = [int](($len)*$scale) + $pad*2; $h = 7*$scale + $pad*2
  $c = New-DS $w $h
  if ($bg -ge 0) { DsRect $c 0 0 ($w-1) ($h-1) $bg -Fill }
  [void](DsText $c $text $pad $pad $v $scale)
  return $c }
function DsTextOutline { param($c,[int]$ink) DsSilhouetteOutline $c $ink }
