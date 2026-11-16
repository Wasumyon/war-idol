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

- **Quote convention flips inside one scene.** `01_intro` carries 39 quoted dialogue lines and 13
  bare, with the flip at the aftermath; `02`, `03` and `04` are 100% bare. Decide once.
- **Label convention differs.** `01_intro` uses `@ cast` shorthand (`S:`, `C:`, `P:`, `K:`, `R:`);
  the later scenes use long form (`Chip:`, `Player:`). Both parse. Decide which is house.
- **`car/vn/scenes/Notes.txt` is a live scene.** The game loads it as one named *Notes*, and
  `make_plain.ps1` generates `_read_Notes.txt` for it. It also breaks the `NN_name` convention.
  Underscore-prefix it or move it out of `scenes/`.

### Tooling

- **`commission.ps1` is blind to an sfx inside a `@ preset`.** It switches on the line's first
  verb, so `@ preset tremble = shake + zoom 1.15 + sfx shuffle` reads as verb `preset` and the
  `shuffle` never surfaces. That reference is the only one, so the check reports a missing asset
  that is present.
- **`make_plain.ps1` drops `? ` and `+ ` blocks**, so a wired choice disappears from the reading
  copy. This is the cause of the first item above.
- **The inline markup set has never been executed by Godot.** It was proven by a PowerShell port
  only. Highest-risk item on this list: one slip breaks every scene's text at once.
- **`@ auto <seconds>` does not exist, and the S-gag needs it.** Wanted: a title card that shows
  `WAR IDOLS`, then, once the word has finished typing, plays a glitch and swaps to `WAR IDOL` with no
  click. The engine advances only on click — `_advance()` is reached from the click path, and the `|`
  mark also waits — so this cannot be done in a scene file.
  - **And it is a driver, not a timer.** `_advance()` finishes the typing, appends the next narration
    unit, finishes the reveal, steps to the next dialogue segment, and only then leaves the node. So
    playing a node by itself means calling it repeatedly on a schedule and stopping when the node
    changes or a choice is up.
  - **Spec:** arm on the node; first tick only after typing completes, or it cuts the word off
    mid-letter; any click disarms it; never fire while a choice is presented.
  - **It is not a one-off.** The title card, the prologue's painted plate (*the camera does the
    work*) and any Feed or credits sequence all want it.

---

## B. Considerations

Numbers are stable handles, so a closed item leaves a gap rather than renumbering the rest.

- **B2. The quotes.** The remedy for the flip above — a 39-line mechanical pass. The reading copy
  is unaffected either way, because the script re-adds the marks.
- **B5. The refusal of the lesser door.** *Inherited*, E5, **still open**. The ladder should read:
  the brass refuse him → the army refuses him and offers the merc → **he refuses the honest
  illegitimate job** → and later accepts the counterfeit legitimate one.
