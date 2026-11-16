extends RichTextEffect
## [glitch]...[/glitch]: the visor or the record is unsure of this span. Spec: dossier_spec.md §6.
##
## Every character is swapped for a random block glyph a few times a second, with a small
## horizontal jitter and a colour split. The true letter shows through for a frame now and
## then so a careful reader can half-read it. Span length is kept, so the noise matches the
## word's shape. Same pattern as script_effect.gd.

var bbcode := "glitch"

const RATE := 7.0            ## re-rolls per second
const TRUTH_ODDS := 6        ## one frame in this many shows the real letter
const JITTER := 1.5          ## px
const GLYPHS := "█▓▒░▚▞▙▛▜▟"
const FALLBACK := "#%&@$*+=?/"
const TINTS := [Color("#79ead1"), Color("#ff5f8f"), Color("#e8f6f2")]


func _process_custom_fx(c: CharFXTransform) -> bool:
	var step := int(c.elapsed_time * RATE)
	var h := absi(hash(Vector3i(step, c.relative_index, 17)))
	if h % TRUTH_ODDS != 0:
		var ts := TextServerManager.get_primary_interface()
		var pool := GLYPHS
		var pick := pool.unicode_at((h >> 4) % pool.length())
		if not ts.font_has_char(c.font, pick):
			pool = FALLBACK
			pick = pool.unicode_at((h >> 4) % pool.length())
		c.glyph_index = ts.font_get_glyph_index(c.font, 16, pick, 0)
	c.offset.x += float(((h >> 8) % 3) - 1) * JITTER
	c.color = TINTS[(h >> 12) % TINTS.size()]
	return true
