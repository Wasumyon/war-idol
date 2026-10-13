Looping music for the visual novel lives here.

NAME CONVENTION
  A directive `@ music keno` loads, in order:
      vn/music/keno.ogg
      vn/music/keno.wav
      vn/music/keno.mp3
  and loops until changed. `@ music stop` stops it.

  ONE-SHOT SOUND EFFECTS DO NOT LIVE HERE. They go in ../sfx/ - see sfx/README.txt.

  You can also give a full path: `@ music res://vn/music/keno.ogg`.

  A missing file does not crash - it logs a warning and plays nothing.

FORMAT
  .ogg (Vorbis) is strongly preferred. The player sets `loop = true` in code, so there is
  nothing to configure in Godot's import settings - but that also means nothing saves a bad
  file.

  MP3 CARRIES ENCODER DELAY AND PADDING, so a loop point never lands where you put it.
  Do not use MP3 for music.

  .wav works and loops the whole buffer forward, so the first and last samples must match
  and there must be no leading or trailing silence.

  Trim both ends flush. A generator that ends on a fade is the most common reason a loop
  clicks.

PROVENANCE
  Record the source and licence in Notes/audio_sources.md before the file lands here.
