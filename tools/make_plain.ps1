# tools/make_plain.ps1
#
# Generates plain-text reading copies of every VN scene. Strips every directive and
# comment, keeps the prose WITH its inline markup (**bold** and *italic* / _italic_ survive
# into the copy), expands the cast shorthand to display names, quotes the dialogue, and renders
# a page break as a bare "---" with a blank line above it and none below, so the structure
# survives and the file still reads correctly as Markdown.
#
#   powershell -File tools\make_plain.ps1
#
#   source : vn/scenes/NN_*.txt      (files starting "_" are skipped)
#   output : vn/scenes/_read_NN_*.txt
#
# A reading copy is a diagnostic as much as a convenience: if a scene reads as
# fragments without the art, the scene is under-written.

$root   = Split-Path -Parent $PSScriptRoot
$scnDir = Join-Path $root 'vn\scenes'

function Convert-Scene([string]$src, [string]$dst) {
	$lines = [IO.File]::ReadAllLines($src)

	# --- collect the cast shorthand ("@ cast C=Chip, P=Player, K=Captain Keno") ---
	$cast = @{}
	foreach ($l in $lines) {
		$t = $l.Trim()
		if (-not $t.StartsWith('@')) { continue }
		$b = $t.Substring(1).Trim()
		if (-not ($b -eq 'cast' -or $b.StartsWith('cast '))) { continue }
		foreach ($nm in ($b.Substring(4) -split ',')) {
			$n = $nm.Trim()
			if ($n -eq '') { continue }
			$eq = $n.IndexOf('=')
			if ($eq -gt 0) { $cast[$n.Substring(0, $eq).Trim()] = $n.Substring($eq + 1).Trim() }
			else { $cast[$n] = $n }
		}
	}

	$out   = New-Object System.Collections.Generic.List[string]
	$blank = $true
	foreach ($raw in $lines) {
		$t = $raw.TrimEnd()
		$k = $t.Trim()

		# a gap is DEFERRED, not emitted here: if the next real line is a page break the
		# gap is swallowed, and only a gap between two lines of prose survives
		if ($k -eq '') { $blank = $true; continue }

		# a page break survives as a bare rule with a blank line ABOVE it and none
		# below. Markdown reads "prose / ---" as a setext heading; the blank line above
		# is what makes it a rule rather than a caption.
		if ($k -eq '---' -or ($k.Length -ge 3 -and $k.Replace('-', '') -eq '')) {
			if ($out.Count -gt 0 -and $out[$out.Count - 1] -ne '') { $out.Add('') }
			$out.Add('---'); $blank = $false; continue
		}
		if ($k.StartsWith('@')) {
			$b = $k.Substring(1).Trim()
			if ($b -eq 'page' -or $b -eq 'page off') {
				if ($out.Count -gt 0 -and $out[$out.Count - 1] -ne '') { $out.Add('') }
				$out.Add('---'); $blank = $false
			}
			continue
		}
		if ($k.StartsWith('#') -or $k.StartsWith('==') -or $k.StartsWith('->') -or
		    $k.StartsWith('? ') -or $k.StartsWith('+ ')) { continue }

		# click marks become a space; **bold** / *italic* / _italic_ are KEPT (style guide 11)
		$t = $t.Trim() -replace '\|', ' '
		$t = $t -replace ' {2,}', ' '

		# speaker label -> quoted dialogue, label dropped
		$i = $t.IndexOf(':')
		if ($i -gt 0) {
			$who = $t.Substring(0, $i).Trim()
			if ($cast.ContainsKey($who) -or -not ($who -match '\s')) {
				$body = $t.Substring($i + 1).Trim()
				if (-not $body.StartsWith('"')) { $body = '"' + $body + '"' }
				$t = $body
			}
		}

		if ($blank -and $out.Count -gt 0) { $out.Add('') }
		$blank = $false
		$out.Add($t)
	}

	while ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
	[IO.File]::WriteAllText($dst, (($out -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
	Write-Output ("  {0,-28} {1} lines" -f (Split-Path $dst -Leaf), $out.Count)
}

Write-Output "plain-text reading copies:"
$n = 0
foreach ($f in (Get-ChildItem $scnDir -Filter *.txt | Where-Object { $_.Name -notlike '_*' } | Sort-Object Name)) {
	Convert-Scene $f.FullName (Join-Path $scnDir ("_read_" + $f.Name))
	$n++
}
Write-Output ("done: " + $n + " scene(s)")
