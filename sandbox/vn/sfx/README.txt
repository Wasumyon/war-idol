One-shot sound effects for the visual novel live here.

NAME CONVENTION
  A directive `@ sfx gunshot` loads, in order:
      vn/sfx/gunshot.ogg
      vn/sfx/gunshot.wav
      vn/sfx/gunshot.mp3
  So drop a file named after the sound and use that name in the script.

  LOOPING MUSIC DOES NOT LIVE HERE. It goes in ../music/ - see music/README.txt.

  You can also give a full path: `@ sfx res://vn/sfx/explosion.ogg`.

  A missing file does not crash - it logs a warning and plays nothing.

SUPPORTED FORMATS
  .ogg, .wav, .mp3

WHY THE SPLIT
  Effects are short, played many at once, and never loop. Music is long, streamed, and
  looped, and the player sets `loop = true` on it in code. Different import needs, so
  different folders - that is the reason, not neatness.

PROVENANCE
  Record the source and licence in Notes/audio_sources.md before the file lands here.
