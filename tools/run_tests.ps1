# Runs every headless test scene in <game project>/tests/*.tscn and prints one summary line each.
# A test fails if it exits non-zero, times out, or prints "FAIL" or "N failure(s)" with N > 0.
# Last, it runs tools/stale_names.ps1 (retired names must not come back) and counts it as a test.
#
#   powershell -File tools/run_tests.ps1
#   powershell -File tools/run_tests.ps1 -Godot "C:\path\Godot_console.exe" -TimeoutSec 180
#
# The game project is game/ (the folder with project.godot).
param(
	[string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "C:\Users\9meac\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" }),
	[int]$TimeoutSec = 120
)

$root = Split-Path -Parent $PSScriptRoot
$project = foreach ($name in "game") {
	if (Test-Path (Join-Path $root "$name\project.godot")) { Join-Path $root $name; break }
}
if (-not $project) { Write-Error "No game project found (game/)."; exit 2 }
if (-not (Test-Path $Godot)) { Write-Error "Godot console exe not found: $Godot (set -Godot or `$env:GODOT)"; exit 2 }

$failed = 0
$tests = Get-ChildItem (Join-Path $project "tests") -Filter *.tscn | Sort-Object Name
foreach ($t in $tests) {
	$out = Join-Path $env:TEMP ("test_" + $t.BaseName + ".log")
	$err = $out + ".err"
	$p = Start-Process -FilePath $Godot -ArgumentList @("--headless", "--path", $project, "res://tests/$($t.Name)") `
		-RedirectStandardOutput $out -RedirectStandardError $err -PassThru -NoNewWindow
	$null = $p.Handle
	$finished = $p.WaitForExit($TimeoutSec * 1000)
	if ($finished) { $p.WaitForExit() }
	if (-not $finished) { $p.Kill(); $why = "TIMEOUT after ${TimeoutSec}s" }
	else {
		$text = (Get-Content $out -Raw -ErrorAction SilentlyContinue) + (Get-Content $err -Raw -ErrorAction SilentlyContinue)
		$why = $null
		if ($p.ExitCode -ne 0) { $why = "exit code $($p.ExitCode)" }
		elseif ($text -match "(?m)^FAIL") { $why = "a check printed FAIL" }
		elseif ($text -match "(?i)(\d+) failure\(s\)?" -and [int]$Matches[1] -gt 0) { $why = "$($Matches[1]) failures" }
		elseif ($text -match "SCRIPT ERROR|Parse Error") { $why = "script error in output" }
	}
	if ($why) { $failed++; Write-Host ("FAIL  {0}  ({1})  log: {2}" -f $t.Name, $why, $out) }
	else { Write-Host ("ok    {0}" -f $t.Name) }
}
# Not a Godot test: fails if a name retired by the restructure is back in game/ or the docs.
$names = & powershell -NoProfile -File (Join-Path $PSScriptRoot "stale_names.ps1")
if ($LASTEXITCODE -ne 0) { $failed++; Write-Host "FAIL  stale_names.ps1"; $names | ForEach-Object { Write-Host $_ } }
else { Write-Host "ok    stale_names.ps1" }
Write-Host ("{0} test(s), {1} failed" -f ($tests.Count + 1), $failed)
exit ([int]($failed -gt 0))
