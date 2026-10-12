# Art brief

The **plan**: what to make, in what order, and the POV rules that make plates sit together.
`style_guide.md` §12 holds the *rules*; this file holds the *work*. Update it as assets land.

---

## What to approach first

The order is not by size. It is by **what decides the look** and **what the script blocks on**.

**Warm-up, no deliverable attached.** An afternoon of colour-mixing studies in CSP, then two
landscape studies from NASA/JPL Io frames. Public domain, and it is the actual subject. The
point is to find the palette and get the hand back, not to produce anything.

1. **The Io vista — the look-setter.** Everything else gets judged against it, so it has to
   exist first or every later asset gets retro-fitted. It fixes the sky, the palette, the
   horizon height and the light rig in one image. Paint from reference, but *move* the
   horizon, *move* a fumarole, and add a structure or a figure, so the arrangement is yours
   even though the observation is not.
2. **`chip-skull`** — small, one line of script, a face. It proves the *other* register, the
   Feed's graphic layer, in a single asset. Highest confidence, highest impact, least time.
3. **Keno's interior** — the only constructed space in the chapter, so the one place the
   perspective drills actually get used. One-point is enough.
4. **The `Keno` plate for 01_intro** — the bar's exterior and the street. Reuse the Io vista's
   sky and palette and it costs a fraction of a new plate.
5. **The alley** — two-point, night, the Feed's light on faces.
6. **Then** the rest of the commission list, plus the Tank sheet corrections below.

Rules of order, generally: **look-setters before one-offs. Reusable layers before unique
plates. Whatever the script blocks on before decoration.**

---

## POV, horizon and composition

**The camera is fixed. A plate is a stage, not a picture.** Pick a camera height per location
and never break it — consistency of horizon height *is* consistency of world.

- **The horizon is eye level.** Which means the horizon height *is* the camera height. Seated
  in a booth at Keno's, roughly 1.2 m. Standing on the street, 1.6–1.7 m.
- **The bottom third is the dialogue box.** Nothing load-bearing below about 60% height, and
  the bottom must be *quiet* — dark or low-contrast — or the text becomes unreadable.
- **`KEEP_ASPECT_COVERED` crops.** Keep the focal object inside the central 70% and never put
  meaning within about 10% of an edge: a taller window loses the sides, a wider one loses top
  and bottom.
- **If a plate will use `@ pan`, paint wider than 16:9.** The engine clamps panning to the
  plate overhang, so an exact 16:9 plate cannot pan at all. And a pan means the composition
  must survive a horizontal shift — keep verticals strong, avoid a single centred focal object.
- **Three planes, always.** Dark foreground silhouette, mid-ground stage, light background.
  Aerial perspective does the rest, and it is the cheapest depth there is.
- **Put a human figure or a doorway in for scale.** Io's geology is enormous, and nothing reads
  as enormous without something to measure it against.

---

## The light rig — one rule that unifies the whole game

Io receives about **3.7% of Earth's sunlight**, so the sun is a weak cold key from above. The
ground is volcanic, so there is a warm bounce from below. Therefore:

> **Every exterior has a cold top light and a warm bottom light.**

That is true to the place, it produces the sulfur yellow-green in the lower planes for free,
and it will make every plate look like it belongs to the others.

**Interiors are the exception, and the exception is the point: the bar is lit by the Feed.**
The screen behind the bar is the key light, so every face in Keno's is lit by the Ministry's
picture of the war. Cyan and white on the skin, warm bar glow behind. Do not add a chandelier.

**And the Eye.** Jupiter in frame means *watched*; Jupiter out of frame means *private*. The
red spot is the eye. So whether the Eye is in the plate is a narrative decision rather than a
lighting one — caves, storms and interiors are where it is absent, and that absence is a gift.

---

## Per-asset notes

**Io vista — the look-setter.** Wide. Horizon high, around 60–65%, so the ground dominates,
which is right for a volcanic moon. Cold from above, warm from the ground. One structure or
figure for scale. Bottom quiet. Jupiter in frame with the red spot legible.

**`chip-skull`.** A face, one frame, no gore. It is a *rendering*, not anatomy, so keep her
silhouette and replace the material: hard edge, over-clean surfaces, a cyan rim. It should
read as the HUD failing, not as a wound.

**Keno's interior.** One-point, seated eye-level. Back-bar shelves, a doorway to the street,
the screen as key light. Low gravity, so nothing hangs quite straight and everything is
jointed — nothing rigid survives the tide.

**Tank sheet, second pass — two corrections:**

1. **Goggles: plain glass.** Remove the emissive lens, the bezel glow and the cyan. No HUD.
   She is the only character with clean eyes and the story needs them.
2. **Pauldrons: taper them.** As drawn they are flat toothed discs, so the HUD has nothing
   conical to misread. Give them a projecting, tapering form — the hose fitting flaring, or a
   curved exhaust — and keep the gear reading underneath. Gear first, horn second.

---

## Working in CSP

- `Sub Tool Detail → Color Mixing`: **mixing rate** for dirty-brush pickup, **density of paint**
  for body, and **amount of paint** set low so strokes *run out* the way a real brush dries.
  `Ink → Compare Density` for loaded paint, `Scale Density` for glazing.
- Five brushes in Quick Access, named for their job. Nothing else in the panel.
- **Cap the undo count.** Revise less, commit more — that is the digital failure mode for a
  painter, and commitment is your strength.
- Work at whole-canvas zoom. Closer only for cleanup.
- Score at **3840×2160**, export at 1920 wide, WebP for file size.
