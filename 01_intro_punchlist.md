# 01_intro — fix list

Updated against the current file. Quote-anchored, no line numbers, so it won't go stale.

**Sections:** A inconsistencies to settle · B line-level fixes · C decided, do not "fix" ·
D optional beats · E reader feedback, with status.

**Nothing here breaks playback.** The only run-breaking items are missing assets
(`chip-skull`, `keno`), and those are deliberately deferred.

---

## Closed since the last pass

- **`P:` on the merc offer → `R:`.** It was the recruiter's line; as `P:` the narrator was
  recommending the mercs to himself.
- **The money words are three distinct nouns now** — *VA benefits* (the promise), *Veteran's
  Assistance* (the office), *your pension* (what's withheld). No repeat, and canon's quote
  matches again, so no note edits are owed. The order also works: he says the acronym in his
  own idiom and then, talking to a stranger, spells it out.
- **`The show only lands harder because of the stairs`** was rewritten and the ambiguity is gone.
- **The refusal is the recruiter's own line**, and *"Somebody put you to this?"* stays puzzlement,
  so E5's guardrail holds.
- **`Grand Executor Albrecht` exists in the notes now** — canon §13, title settled as *Grand
  Executor*, with the Grand Inquisitor rationale and the rule for who says the full form.

---

## A. Inconsistencies to settle

- **Three quote styles in one file.** `R:` and `P:` in the recruiter block carry quotation marks;
  `K:` does; `C:` and `P:` in the bar do not. The engine already prints the speaker's name, so the
  marks are redundant — strip them everywhere and keep quotation marks only for speech *reported
  inside narration* (`"Chaac Patera... Lost a brother there."`).
- **`@img` / `@music` with no space.** Both parse (verified — the parser strips after the `@`), so
  it's cosmetic. `@ img` / `@ music` is easier to grep. **A stray colon is not cosmetic**: `@img:`
  parses as the verb `img:` and silently does nothing. And the names are capitalised (`Keno`,
  `Recruiting_office`, `Great_red_eye`) — lowercase them, or they resolve on Windows and break on
  export.
- **`@ fullscreen` is never cleared.** So every `C:` / `P:` / `R:` / `K:` line renders full-screen
  with a bold name above it — and because the name and the line are separate units, **each dialogue
  line costs two clicks**. Either that's the intended look (it matches the prologue) or the file
  wants `@ box` after the title card.
- **Nothing stops the Keno cue.** It starts at the bar and nothing in the file ends it, so it runs
  over the alley and past the scene unless 02_stream sets its own.
- **The bracketed aside straddles clicks.** `[Nobody knows what caused it...` opens on one click
  and `...Argos.]` closes five clicks later, so the brackets render as orphans. One line, or no
  brackets.
- **Drink names are quoted inconsistently**: `"the Kiss"`, `"the Hump"`, `"the White Cow"` are
  quoted; `the will-o'-the-wisp`, `the Peacock`, `the Gadfly` are not.
- **Dashes**: spaced hyphen (` - `) everywhere. Fine, but decide, because an em dash reads better
  typeset.
- **Canon says the survivor died three weeks later; the file says a month.** Pick one.

---

## B. Line-level fixes

**Fixed in the last pass** (grammar, spelling, punctuation, and a malformed directive): `upstairs`;
`'til`; `grandfathers`; `Veterans'`; the comma after *bugs*; the missing close-quote on Keno's myth
line; `somber` without *again*; `her slim arm`; `reads in big letters:`; the doubled blank before
`Our contract:`; the comma in *"End times or not, life goes on."*; and `@img:` → `@img Great_red_eye`.

**Still open:**

- **`@tremble` does nothing in this file.** Presets are per-scene and `tremble` is defined in the
  prologue, not here — so the line is parsed and never read. And if you *do* define it here, its
  `sfx shuffle` is a missing asset: there is no `shuffle.ogg|wav|mp3` in `car/vn/sfx/`. Write the
  three effects out longhand, or define the preset here with a sound that exists.
- **The closing bold spans two clicks.** `*Stay alive and elbow out the competition. / Those are the
  rules of the War Idols.*` opens the `*` on one click and closes it on the next. Check the renderer
  joins them, or the last line of the chapter loses its bold.
- **`he whistles`** — whistling a *list of battles* is odd; the intended reading is a low whistle
  *at the record*. *"he says, and then a low whistle."*
- **`Every 3.5 days their orbits are closest.`** — orbits aren't closest; the *bodies* are.
- **`My cloak falls open off her as if in slow motion as she moves.`** — two *as* clauses. Drop one.
- **`level it at her small chest`** — "small" is a diminishment word you've been clearing out
  (tiny back, tiny arms, slender fingers). This is the last one.
- **`The transformation bewilders my senses.`** — "The" implies one already named. It's a plant for
  Daphne three pages later, so it works retroactively; on first read it points at nothing.
- **`still rings out tallies of booty`** — "booty" is doing two jobs (loot and sex) and neither
  cleanly.
- **`pins her arms in a Nelson.`** — half- or full? Both exist.
- **`in the bacon`** — *some scratch* is now seeded earlier, so either use *scratch* here too or
  accept two money words in one mouth.
- **`It says so in the pamphlet.`** — the word order is fixed, but dropping *"over there"* lost the
  **pointing**, which the "every word is punctuated with his hands" business was built to serve.
  The pamphlet was an object in the room.

---

## C. Decided — do not "fix" these

Pasted here so nobody undoes them later, you included.

- **The pistol is a laser with a recuperator.** That's why `las-pistol`, `cold steel`, `three
  recoils` and `burned-out craters` all coexist. Never explained on the page — it exists so *you*
  stay consistent. Do not add a line about it.
- **A flight, four glasses** — one small pour each, served together, *not* one glass. Keep the
  *effects* (colours, layers, fizz, whatever changes) and never the recipe: a list of ingredients is
  a mechanism, and this narrator does not explain mechanisms.
- **The four drinks are in myth order**: White Cow → Peacock → Gadfly → Metamorphosis. The cow is Io
  transformed; the peacock is Argus, whose hundred eyes Hera sets in the bird's tail; the gadfly is
  her tormentor; the metamorphosis is her restoration. Sequence *and* meaning are both correct.
- **`It gives them horns.`** stays where it is — closing the body description, isolated by blanks.
- **`retards like me`** — self-effacing grunt humour, deliberate.
- **`Seven months since then.`** — not a fragment for effect. It's *"It is seven months since then"*
  with the dead words elided. `since` never takes a bare present or simple past.
- **`~` in Chip's lines** — a deliberate style mark. Renders literally, as intended.
- **`Since` / `have passed`** — never both.
- **`You knows what they're going to take back...`** — kept. It's the recruiter's dialect, and the
  same mouth's *I knows a guy* establishes it two lines earlier. Do not "fix" it.
- **`Ex-Nemean, I think to myself.`** — do not touch. Canon §4 quotes this line *as is* as his
  private label-amendment. The tag is the character trait, not a redundancy.
- **`just a curio, could be a scam, could be a rumor`** — the comma splice is his voice, not an
  error. He splices in dialogue too (*"…no one's gonna save you, your little tricks won't work."*).
- **`He heats at my curt answer.`** — a clipping of *gets heated*. The frame is native (*bristles
  at*, *chafes at*), so only the verb is new, which is how slang gets built.
- **`all true Ionian patriots`** — the axis is **resident vs absentee**, not veteran vs patriot.
  The oligarchs are cosmopolitan and don't live on Io; *patriot* is the ministry's **belonging**
  word, which is what it actually sells. The refusal four lines later pays it off: the promise is
  universal, the payment isn't. *Ionian* is worth establishing as the demonym — Io → Ionian, with
  *ion* sitting right there in a moon that is a plasma torus.
- **`You ain't fresh from the barracks no more, you know?`** — *fresh* is a goods word, and the
  idiom "fresh out of college" buries the metaphor. Negating it while he looks at the leg is what
  detonates it: broken, older, used up. **And the scene proves him right** — the fall on the stairs.
  That is the true-but-insufficient reason done by **demonstration** instead of by a clause, which
  is why the refusal doesn't need to mention the physical.
- **`You're not that guy anymore`** — rejected as too cliché, and too worn for a register this dry.
  Recorded so it doesn't come back.
- **The pun in `the show landed; but I landed harder`** — kept. Deadpan, self-deprecating, and
  *on account of* hides the hinge. Note this is an **exception to style guide §6** (puns belong to
  characters, not the narration) — and §9's narrower test is "*a pun the narration is proud of*",
  which this isn't. **Action: record the exception in §6 so it isn't re-litigated.**
- **`That Great Red Eye`** — *Red* is the specific noun; *Great* survives because it's a **citation**
  of the Great Red Spot, which is why the capitals stay (they make it a quotation rather than a
  filler adjective). The prologue rhyme is carried by **"again"**, so the name is free to be
  specific; a second "of Jupiter" would repeat the prologue's construction minutes after it.
- **`He says it as a kindness.`** — the plain version is the point. "Cruel kindness" names what the
  reader is already doing for free. The narrator is a witness, not a judge.

---

## D. Optional beats

- **The chant payoff — rewrite before using.** Canon wants the beat *and* supplies wording: *"It was
  four, damn it. / But never let the numbers fuck up a good chant."* The rule is ***no census*, not
  *no temper*** — a fumble given up in the same breath. As previously written ("Three of us came
  back. Two of us are still here") it **does the census** the rule forbids.
- **`Good girl.` on its own line** — a pause before the verdict.
- **A hand on the shoulder** after *"He says it as a kindness."* Stages the cruel kindness in
  reported fact instead of naming it, and rhymes with Chip putting her hand on his arm at the bar.
- **Keno's myth line** is currently reported narration. With `K=Captain Keno` it could be his mouth.
- **`@ input_name` is never called**, so Player renders as the default name for the whole chapter.
- **The title card reads `WAR IDOLS`**, the game is *War Idol*. Consider making the card an in-world
  broadcast ident — the plural then means the show and the singular means the game.

---

## E. Reader feedback — first outside read

Three readers. Quote-anchored, and worth more than anything else in this file, because it is the
only evidence here that does not come from the author or from me.

**Provenance note.** In E1–E5, the *quotes and the observations* are the readers'. The diagnoses,
the suggested fixes and any claim about what the chapter's subject is are **mine**, written into
this file afterwards. E2 in particular: the readers supplied only *which two images landed*; the
prologue link and "foundational image" are my conclusion, not a finding of record, and not a rule
the way style guide §6 is. Discount accordingly.

### E1. The fight reads as dissociation, but nobody can see it — **OPEN**

`"I don't remember deciding. Three recoils. A pipe across my back. The heft of the tantalum cane
through a neck, an ankle, and the gun level on a third. / Scatter."`

They got the dissociated state, and they liked the *impression*. **They could not follow the
action or place the narrator.**

The cause is specific: **the dissociation has eaten the staging.** There are no anchors — no
position (standing, kneeling, down), no facing, no distances — so the reader has a mood and no
picture. Two smaller faults compound it:

- **"A pipe across my back" implies a man behind him who is never accounted for.**
- **"a third" invents a headcount.** Three shots (two craters in one chest, one in the Cassini
  punk's forehead) plus a neck, an ankle and "a third" reads as six men. The chapter tags people
  by feature everywhere else — *the Cassini punk*, *the fat one* — so the fix is to use a tag here
  too instead of a number.

**The fix is not to un-dissociate him.** It is to let the existing device carry *space* as well as
decision: make `"I don't remember ___"` the pattern for the staging too. *"I don't remember
deciding."* … *"I don't remember crossing the floor."* The omissions become the information, which
is the same trick the passage is already using.

### E2. The two images that landed are the same image — **OPEN (lens, not a task)**

**Jupiter's eye**, and **the fall on the stairs.**

Both are about being *down* and *watched* — and note that the prologue opens the same way: *"A leg.
/ My leg."* on the ground, bleeding, with something watching from orbit. So the chapter's
foundational image may already be in place and may have arrived by accident. Worth making
deliberate. The art brief already puts Jupiter in frame for exteriors; this is the narrative side
of the same instruction.

### E3. Chip fell flat — and the suggested fix is the wrong lever — **HALF DONE**

One reader wanted more flirtation and more rebuffing.

**The instinct is right and the diagnosis is wrong.** The problem is not quantity of flirtation.
It is that **Chip never costs him anything.** She asks the loaded questions — *"How many people
have you killed!?"*, *"Is it true what they say about the smell?"* — and he answers with a joke,
every time. And she wins every exchange in the bar: the clip, the donations, the free round, the
last word, and she pays for his drinks. A character who cannot lose is flat regardless of how
well she flirts.

**The collision that is missing is already in the premise:** she wants footage, and he is hiding
something. Those are the same object. Let one of her questions *land* — let it cost him a beat he
does not recover from in the same line. That is stakes, not chemistry, and it is one exchange.
**Not done.**

**And her fear has nowhere to go** — *"She holds back a shriek and lets out something like a
croak"* is genuine, and the act used to resume on the next line. **Done:** the drop now breathes
for three beats (the croak, the narrator's aside on harsh lessons, the sweat on her brow) before
the thesaurus police. Keep it.

### E4. Why the three notes are one note — **lens**

Being *seen* while you are *down* is the chapter's subject. E2 is that image landing; E1 is the
staging hiding who is looking from where; E3 is the watcher having no stake. **Chip is the Eye in
human form** — the girl with the camera and the red spot in the sky are doing the same thing to
him. Worth holding in mind while revising all three.

### E5. Make the refusal explicit — **MOSTLY DECLINED, one item open**

A reader wanted the recruiter to say plainly that it is the leg, and wanted the narrator to *fight
back* before being told he's not that guy anymore.

**Declined on the explicitness.** Reason given: too wordy, and readers understand the meaning
without it. The structure holds up without it, and better than expected — the desk's *"not fresh
out of the barracks"* is proved true three beats later by the fall on the stairs, so the
true-but-insufficient reason is demonstrated rather than stated, and the body still gets named
without naming Chaac. See C.

**Guardrail — respected.** He may be explicit about the leg and must be *ignorant* about Chaac.
*"Somebody put you to this?"* is puzzlement, not knowledge. Any hint that this man knows something
collapses the ambiguity.

**The narrator must not argue — respected.** He reports, doesn't plead, and walks.

**But his silence is still written as passive — DECLINED.** *"as I wait in silence"* is waiting,
and per canon §13 that is the **correct** form: the Grand Inquisitor's prisoner answers with a
gesture, never with pressure, and the old man adheres to his idea anyway. E5 wanted the silence
turned into pressure so the recruiter's cruelty would be *caused* by the narrator. Not needed —
the form is already right, and pushing would make the narrator a participant in the pitch.

**And the reader handed over the chapter's thesis by accident:**

> "they won't even bother with checking your physical, security will take you."

That is the opening move of a **lesser door**. They will take his body and not his name — which is
precisely *"I wanted a name on mine"* later. The offer is now in the scene and it's sharper than
the draft's (*"they won't give a damn about your physical"*). **What's missing is the refusal of
it:** the ladder should read — the brass refuse him, the army refuses him and offers the merc,
**he refuses the honest illegitimate job**, and later accepts the counterfeit legitimate one. That
refusal is what makes the licence damning. **Still open.**

*(The doubled offer is settled: there is now one sharp version rather than Vulkan and the mercs
saying the same thing twice.)*
