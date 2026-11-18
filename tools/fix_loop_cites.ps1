# One-shot citation repair for LOOP-001: replaces SYS-001 section references that
# do not exist in SYS-001 with the legal section that actually holds the row.
# The section sign is built from its code point so this file stays pure ASCII.
$ErrorActionPreference = 'Stop'
$p = 'E:\GameDev\ProjectDarkstar\docs\01-design\ROGUELIKE_LOOP_AND_LANTERN_TREE.md'
$s = [char]0x00A7
$enc = New-Object System.Text.UTF8Encoding($false)
$t = [System.IO.File]::ReadAllText($p, $enc)
$before = $t

$pairs = @(
  ,@("SYS-001 ${s}6.2)",                                   "SYS-001 ${s}6)")
  ,@("SYS-001 ${s}6.6)",                                   "SYS-001 ${s}6)")
  ,@("SYS-001 ${s}6.5)",                                   "SYS-001 ${s}7.2)")
  ,@("(SYS-001 ${s}4.3)",                                  "(SYS-001 ${s}6)")
  ,@("SYS-001 ${s}3.4",                                    "SYS-001 ${s}3")
  ,@("SYS-001 ${s}3.3",                                    "SYS-001 ${s}3")
  ,@("(SYS-001 ${s}3.5)",                                  "(SYS-001 ${s}3)")
  ,@("(SYS-001 ${s}3.2)",                                  "(SYS-001 ${s}3)")
  ,@("(SYS-001 ${s}5)",                                    "(SYS-001 ${s}5.1)")
  ,@("thread snap before it does (SYS-001 ${s}2.2)",       "thread snap before it does (SYS-001 ${s}2)")
  ,@("at any Warp (SYS-001 ${s}1.4, ${s}1.5)",             "at any Warp (SYS-001 ${s}1.1, ${s}1.5)")
  ,@("Shard magnet +20 px (SYS-001 ${s}1.3 ceiling",       "Shard magnet +20 px (SYS-001 ${s}1.4 ceiling")
  ,@("Magnet +25 px (SYS-001 ${s}1.3, 96 px base)",        "Magnet +25 px (SYS-001 ${s}1.4, 96 px base)")
  ,@("Charges curve harder (SYS-001 ${s}1.3 turn",         "Charges curve harder (SYS-001 ${s}1.4 turn")
  ,@("Charge magazine +1 (SYS-001 ${s}1.3 cap applies)",   "Charge magazine +1 (SYS-001 ${s}1.4 cap applies)")
  ,@("after throwing a Charge (SYS-001 ${s}3.1)",          "after throwing a Charge (SYS-001 ${s}3)")
  ,@("+1 Salt Glass mine (SYS-001 ${s}3.1)",               '+1 Salt Glass mine (no SYS-001 row yet; this doc defines it, see [^gap])')
)

$report = @()
foreach ($pair in $pairs) {
  $n = ([regex]::Matches($t, [regex]::Escape($pair[0]))).Count
  if ($n -eq 0) { $report += "MISS  $($pair[0])" }
  else { $t = $t.Replace($pair[0], $pair[1]); $report += "OK x$n  $($pair[0]) -> $($pair[1])" }
}

if ($t -ne $before) { [System.IO.File]::WriteAllText($p, $t, $enc) }
$report | ForEach-Object { Write-Output $_ }

# Verify no illegal SYS-001 section references remain.
$legal = '^0$|^1$|^1\.[1-5]$|^2$|^2\.1$|^2\.2$|^3$|^3\.1$|^4$|^5$|^5\.1$|^5\.2$|^6$|^7$|^7\.[1-4]$|^8$|^9$|^10$|^11$'
$bad = @()
foreach ($m in [regex]::Matches($t, "SYS-001 ${s}([0-9]+(?:\.[0-9]+)?)")) {
  if ($m.Groups[1].Value -notmatch $legal) { $bad += $m.Value }
}
Write-Output ("ILLEGAL REMAINING: " + $bad.Count)
$bad | ForEach-Object { Write-Output $_ }
Write-Output ("BYTES: " + (Get-Item $p).Length)
