<#  One-off source fix (kept for the record): flatten nested point-list array
    literals  @(,@(x,y),@(x,y))  ->  @(x,y,x,y)  because this PowerShell build
    mis-parses nested literals that contain expressions. Flat lists are safe.
    Tuple loops ( foreach ($x in @(@(a,b,c), ...)) ) are NOT touched.
    Run:  & tools\pixel-art\fix_nested_points.ps1                                 #>
$ErrorActionPreference = 'Stop'
$ROOT = 'E:\GameDev\ProjectDarkstar'
$backup = Join-Path $ROOT 'tools\pixel-art\backup_pre_flatten'
New-Item -ItemType Directory -Path $backup -Force | Out-Null

function Get-MatchEnd { param([string]$t,[int]$open)
  $d=0; $j=$open
  do { $ch=$t[$j]; if ($ch -eq '(') { $d++ } elseif ($ch -eq ')') { $d-- }; $j++ } while ($j -lt $t.Length -and $d -gt 0)
  return ($j-1) }

function Flatten-Line { param([string]$line)
  $out = New-Object System.Text.StringBuilder
  $i = 0
  while ($i -lt $line.Length) {
    $tail = ''
    if (($i+3) -lt $line.Length) { $tail = $line.Substring($i+1,3) }
    if ($line[$i] -eq '@' -and ($tail -eq '(,@' -or $tail -eq '(@(')) {
      $open = $i+1; $close = Get-MatchEnd $line $open
      if ($close -gt $open) {
        $inner = $line.Substring($open+1, $close-$open-1)
        $parts = @(); $d2 = 0; $cur = New-Object System.Text.StringBuilder
        foreach ($ch in $inner.ToCharArray()) {
          if ($ch -eq '(') { $d2++; [void]$cur.Append($ch) }
          elseif ($ch -eq ')') { $d2--; [void]$cur.Append($ch) }
          elseif ($ch -eq ',' -and $d2 -eq 0) { $parts += $cur.ToString(); $cur = New-Object System.Text.StringBuilder }
          else { [void]$cur.Append($ch) } }
        $parts += $cur.ToString()
        $parts = @($parts | Where-Object { $_.Trim() -ne '' })   # the ',@(' idiom leaves a leading empty part
        $allPairs = $true
        foreach ($p in $parts) { $p2 = $p.Trim()
          if (-not ($p2.StartsWith('@(') -and $p2.EndsWith(')'))) { $allPairs = $false; break } }
        if ($allPairs -and $parts.Count -ge 2) {
          $flat = @()
          foreach ($p in $parts) { $p2 = $p.Trim(); $flat += $p2.Substring(2, $p2.Length-3) }
          [void]$out.Append('@(' + ($flat -join ',') + ')')
          $i = $close + 1
          continue } } }
    [void]$out.Append($line[$i]); $i++
  }
  return $out.ToString()
}

$changed = @()
foreach ($f in (Get-ChildItem (Join-Path $ROOT 'tools\pixel-art\src') -Recurse -Filter '*.ps1')) {
  $lines = Get-Content $f.FullName
  $new = @(); $touch = $false
  foreach ($ln in $lines) {
    if ($ln -match 'foreach\s*\(\s*\$\w+\s+in') { $new += $ln; continue }
    $flat = Flatten-Line $ln
    if ($flat -ne $ln) { $touch = $true }
    $new += $flat }
  if ($touch) {
    Copy-Item $f.FullName (Join-Path $backup $f.Name) -Force
    Set-Content -Path $f.FullName -Value $new -Encoding UTF8
    $changed += $f.Name } }
"rewritten: " + ($changed -join ', ')

# parse-check every script so a bad edit fails loudly here, not mid-render
$errsTotal = 0
foreach ($f in (Get-ChildItem (Join-Path $ROOT 'tools\pixel-art') -Recurse -Filter '*.ps1')) {
  $toks = $null; $errs = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$toks, [ref]$errs)
  if ($null -ne $errs -and $errs.Count) { $errsTotal += $errs.Count
    foreach ($e in $errs) { "PARSE $($f.Name): line $($e.Extent.StartLineNumber): $($e.Message.Split("`n")[0])" } } }
"parse errors: $errsTotal"
