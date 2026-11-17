# Fails if a name retired by the 2026-11-16 restructure comes back in game/ or the live docs.
# Run by tools/run_tests.ps1; can also be run alone:
#
#   powershell -File tools/stale_names.ps1
#
# To retire another name, add a line to $code (checked in game/) or $docs (checked in the docs).
# Not checked: STATUS.md (it lists the retired names), docs/tunnel/ and docs/tunnel_port_plan.md
# (they describe the old tunnel project), _archive/, sandbox/, tunnel/.

$root = Split-Path -Parent $PSScriptRoot

# pattern = what it was replaced by. Matching is case-sensitive.
$both = [ordered]@{
	'\bMainGame\b'        = 'Main'
	'main_game\.'         = 'main.gd / main.tscn'
	'maingame_spec'       = 'main_spec.md'
	'vn_game_design'      = 'game_design.md'
	'campaign_phone'      = 'phone.gd'
	'runner_placeholder'  = 'deleted'
	'HANDOVER'            = 'STATUS.md and AGENTS.md'
	'(^|[^A-Za-z_/])(car|vn)/' = 'sandbox/ or game/'
}
$code = [ordered]@{
	'res://(scenes|scripts|art|img|sfx|runner|stealth|phone|opener|first_shot)/' = 'res://story/, res://minigames/, res://assets/, res://ui/'
	'slice\.(gd|tscn)'    = 'run.gd / run.tscn'
	'(^|[^A-Za-z_"''])Game\.[a-z_]' = 'GameState.'
}

$codeFiles = Get-ChildItem (Join-Path $root "game") -Recurse -File -Include *.gd, *.tscn, *.tres, *.txt, *.godot, *.cfg |
	Where-Object { $_.FullName -notmatch '\\\.godot\\' }
$docFiles = @(Get-Item (Join-Path $root "CLAUDE.md"), (Join-Path $root "AGENTS.md"), (Join-Path $root "README.md")) +
	@(Get-ChildItem (Join-Path $root "docs") -Recurse -File -Filter *.md |
		Where-Object { $_.FullName -notmatch '\\docs\\tunnel\\' -and $_.Name -ne 'tunnel_port_plan.md' })

$hits = 0
function Check($files, $patterns) {
	foreach ($p in $patterns.Keys) {
		foreach ($m in ($files | Select-String -Pattern $p -CaseSensitive)) {
			$script:hits++
			$rel = $m.Path.Substring($root.Length + 1)
			Write-Host ("  {0}:{1}  retired name (now: {2})  {3}" -f $rel, $m.LineNumber, $patterns[$p], $m.Line.Trim().Substring(0, [Math]::Min(100, $m.Line.Trim().Length)))
		}
	}
}
Check $codeFiles $both
Check $codeFiles $code
Check $docFiles $both

if ($hits) { Write-Host ("{0} retired name(s) found" -f $hits); exit 1 }
Write-Host "no retired names"
exit 0
