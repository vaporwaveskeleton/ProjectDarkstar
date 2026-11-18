# Two follow-up corrections: delete the stale Salt Glass clause from the LOOP-001 gap
# footnote, and put the paragraph in section 3.4 into past tense now that both items are decided.
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$path = 'E:\GameDev\ProjectDarkstar\docs\01-design\ROGUELIKE_LOOP_AND_LANTERN_TREE.md'
$t = [System.IO.File]::ReadAllText($path, $enc)
$s = [string][char]0x00A7

# 1. the dropped sigil must not still be cited as owed work
$old1 = 'SIG-W-03 hands the player a carried Salt Glass mine'
$i = $t.IndexOf($old1)
if ($i -lt 0) { Write-Output 'skip  salt clause already gone' }
else {
  $start = $t.LastIndexOf('; ', $i)
  $close = $t.IndexOf(')', $i)
  if ($start -lt 0 -or $close -lt $i) { throw 'could not bound the salt clause' }
  $clause = $t.Substring($start, $close - $start + 1)
  Write-Output ('deleting: ' + $clause)
  $t = $t.Remove($start, $close - $start + 1)
}

# 2. the paragraph is history now, not an open question
$old2 = 'Two of these disagree with their own node row in ' + $s + '3.3 and need a decision, tracked here rather than papered over:'
if (-not $t.Contains($old2)) { Write-Output 'skip  conflict paragraph already reworded' }
else {
  $new2 = 'Two of these disagreed with their own node row in ' + $s + '3.3 and went to the owner as questions, tracked here rather than papered over:'
  $t = $t.Replace($old2, $new2)
  Write-Output 'ok    conflict paragraph reworded to past tense'
}

[System.IO.File]::WriteAllText($path, $t, $enc)
Write-Output ('bytes=' + (Get-Item $path).Length)

# verify both files read back clean
Select-String -Path $path -Pattern 'Salt Glass','salt ward','Salt Pouch','0\.8 s' | ForEach-Object {
  'L' + $_.LineNumber + ' | ' + $_.Line.Substring(0, [Math]::Min(150, $_.Line.Length))
}
