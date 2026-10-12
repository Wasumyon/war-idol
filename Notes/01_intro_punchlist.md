# 01_intro — fix list

Rewritten against the current file. Quote-anchored, no line numbers, so it won't go stale.

**Nothing here breaks playback.** The only run-breaking items are the missing assets, and those are deliberately deferred.

---

## A. Inconsistencies to settle (pick one and apply it)

- **Keno's lines have quotation marks; nobody else's do.**
  `K: "Already paid."` · `K: "Hey! What!?-"` · `K: "Free round for everyone on the Nemean!"`
  Chip and Player lines are unquoted throughout. Strip the quotes from the K lines, or quote everything.
- **`@img` vs `@ img`.** The crib sheet says `@ img`, the file says `@img Keno`. Both work. Pick one — `@ img` is easier to grep.
- **Drink names are quoted inconsistently**: `"the Kiss"`, `"the Hump"`, `"White Cow."` are quoted; `the will-o'-the-wisp`, `the Peacock`, `the Gadfly` are not. Decide whether named drinks take quotes.
- **Dashes**: the file uses a spaced hyphen (` - `) everywhere. Fine, but decide, because an em dash would read better typeset.

---

## B. Line-level fixes

- **`My cloak falls open off her as if in slow motion as she moves.`** — two *as* clauses. Drop one: *"falls open off her, slow, as she moves."*
- **`The show only lands harder because of the stairs.`** — whose show? The fall, or his war record? Still the least clear line in the scene, and it's at the most important beat.
- **`"First Loki Patera...!" he whistles.`** — whistling a *list of battles* is odd. A *low* whistle, or move the verb: *"he says, and then a low whistle."*
- **`Every 3.5 days their orbits are closest.`** — orbits aren't closest; the *bodies* are.
- **`thrusts her slim arms over my elbow`** — plural. One arm goes over the elbow.
- **`level it at her small chest`** — "small" is one of the diminishment words you've been clearing out (tiny back, tiny arms, slim arm, slender fingers). This one is left.
- **`The transformation bewilders my senses.`** — "The" implies a transformation already named. It's a *plant* for Daphne three pages later, so it works retroactively, but on first read it points at nothing. Specify whose.
- **`still rings out tallies of booty`** — "booty" is doing two jobs (loot and sex) and neither cleanly.
- **`One random voice on the Feed is just a curio, could be a scam, could be a rumor.`** — comma splice.
- **`The bright screen reads, in big letters.`** — the comma placement is awkward. Colon or nothing.
- **`Ex-Nemean, I think to myself.`** — "I think to myself" is a tag the "I" already carries.
- **`pins her arms in a Nelson.`** — half-Nelson, or full? Both exist.
- **`she brings me out there and in the bacon`** — "in the bacon" (money) isn't set up anywhere. Either seed it earlier or use something established.
- **Two consecutive blank lines before `Our contract:`** — one blank is one paragraph gap.
- **`His tone becomes somber again.`** — "again" implies it was somber before. It wasn't.

---

## C. Decided — do not "fix" these

Pasted here so nobody undoes them later, you included.

- **The pistol is a laser with a recuperator.** That's why `las-pistol`, `cold steel`, `three recoils` and `burned-out craters` all coexist. The mechanism is deliberately never explained on the page — it exists so *you* stay consistent. Do not add a line about it.
- **One glass, four drinks.** Doesn't need specifying. Readers don't audit staging.
- **The three drinks are in myth order**: White Cow → Peacock → Gadfly is the Io story in sequence. Keep it.
- **`It gives them horns.` stays where it is** — closing the body description, isolated by blank lines.
- **`retards like me`** — self-effacing grunt humour, deliberate.
- **`Seven months since then.`** — not a fragment for effect. It's *"It is seven months since then"* with the dead words elided, which is the correct tense. `since` never takes a bare present or simple past.
- **`~` in Chip's lines** — a deliberate style mark. Renders literally, as intended.
- **`Since` / `have passed`** — never both.

---

## D. Optional beats (your call, all cheap)

- **The chant payoff.** After `"THE THREE RETURNED!"`, his arithmetic: *"Three of us came back. Two of us are still here."* The chant is now literally true, so the grief is that it stopped being true, and only he's counting.
- **`Good girl.` on its own line** — gives him a pause before the verdict.
- **Keno's line at 119** — currently reported narration. With `K=Captain Keno` in the cast, it could be his mouth instead.
- **`@ input_name` is never called**, so Player renders as the default name for the whole chapter. Either call it or commit to the default.
- **The title card reads `WAR IDOLS`**, the game is *War Idol*. Consider making the card an in-world broadcast ident — the plural then means the show and the singular means the game.
