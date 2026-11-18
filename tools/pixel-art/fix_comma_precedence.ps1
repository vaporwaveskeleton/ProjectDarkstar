<#  One-off source fix (kept for the record): parenthesise array-literal elements.

    Why: this PowerShell build binds the binary comma tighter than + and -, so
      @(x, x+4, x+2)      parses as      ((x, x) + (4, x, 2))
    i.e. the elements are NOT what the source reads like. With integers the
    result is a silent array concatenation (wrong geometry, no error); with a
    `*` in the element it throws "Object[] does not contain a method named
    op_Multiply". Flattening @(,@(a,b),@(c,d)) -> @(a,b,c,d) is only safe when
    every element is parenthesised. This script adds the missing parentheses:
      @(x, x+4, x+2)   ->   @(x, (x+4), (x+2))
    Idempotent, and element-safe: already-parenthesised elements are untouched,
    and nested literals / index expressions / strings are never re-split.
    Run:  & tools\pixel-art\fix_comma_precedence.ps1                            #>
$ErrorActionPreference = 'Stop'
$ROOT = 'E:\GameDev\ProjectDarkstar'
$backup = Join-Path $ROOT 'tools\pixel-art\backup_pre_comma_fix'
New-Item -ItemType Directory -Path $backup -Force | Out-Null

function Get-MatchEnd { param([string]$t,[int]$open)   # index of ')' matching '(' at $open
  $d = 0; $j = $open; $inS = $false; $inD = $false
  while ($j -lt $t.Length) {
    $ch = $t[$j]
    if ($inS) { if ($ch -eq "'") { $inS = $false } }
    elseif ($inD) { if ($ch -eq '"') { $inD = $false } }
    elseif ($ch -eq "'") { $inS = $true }
    elseif ($ch -eq '"') { $inD = $true }
    elseif ($ch -eq '(') { $d++ }
    elseif ($ch -eq ')') { $d--; if ($d -eq 0) { return $j } }
    $j++ }
  return -1 }

function Split-TopLevel { param([string]$inner)   # split on commas outside any bracket/quote
  $parts = @(); $d = 0; $cur = New-Object System.Text.StringBuilder
  $inS = $false; $inD = $false
  foreach ($ch in $inner.ToCharArray()) {
    if ($inS) { [void]$cur.Append($ch); if ($ch -eq "'") { $inS = $false }; continue }
    if ($inD) { [void]$cur.Append($ch); if ($ch -eq '"') { $inD = $false }; continue }
    if ($ch -eq "'") { $inS = $true; [void]$cur.Append($ch); continue }
    if ($ch -eq '"') { $inD = $true; [void]$cur.Append($ch); continue }
    if ($ch -in '(', '[', '{') { $d++ } elseif ($ch -in ')', ']', '}') { $d-- }
    if ($ch -eq ',' -and $d -eq 0) { $parts += $cur.ToString(); $cur = New-Object System.Text.StringBuilder }
    else { [void]$cur.Append($ch) } }
  $parts += $cur.ToString()
  return ,$parts }

function Test-NeedsParens { param([string]$e)
  # element needs parens when it contains a top-level + or - (comma binds tighter than these)
  $d = 0; $inS = $false; $inD = $false
  for ($k = 0; $k -lt $e.Length; $k++) {
    $ch = $e[$k]
    if ($inS) { if ($ch -eq "'") { $inS = $false }; continue }
    if ($inD) { if ($ch -eq '"') { $inD = $false }; continue }
    if ($ch -eq "'") { $inS = $true; continue }
    if ($ch -eq '"') { $inD = $true; continue }
    if ($ch -in '(', '[', '{') { $d++ } elseif ($ch -in ')', ']', '}') { $d-- }
    elseif ($ch -eq '/' -or $ch -eq '*') { if ($d -eq 0 -and $k -gt 0 -and $e[$k-1] -eq '/') { break } }
    elseif (($ch -eq '+' -or $ch -eq '-') -and $d -eq 0) {
      # skip unary use: at start, or after another operator
      $prev = if ($k -gt 0) { $e[$k-1] } else { ' ' }
      if ($prev -notin ' ', '(', ',', '+', '-', '*', '/', '%') { return $true } } }
  return $false }

function Fix-Line { param([string]$line)
  $out = New-Object System.Text.StringBuilder
  $i = 0
  while ($i -lt $line.Length) {
    $ch = $line[$i]
    if ($ch -eq '@' -and (($i + 1) -lt $line.Length) -and ($line[$i+1] -eq '(')) {
      $open = $i + 1; $close = Get-MatchEnd $line $open
      if ($close -gt $open) {
        $inner = $line.Substring($open + 1, $close - $open - 1)
        $parts = Split-TopLevel $inner
        $fixed = @()
        foreach ($p in $parts) {
          $t = $p.Trim()
          if ($t -eq '') { $fixed += $p; continue }
          if (Test-NeedsParens $t) { $fixed += '(' + $t + ')' } else { $fixed += $p } }
        [void]$out.Append('@(' + ($fixed -join ',') + ')')
        $i = $close + 1; continue } }
    if ($ch -eq '#' -and -not $inComment) { }   # comments carry no literals we need to touch
    [void]$out.Append($ch); $i++ }
  return $out.ToString() }

$changed = @()
foreach ($f in (Get-ChildItem (Join-Path $ROOT 'tools\pixel-art\src') -Recurse -Filter '*.ps1')) {
  $lines = Get-Content $f.FullName
  $new = @(); $touch = $false
  foreach ($ln in $lines) {
    if ($ln.TrimStart().StartsWith('#')) { $new += $ln; continue }
    $fixedLine = if ($ln -match '@\(') { Fix-Line $ln } else { $ln }
    if ($fixedLine -ne $ln) { $touch = $true }
    $new += $fixedLine }
  if ($touch) {
    Copy-Item $f.FullName (Join-Path $backup $f.Name) -Force
    Set-Content -Path $f.FullName -Value $new -Encoding UTF8
    $changed += $f.Name } }
"rewritten: " + ($changed -join ', ')

# parse-check + a runtime probe of the precedence rule so a bad edit fails here, not mid-render
$errsTotal = 0
foreach ($f in (Get-ChildItem (Join-Path $ROOT 'tools\pixel-art\src') -Recurse -Filter '*.ps1')) {
  $toks = $null; $errs = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$toks, [ref]$errs)
  if ($null -ne $errs -and $errs.Count) { $errsTotal += $errs.Count
    foreach ($e in $errs) { "PARSE $($f.Name): line $($e.Extent.StartLineNumber): $($e.Message.Split("`n")[0])" } } }
"parse errors: $errsTotal"
$probe = @(1, (1 + 4), (1 + 2))
"probe @(1,(1+4),(1+2)) -> " + ($probe -join ',') + "   (expect 1,5,3)"
