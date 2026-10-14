# Notes/make_flatline.ps1
#
# Regenerates car/vn/sfx/flatline.wav — the monitor sting under the prologue's last
# beat. Generated rather than sourced, so there is no licence to record.
#
#   powershell -File Notes\make_flatline.ps1
#
# The tone TAPERS. A held sine at full scale is a klaxon. This one opens with a
# fraction of a second of full tone and then decays to silence inside a second,
# which is what the beat wants.
#
# Retune by editing the four numbers below; nothing else needs touching.

$gain    = 0.5      # peak amplitude. -6 dBFS, the ceiling to standardise on. History: full
                    # scale (1.0) was a klaxon; 0.13 (-18 dBFS) vanished under the decay.
$freq    = 1000     # Hz
$seconds = 1.3      # total length; the decay is over well before this
$tau     = 0.36     # decay time constant in seconds: ~63% quieter every 0.36 s. Was 0.28,
                    # fast enough that the tone was gone before the ear caught it.
$sr      = 44100    # sample rate

$root = Split-Path -Parent $PSScriptRoot
$dst  = Join-Path $root 'car\vn\sfx\flatline.wav'

$n = [int]($sr * $seconds)
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$data = $n * 2

$bw.Write([char[]]'RIFF'); $bw.Write([int](36 + $data)); $bw.Write([char[]]'WAVE')
$bw.Write([char[]]'fmt '); $bw.Write([int]16);  $bw.Write([int16]1); $bw.Write([int16]1)
$bw.Write([int]$sr);       $bw.Write([int]($sr * 2)); $bw.Write([int16]2); $bw.Write([int16]16)
$bw.Write([char[]]'data'); $bw.Write([int]$data)

for ($i = 0; $i -lt $n; $i++) {
	$t = $i / $sr
	$env = [Math]::Exp(-$t / $tau)
	if ($t -lt 0.15) { $env = 1.0 }                        # a beat of full tone first
	$tail = ($seconds - $t) / 0.04
	if ($tail -lt 1) { $env *= [Math]::Max(0, $tail) }     # 40 ms to exact zero, no click
	$v = [Math]::Sin(2 * [Math]::PI * $freq * $t) * $gain * $env
	$bw.Write([int16]([Math]::Round($v * 32767)))
}

$bw.Flush()
[IO.File]::WriteAllBytes($dst, $ms.ToArray())
$bw.Close()

Write-Output ("flatline.wav  {0:N0} samples  {1:N2} s  peak {2:N2} (~{3:N1} dBFS)  tau {4} s" -f `
	$n, $seconds, $gain, (20 * [Math]::Log10($gain)), $tau)