- **B7. The narrator's quoting device — is it the rule?** `Technically it's the "White Cow"` puts the
  **official name** in quotes against what everyone calls it. That is not a drink-name inconsistency:
  the flight's first pour shares the bar's name, from the same myth. But the same shape exists
  ready-made for `the Kiss` / `the Hump`, so the question is whether quoting the official form is the
  device, and it should then be applied wherever the paper name meets the street name.
- **B9. Does the narrator's glass show anywhere?** The plant for him is one clause at *"Eyes turn
  towards us. It's my turn to feel sweat on my brow."* — *My glass is in the way.* It never says he is
  drunk; it puts the drink between him and the thing he is good at, which is §8's rule that props do
  the characterisation. Not in. Deliberately kept out of the three places where it would change what
  the beat *is*: the pistol, *"Not hard, just enough to stop her"*, and *"I laugh. It's been a while."*
- **B10. Albrecht's rescue — where and from what** (outline Beat 17). Proposed: its own beat at the
  top of Act 2, on one of Ottenok's new routes, before the trap. The alternative is to make
  Ottenok's trap (18) the cornering he rescues them from — tighter, but then the Ministry's trap
  and Albrecht's rescue sit in one scene, which tips the double meaning early.
- **B11. The gala finds the hardware, not the plan** (Beat 28). The old outline revealed the
  collision plan at Aysel's server, which spends Albrecht's one scene of self-justification
  (bible, Act 3) twenty days early. Proposed: mass-driver procurement and the Terpsichore boosters,
  unexplained until Beat 34. The old discovery also had the plan "wiping out the 8 Families",
  which the bible does not say.
- **B12. Who is in the interrogation room** (Beat 34). Canon §8 says the heist proves to Aysel that
  Albrecht knowingly ran it; if she hears him justify it in Beat 34, that reveal is spent.
  Proposed: the narrator and Chip only; Aysel held apart as the hostage he respects.
- **B13. Kathay — conditional rescue, permanent role.** The Day 7 LZ (Beat 16) is gated (canon §11)
  but she is load-bearing later, so Beat 18 is written as the shared fallback where a player who
  missed the LZ meets her. After Ottenok she takes his chair as the info dealer (bible), not a seat
  in the crew: Beats 28 and 37 use her as a hired hand, Beat 30 as the leak.
- **B14. Threads with no beat yet.** Langley's father (Watcher 6 → the recording → Aysel's bait →
  nothing). Aysel's locker drive — proposed cracked in Beat 36. First contact with the separatists
  before Route A needs them (35, 39). The red flag (13) could instead replace the monologue on Day
  1's street (03), but that changes a written scene.
- **B8. Carried, not re-checked** — from `01_intro_punchlist` §B and §D: the closing bold spanning
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
- **The title is *War Idol*, singular.** The card reads `WAR IDOL` and the `01_intro` header now
  matches the other scene headers.
- **The Metamorphosis beat and the flight are settled.** The Kiss named on the tray as the water
  and never glossed; the correct pour *"flat as snowy Europa"*, the wrong one topaz → emerald →
  blue → cloud → clear, ending on Chip's reflection; the flight named *the four jewels of Io* at
  the order rather than at the climax. Filed to canon §3 and §14.
- **The survivor's timing is settled, and the fix was canon's.** The intro's `one was gone a month
  later` stands. *Gone* is a euphemism paired with the next line's *I'm sorry, buddy*, and *a month*
  is the only rounded duration in a passage that otherwise itemises to the month. Canon §6 no longer
  gives a figure, and now says the blur is the tell.
- **Chip's flatness — dropped, not outstanding.** The reader's note was that she reads flat and could
  use more rebuffing. It was answered by the bar scene itself, written afterwards, so nothing is owed.
  The diagnosis that grew on top of that note goes with it; the page did not support it.
- **The fight's staging — addressed by the author.** A reader could not follow the action or place
  the narrator in the Chaac fight, because the dissociation had eaten the staging. The author has
  fixed it; recorded here so it is not raised again from the old file.
- **B3 and B4 are dropped, not missing.** Their numbers are left as gaps so the record stays
  traceable; see the two entries above.
- **The singular/plural question is settled; the gag that shows it is not.** The last line stays
  plural because it states a *rule*, and rules govern a class — the idols, in-world. The card stays
  singular: the form, the ideal. The glitch that would display both is deferred to the `@ auto`
  engine item in A.
- **Chip's drunkenness is planted once, at the will-o'-the-wisp** — *her second or third*, which is
  his count failing rather than hers, and which rhymes with his own opening, *the first two bars — or
  was it three?* Chosen over a second plant at her arrival, and *Swaying on her stool* stays the
  single payoff.
- **The choices mechanic is designed and filed.** It was B1, and the whole system now lives in
  **canon §11** — *The three things that are tracked* and *The rules*: the Sympathy ↔ Drama axis at
  ±1, deeds as positive-only flags, the no-HUD rule, floor-and-window Hype, the diegetic invitation
  instead of a meter. Nothing in it is open. What remains is engine work: the **conditional read**
  (see A) and teaching `make_plain.ps1` to render `? ` blocks — which is now a hard requirement
  rather than a nicety, since the design depends on choices being authored.
