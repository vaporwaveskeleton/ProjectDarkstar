<#
  DARKSTAR asset pipeline driver  (tools/pixel-art/run_all.ps1)
  ------------------------------------------------------------------
  Regenerates every kit deterministically, lints palette locks, writes:
    tools/pixel-art/out/<kit>/*.png                 (scratch)
    assets/sprites/generated/<kit>/*.png            (canonical, engine-consumed)
    assets/sprites/SPRITE_MANIFEST.csv              (one row per asset)
    docs/02-art/screens/kit_<kit>.png               (contact sheets for art QA)
  Usage:  pwsh -File tools\pixel-art\run_all.ps1 [-Kits vigil,grub] [-NoSheet]
#>
param([string[]]$Kits = @(), [switch]$NoSheet, [switch]$Quiet)

$ErrorActionPreference = 'Stop'
$ROOT  = 'E:\GameDev\ProjectDarkstar'
$OUT   = Join-Path $ROOT 'tools\pixel-art\out'
$GEN   = Join-Path $ROOT 'assets\sprites\generated'
$SCREENS = Join-Path $ROOT 'docs\02-art\screens'
. (Join-Path $ROOT 'tools\pixel-art\src\ds_pixcore.ps1')
. (Join-Path $ROOT 'tools\pixel-art\src\ds_pixextras.ps1')
# NOTE: dot-source in the script scope (ForEach-Object would create a child scope and drop the functions)
foreach ($f in (Get-ChildItem (Join-Path $ROOT 'tools\pixel-art\src\kits') -Filter '*.ps1')) { . $f.FullName }

# kit -> build function (add new kits here)
$BUILDS = [ordered]@{
  vigil     = 'Build-KitVigil'
  grub      = 'Build-KitGrub'
  acolyte   = 'Build-KitAcolyte'
  deceiver  = 'Build-KitDeceiver'
  penitent  = 'Build-KitPenitent'
  geode     = 'Build-KitGeode'
  sepulchre = 'Build-KitSepulchre'
  shard     = 'Build-KitShard'
  entity    = 'Build-KitEntity'
  fx        = 'Build-KitFx'
  ui        = 'Build-KitUi'
  compass   = 'Build-KitCompass'
  hub       = 'Build-KitHub'
  matron    = 'Build-KitMatron'
  listener  = 'Build-KitListener'
  deacon    = 'Build-KitDeacon'
}
$want = if ($Kits) { $Kits -split ',' } else { $BUILDS.Keys }
$manifest = New-Object System.Collections.ArrayList
$lintLog  = New-Object System.Collections.ArrayList
$total = 0; $t0 = Get-Date

foreach ($kit in $want) {
  $fn = $BUILDS[$kit]
  if (-not $fn -or -not (Test-Path "function:$fn")) { continue }
  # deterministic seed per kit so re-runs are byte-stable
  DsSeed ([Math]::Abs(($kit.GetHashCode() * 2654435761) -band 0x7FFFFFFF) % 2000000000 + 7)
  $items = & $fn
  $lock = $script:PALJ.kit_locks.$kit
  $kitFiles = @()
  foreach ($it in $items) {
    if ($null -eq $it.c) { continue }
    $name = $it.name
    if ($name -notlike "ds_$kit*" -and $name -notlike "ds_${kit}_*") {
      $lintLog.Add("NAME  $kit : $name does not match ds_<kit>_ prefix") | Out-Null }
    # colour lint (composite previews may exceed the per-sprite limit: they combine kits on purpose)
    $cols = @{}; foreach ($p in $it.c.Px) { if ($p -ge 0) { $cols[[int]$p] = 1 } }
    if ($cols.Count -gt 10 -and $name -notlike '*ASSEMBLED*') { $lintLog.Add("COLOUR $name : $($cols.Count) colours (>10)") | Out-Null }
    if ($lock -and $name -notlike '*ASSEMBLED*') { foreach ($k in $cols.Keys) { if ($lock -notcontains $k) {
      $lintLog.Add("LOCK   $name : $($script:PALNAMES[$k]) not allowed for kit $kit") | Out-Null } } }
    # faction rules (ART_BIBLE palette law 1 + exceptions in darkstar_palette.json faction_exceptions)
    # ASSEMBLED_* are composite previews: they blit parts that were linted on their own, so they inherit
    # the parts' exceptions. They are still checked against GAS-5, which is never allowed on Choir or entity.
    $isC = ($kit -in @('grub','acolyte','deceiver','penitent','matron','listener','deacon','herald','entity'))
    $isComp = ($name -like '*ASSEMBLED*')
    $gas = @($cols.Keys | Where-Object { $_ -ge 24 -and $_ -le 29 })
    $allow = $script:PALJ.faction_exceptions.allowed
    if ($isC -and $gas.Count -and -not $isComp) {
      $ok = @($allow.$name)
      foreach ($g in $gas) { if ($ok -notcontains [int]$g) {
        $lintLog.Add("FACTION $name : $($script:PALNAMES[$g]) on a Choir/entity part not whitelisted in faction_exceptions") | Out-Null } } }
    if ($isC -and $isComp) {
      $okAll = @(); foreach ($pn in $allow.PSObject.Properties.Name) { $okAll += @($allow.$pn) }
      foreach ($g in $gas) { if ($okAll -notcontains [int]$g) {
        $lintLog.Add("FACTION $name : composite carries $($script:PALNAMES[$g]), which no component part is allowed") | Out-Null } } }
    if ($isC -and ($gas -contains 29)) {
      $lintLog.Add("FACTION $name : GAS-5 (lantern core) is never allowed on Choir or entity") | Out-Null }
    if ($kit -eq 'vigil' -and ($cols.Keys | Where-Object { $_ -ge 12 -and $_ -le 17 })) {
      $lintLog.Add("FACTION $name : CHOIR colour on a player asset") | Out-Null }

    $scratch = Join-Path (Join-Path $OUT $kit) "$name.png"
    $canon   = Join-Path (Join-Path $GEN $kit) "$name.png"
    Save-DSPng $it.c $scratch; Save-DSPng $it.c $canon
    $kitFiles += $canon
    [void]$manifest.Add([pscustomobject]@{
      id=$name; kit=$kit; part=$it.part; w=$it.c.W; h=$it.c.H
      frames=$(if($it.frames){$it.frames}else{1}); colours=$cols.Count
      palette_lock=$(if($lock){"$($lock -join ',')"}else{'kit-default'})
      path="assets/sprites/generated/$kit/$name.png"; status='generated'; note=$it.note })
    $total++
  }
  if (-not $NoSheet -and $kitFiles.Count) {
    Save-DSContactSheet -Files $kitFiles -OutPath (Join-Path $SCREENS "kit_$kit.png") -Cell 96 -Cols 6 -Scale 2
  }
  if (-not $Quiet) { "{0,-10} {1,3} assets" -f $kit, $kitFiles.Count }
}

# manifest (sorted by kit then part then name)
$mpath = Join-Path $ROOT 'assets\sprites\SPRITE_MANIFEST.csv'
$manifest | Sort-Object kit, part, id | Export-Csv -NoTypeInformation -Path $mpath -Encoding UTF8
"TOTAL  $total assets -> $mpath"
if ($lintLog.Count) { "LINT ($($lintLog.Count)):"; $lintLog | ForEach-Object { "  $_" } } else { "LINT clean" }
"contact sheets -> docs/02-art/screens/ ; elapsed $([int]((Get-Date)-$t0).TotalSeconds)s"
