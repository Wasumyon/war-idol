# Builds one browser demo (docs/demo_spec.md) from game/ into build/demo/<name>/ (git-ignored):
#   build/demo/<name>/web/                         the exported files (index.html, .pck, .wasm, ...)
#   build/demo/<name>/war-idol-<name>-demo-<date>-<commit>.zip   the same files, ready for itch.io
#
#   powershell -File tools/export_demo.ps1 tunnel
#   powershell -File tools/export_demo.ps1 tunnel -Godot "C:\path\Godot_console.exe"
#
# Uses the export preset demo_<name> in game/export_presets.cfg. Before exporting it writes the
# build stamp ("<date> <short commit>", "+changes" if game/ has uncommitted edits) to
# game/demo/build_stamp.txt, which the title screen shows; the file is removed afterwards.
# After exporting it lists what went into the pack and fails if story text, dossier entries,
# Main, the debug panel or the tests got in.
# Needs Godot's web export templates; if they are missing it says how to install them and stops.
param(
	[Parameter(Mandatory = $true, Position = 0)][string]$Name,
	[string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "C:\Users\9meac\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" })
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$game = Join-Path $root "game"
$preset = "demo_$Name"
if (-not (Test-Path $Godot)) { Write-Error "Godot console exe not found: $Godot (set -Godot or `$env:GODOT)"; exit 2 }
$presets = Get-Content (Join-Path $game "export_presets.cfg") -Raw
if ($presets -notmatch "(?m)^name=`"$preset`"") { Write-Error "No export preset named $preset in game/export_presets.cfg"; exit 2 }

# Web export templates for this exact Godot version (the demos export without threads).
$version = (& $Godot --version | Select-Object -First 1).Trim()   # e.g. 4.7.2.stable.official.ed1daf0bf
$templateDir = Join-Path $env:APPDATA ("Godot\export_templates\" + (($version -split "\.")[0..3] -join "."))
$template = Join-Path $templateDir "web_nothreads_release.zip"
if (-not (Test-Path $template)) {
	Write-Host "Godot's web export templates are not installed (looked for $template)."
	Write-Host "Install them once: open the game in Godot, Editor > Manage Export Templates > Download and Install."
	Write-Host "Then run this script again."
	exit 3
}

# Build stamp.
Push-Location $root
try {
	$commit = (git rev-parse --short HEAD).Trim()
	$dirty = (git status --porcelain -- game) -ne $null
} finally { Pop-Location }
$date = Get-Date -Format "yyyy-MM-dd"
$stamp = "$date $commit" + $(if ($dirty) { " +changes" } else { "" })
$stampFile = Join-Path $game "demo\build_stamp.txt"

$out = Join-Path $root "build\demo\$Name"
$web = Join-Path $out "web"
if (Test-Path $web) { Remove-Item -Recurse -Force $web }
New-Item -ItemType Directory -Force $web | Out-Null
$log = Join-Path $out "export.log"
$listZip = Join-Path $out "pack_contents.zip"

Set-Content -Path $stampFile -Value $stamp -Encoding ascii -NoNewline
try {
	Write-Host "Exporting $preset ($stamp) ..."
	& $Godot --headless --path $game --export-release $preset (Join-Path $web "index.html") *> $log
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $web "index.pck"))) {
		Write-Error "Export failed; see $log"; exit 1
	}
	# The same preset as a zip pack, only to list what is inside the .pck.
	if (Test-Path $listZip) { Remove-Item -Force $listZip }
	& $Godot --headless --path $game --export-pack $preset $listZip *>> $log
} finally {
	Remove-Item -Force $stampFile -ErrorAction SilentlyContinue
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead($listZip)
$files = $z.Entries | ForEach-Object { $_.FullName }
$z.Dispose()
Remove-Item -Force $listZip
$banned = $files | Where-Object { $_ -match "^(story|dossier|ui|tests|hub|calendar)/|^main/main\.|^sandbox/" }
if ($banned) {
	Write-Host "These must not be in a demo:"; $banned | ForEach-Object { Write-Host "  $_" }
	Write-Error "Pack check failed"; exit 1
}
$files | Set-Content (Join-Path $out "pack_contents.txt")

$zipName = "war-idol-$Name-demo-$date-$commit.zip"
Get-ChildItem $out -Filter "war-idol-$Name-demo-*.zip" | Remove-Item -Force
Compress-Archive -Path (Join-Path $web "*") -DestinationPath (Join-Path $out $zipName)
Write-Host ("Pack: {0} files, none from story/dossier/Main/debug (list: build\demo\{1}\pack_contents.txt)" -f $files.Count, $Name)
Write-Host "Built build\demo\$Name\$zipName"
Write-Host "Try it:  python -m http.server 8000 --directory `"$web`"   then open http://localhost:8000"
