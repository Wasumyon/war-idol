# Punchlist — live

Cross-work list. Two kinds of item, and **they are not the same kind of claim**:

- **Errors** — mechanical. Something is broken, or two things contradict. Verifiable, no taste
  involved. Fix them.
- **Considerations** — decisions not yet taken. Judgement, style, design. Argue these; don't
  "fix" them.

**Scope.** This is the work-wide list. `01_intro_punchlist.md` remains the granular scene-01 file:
its **C — decided, do not "fix"** section is still authoritative, and its **E — reader feedback**
section is the only outside evidence the project has. Items here that originate there say so.

**Provenance.** Items marked *inherited* come from `01_intro_punchlist.md` and were **not**
re-verified in this pass. Everything else was checked against the files.

**Convention:** quote-anchored, no line numbers, so items don't go stale.

---

## A. Errors

### Scene 01 — rendering and wiring

- **The unwired choice renders to the player.** `I order a [choice] for myself.` and
  `[House and Red, Old Fashioned, …]`. A `[` line is not structural, so both are drawn as
  narration in-game, and both appear in `_read_01_intro.txt`. **Kept deliberately for now** —
  they are what carries the options into the reading copy — so this is a live defect with a
  deferred fix. See B1.
- **His drink is hardcoded against a player choice.** `I'm nursing an old-fashioned` sits
  against an option list that includes *Brimstone* and *White Cow*. When the choice is wired:
  either that line reads the chosen name, or it stops naming the drink.
- **`@ music keno` never stops.** There is no `@ music stop` anywhere in the file, so the cue
  runs over the alley, the aftermath and the contract. End it, or let `02_stream` set its own.
- **`@ fullscreen` is never cleared.** Set for the title card; only `@ center off` and
  `@ large off` follow. Verified: the directive is never turned off. *Inherited and unverified:*
  the consequence the old file gives — every dialogue line full-screen, two clicks each.
- **`@ input_name` is never called in `01_intro`**, so Player renders as the default name for the
  whole chapter. It *is* called in `03_car`.

### The work — consistency

- **The survivor's timing contradicts canon.** File: `one was gone a month later`. Canon §6:
  `One of them was dead three weeks later`. Pick one.
- **Quote convention flips inside one scene.** `01_intro` carries 39 quoted dialogue lines and 13
  bare, with the flip at the aftermath; `02`, `03` and `04` are 100% bare. Decide once.
- **Label convention differs.** `01_intro` uses `@ cast` shorthand (`S:`, `C:`, `P:`, `K:`, `R:`);
  the later scenes use long form (`Chip:`, `Player:`). Both parse. Decide which is house.
- **The title is both singular and plural.** The on-screen card reads `WAR IDOLS` and the file
  header is "War Idols - 01"; `00_prologue` reads "War Idol".
- **`car/vn/scenes/Notes.txt` is a live scene.** The game loads it as one named *Notes*, and
  `make_plain.ps1` generates `_read_Notes.txt` for it. It also breaks the `NN_name` convention.
  Underscore-prefix it or move it out of `scenes/`.
- **Drink names are quoted inconsistently** — `"the White Cow"` and `"Hump it"` carry quotes;
  `the Kiss`, `the will-o'-the-wisp`, `the Peacock`, `the Gadfly` do not. Note this may be
  expressive rather than sloppy: *Technically it's the "White Cow"* reads as scare quotes for the
  paper name against what everyone calls it. Decide whether that is the device, and if so apply it.

### Tooling

- **`commission.ps1` is blind to an sfx inside a `@ preset`.** It switches on the line's first
  verb, so `@ preset tremble = shake + zoom 1.15 + sfx shuffle` reads as verb `preset` and the
  `shuffle` never surfaces. That reference is the only one, so the check reports a missing asset
  that is present.
- **`make_plain.ps1` drops `? ` and `+ ` blocks**, so a wired choice disappears from the reading
  copy. This is the cause of the first item above.
- **The inline markup set has never been executed by Godot.** It was proven by a PowerShell port
  only. Highest-risk item on this list: one slip breaks every scene's text at once.

---

## B. Considerations

- **B1. The choices mechanic.** Deferred by decision, and this is where it is parked. Needs:
  whether authoring moves into the engine's own `? ` / `+ ` form with `make_plain.ps1` taught to
  render the options as a visible list, or stays as raw markers; what the stat effects actually
  are; and whether the in-game render of `[choice]` is acceptable until then. Ties to A1, A2 and
  the `make_plain.ps1` gap.
- **B2. The quotes.** The remedy for the flip above — a 39-line mechanical pass. The reading copy
  is unaffected either way, because the script re-adds the marks.
- **B3. Chip must cost him something.** *Inherited*, E3, **not done**. She asks the loaded
  questions and wins every exchange. The collision is already in the premise — she wants footage,
  he is hiding something — so let one question land, and let him not recover in the same line.
- **B4. The fight's staging is eaten by the dissociation.** *Inherited*, E1, **open**. He needs
  space as well as decision: there is no position, no facing, no distance, so the reader gets a
  mood and no picture. The fix is to make `I don't remember ___` the carrier for staging too.
- **B5. The refusal of the lesser door.** *Inherited*, E5, **still open**. The ladder should read:
  the brass refuse him → the army refuses him and offers the merc → **he refuses the honest
  illegitimate job** → and later accepts the counterfeit legitimate one.
- **B6. Carried, not re-checked** — from `01_intro_punchlist` §B and §D: the closing bold spanning
  two clicks; *he whistles* a list of battles; *orbits are closest*; two *as* clauses in the cloak
  line; *small chest*; *The transformation bewilders*; *booty*; *a Nelson*; *in the bacon*; the
  pamphlet losing its pointing; the chant payoff and its *no census* rule; *Good girl* as its own
  line; a hand on the shoulder; Keno's myth line moved into his own mouth; the title card as an
  in-world broadcast ident.

---

## C. Closed since the last pass

Recorded so nobody re-fixes them.

- **`tremble` resolves.** The preset is defined in `01_intro` itself and `shuffle.ogg` exists, so
  the old "does nothing / missing asset" item is retired.
- **Asset names are lowercase** — `@ img recruiting_office`, `great_red_eye`, `juno_alley`,
  `keno`, `chip-skull`; `@ music keno`. The Windows-versus-export hazard is gone.
- **The bracketed aside no longer straddles clicks.** The only bracketed line left is the choice
  marker in A.
- **The `S` → `C` label switch fires at the insist line**, not sixty lines early.
- **`Some princess.` closes the heifer joke**, as its own click after the calf line.
- **The Metamorphosis beat and the flight are settled.** The Kiss named on the tray as the water
  and never glossed; the correct pour *"flat as snowy Europa"*, the wrong one topaz → emerald →
  blue → cloud → clear, ending on Chip's reflection; the flight named *the four jewels of Io* at
  the order rather than at the climax. Filed to canon §3 and §14.
