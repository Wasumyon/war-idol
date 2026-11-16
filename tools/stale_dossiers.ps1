# Lists dossier entries whose `source:` files have a later git commit than the entry itself.
# Run after a canon session (docs/dossier_spec.md section 10). Each hit is an entry to reread,
# often still fine; it is not an automatic rewrite.
#
#   powershell -File tools/stale_dossiers.ps1

$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root 'vn/dossier/entries'

function Get-LastCommit([string]$path) {
    $t = git -C $root log -1 --format=%ct -- $path 2>$null
    if ($t) { return [int64]$t } else { return 0 }
}

$stale = 0
$checked = 0
foreach ($file in Get-ChildItem -Path $dir -Filter '*.txt' | Where-Object { $_.Name -notlike '_*' }) {
    $checked++
    $rel = "vn/dossier/entries/$($file.Name)"
    $entryTime = Get-LastCommit $rel
    if ($entryTime -eq 0) { continue }   # not committed yet: nothing to be stale against
    $sources = @()
    foreach ($line in Get-Content -Path $file.FullName -Encoding UTF8) {
        if ($line.Trim() -eq '') { break }   # headers end at the first blank line
        if ($line -match '^source:\s*(.+)$') {
            $sources += $Matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
    }
    $newer = @()
    foreach ($src in $sources) {
        $t = Get-LastCommit $src
        if ($t -gt $entryTime) { $newer += $src }
    }
    if ($newer.Count -gt 0) {
        $stale++
        Write-Host ("{0}: newer sources: {1}" -f $file.BaseName, ($newer -join ', '))
    }
}
Write-Host ("{0} of {1} entries have sources newer than the entry." -f $stale, $checked)
