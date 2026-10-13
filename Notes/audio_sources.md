# Audio sources and licences

What is in `car/vn/sfx/` and `car/vn/music/`, where it came from, and what its licence
actually permits.
`asset_commission.md` says what the scripts **want**; this file says what we **have**
and what we are allowed to do with it.

**Rule: a file does not go in `car/vn/sfx/` or `car/vn/music/` until its licence is
recorded here.** A
licence you cannot point at is a licence you do not have, and this is the one category
of asset that is expensive to replace late.

---

## Placed so far

| file | source | licence | status |
|---|---|---|---|
| `blow.ogg` | Kenney *Impact Sounds* — `impactPunch_heavy_000` | **CC0** (public domain) | good |
| `knife.ogg` | Kenney *Impact Sounds* — `impactMetal_light_000` | **CC0** | **placeholder** — a metal tap, not a draw-and-shing |
| `squish.ogg` | Kenney *Impact Sounds* — `impactSoft_heavy_000` | **CC0** | **placeholder** — a soft thud, not wet |
| `flatline.wav` | generated here — 1 kHz sine, 3 s, mono 16-bit | none claimed (ours) | good |
| `lightning-flash.wav` | generated here — noise crack + filtered rumble, 1.8 s | none claimed (ours) | **placeholder** — a sourced thunderclap will hit harder |
| `README.txt` | project | — | unchanged |

Kenney *Impact Sounds* (1.0), created 19-12-2019, distributed by Kenney —
`https://kenney.nl/assets/impact-sounds`. Its own `License.txt` states CC0. The pack
also contains 20 impact families × 5 variants plus footsteps, so any of the above can be
swapped for a sibling file without touching the script.

**Nobody has listened to these.** They were chosen by name, not by ear, and the two
marked *placeholder* are guesses. Audition before they are treated as finished.

**Still missing:** `keno` (music) — decided in-house rather than sourced. See the Music
section below.

---

## Where to get free sound, and what each place actually permits

Ranked by how little trouble the licence gives you.

### Safe without thinking about it

- **Kenney** — `kenney.nl/assets`. **CC0** on everything, game-oriented, direct `.zip`
  downloads that work from a script. The best first stop for impacts, UI, footsteps,
  weapons and coin-style stings. No attribution, commercial use fine.
- **OpenGameArt** — `opengameart.org`. Per-file licences; filter to **CC0** and it
  behaves like Kenney. Direct file URLs, so it is scriptable. Good for music.
- **Sonniss GDC Game Audio Bundles** — `sonniss.com/gameaudiogdc`. Royalty-free, no
  attribution, genuinely professional libraries. Multi-gigabyte downloads, metal-detector
  workflow — you dig through 30 GB for four sounds.

### Fine, with a condition

- **Mixkit** — `mixkit.co/free-sound-effects/`. *Mixkit Free License*: free for
  commercial use, no attribution. **But you may not redistribute the file as a
  standalone asset.** Mixing it into the game is fine; shipping the raw file is not.
  **Manual only** — the page markup exposes `-preview.mp3` files and nothing else, so a
  script can find candidates but cannot fetch the file the licence covers.
- **Freesound** — `freesound.org`. Per-file licences; the search filter for **CC0**
  works. Downloads need an account or an API key, so this one is manual, not scriptable.
  Still the best place for the odd specific sound (a knife shing, a wet squelch).
- **Pixabay** — *Pixabay Content License*: commercial, no attribution, no standalone
  redistribution. **Blocks scripted access** (HTTP 403), so it is manual only.
- **Zapsplat** — free tier requires an account and **attribution**.

### Do not use

- **BBC Sound Effects** — the RemArc licence is **personal, educational and research
  use only**. Not commercial. Easy mistake, and it is the biggest, best-labelled library
  of the lot.
- **freepd.com** — **the site is closed.** It was the standard public-domain music
  recommendation for years and still shows up in everyone's listicles. Do not plan
  around it.

---

## Notes on the generated placeholders

**`lightning-flash`** — **filled with a synthesised placeholder.** A noise crack with a
fast attack and a long tail plus a low rumble is close enough that nobody will tell on
one hit. If the flash ever fires more than once, source a real thunderclap: Kenney has no
weather, so it is OpenGameArt (CC0) or Freesound (account needed).

## Music — composed or AI-generated in-house

**Decided: we are not sourcing this.** A dive-bar loop has to survive being played under
a scene repeatedly, which is exactly where free music shows its seams. Written here so
the technical requirements are not rediscovered by debugging.

### What the engine needs

The VN sets looping **in code**, so there is nothing to configure in the import
settings — but that also means there is nothing to save a bad file.

```gdscript
if s is AudioStreamOggVorbis:  s.loop = true
elif s is AudioStreamMP3:      s.loop = true
elif s is AudioStreamWAV:      s.loop_mode = AudioStreamWAV.LOOP_FORWARD
```

- **Export `.ogg` (Vorbis).** No encoder delay, so the loop point lands where you put
  it. Filename is lowercase: `car/vn/music/keno.ogg`.
- **Do NOT use `.mp3` for music.** Encoder delay and padding shift the loop point, so
  the seam never lines up. It is fine for a one-shot `@ sfx`, wrong for a loop.
- **`.wav` works,** and loops `LOOP_FORWARD` over the whole buffer — which means the
  first and last samples must match, and the file must have **no leading silence, no
  trailing silence, and no fade-out.** A generator that ends on a fade is the single
  most common reason a loop clicks.
- Loops start at sample zero and end at the last sample. So: trim both ends flush, and
  make sure bar one follows the last bar without a gap.

### Licence, if generated

Free tiers of most AI music services grant **no commercial rights**; that requires a
paid plan. Also, purely machine-generated audio has no settled copyright in the US, so
you may not be able to stop someone else shipping the same output. Neither is fatal for
us — we only need to *use* it — but record the service, the plan and the date here, on
the same principle as every other asset: a licence you cannot point at is one you do not
have. If you compose it yourself, it is yours, and the only trap is a licensed sample
pack, whose terms the track then inherits.

### The brief for `keno`

- **Job:** plays under the whole bar sequence, and recurs — Keno's is the interview hub.
- **Register: retro-lounge.** The props are an old-fashioned, a vintage aloha shirt,
  prosthetic pince-nez, *the White Cow*, and a myth out of Ovid. This is the one place
  in the chapter that sounds like the twentieth century, and that is the nostalgia
  theme: the boom times are over.
- **Palette:** brushed drums, upright bass, muted trumpet or vibraphone, bar piano.
  Minor, but not sad — *worn*.
- **No lyrics** — they fight dialogue. **No strong melodic hook** — it loops, and a hook
  becomes a tic by the fourth pass.
- **Mix:** leave 1–4 kHz relatively clear so the typewriter and the voice sit above it.
- **70–95 bpm, swung. 60–90 seconds.**
- The one thing it should do: be **the only warm thing in the chapter.** Warmth in the
  timbre, not in the harmony.

### Fallbacks, if the above fails

1. **OpenGameArt** filtered CC0 — search *jazz*, *blues*, *cocktail*, *noir*.
2. **Mixkit** free music, same licence condition as the effects above.
3. **Incompetech** (Kevin MacLeod) — reliable and huge, but **CC-BY**: attribution is a
   credits-screen commitment.
4. **Sonniss** bundles, which include music beds.
