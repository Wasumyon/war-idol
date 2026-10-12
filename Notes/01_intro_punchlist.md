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

---

## E. Reader feedback — first outside read

Three readers. Quote-anchored, and worth more than anything else in this file, because it is the
only evidence here that does not come from the author or from me.

### E1. The fight reads as dissociation, but nobody can see it

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

### E2. The two images that landed are the same image

**Jupiter's eye**, and **the fall on the stairs.**

Both are about being *down* and *watched* — and note that the prologue opens the same way: *"A leg.
/ My leg."* on the ground, bleeding, with something watching from orbit. So the chapter's
foundational image may already be in place and may have arrived by accident. Worth making
deliberate. The art brief already puts Jupiter in frame for exteriors; this is the narrative side
of the same instruction.

### E3. Chip fell flat — and the suggested fix is the wrong lever

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

**And her fear has nowhere to go.** *"She holds back a shriek and lets out something like a
croak"* is genuine — and the act resumes on the next line with the thesaurus police. Let the drop
breathe for one beat before she covers it. It makes her a person rather than a bit, and it pays
off in the alley.

### E4. Why the three notes are one note

Being *seen* while you are *down* is the chapter's subject. E2 is that image landing; E1 is the
staging hiding who is looking from where; E3 is the watcher having no stake. **Chip is the Eye in
human form** — the girl with the camera and the red spot in the sky are doing the same thing to
him. Worth holding in mind while revising all three.

### E5. Make the refusal explicit — but do NOT let him argue

A reader wants the recruiter to say plainly that it is the leg, and wants the narrator to
*fight back* before being told *"you're not that guy anymore."*

**The explicitness is right, and it builds the false floor rather than damaging it.** Two refusals
are in play and they are different bodies: the **army's** refusal (this desk) and the **brass's**
refusal (Chaac). The desk can be perfectly explicit about the leg, because the desk's reason is
mundane and sincere — which makes the *Chaac* refusal louder by contrast. One refusal explained,
one silent. That is exactly what canon §4 wants.

**Guardrail:** he may be explicit about the leg and must be *ignorant* about Chaac. *"Someone put
you to this?"* is puzzlement, not knowledge. Any hint that this man knows something collapses the
ambiguity.

**But the narrator must not argue.** Pleading breaks his one defining habit: he amends names
privately and never to a face, he reports and does not reflect, he takes the refusal and walks.
The friction the reader wants has to come from somewhere else.

**It already does — his silence is the weapon, and it is currently written as passive.** *"I wait
in silence"* is waiting. Make it pressure and the whole second half works: **he refuses to help the
man be kind, so the man is forced to be honest.** One clause converts it. Then the recruiter's
cruel sentence is *caused* by the narrator, which stops it being something done to him — and it is
the same mechanism as Chip, who also escalates when he will not answer.

**And the reader has handed over the chapter's thesis by accident:**

> "they won't even bother with checking your physical, security will take you."

That is the opening move of a **lesser door**. They will take his body and not his name — which is
precisely *"I wanted a name on mine"* forty lines later. **So the recruiter should be the first
person to offer him the illegitimate version**, and the narrator should visibly *decline* it. Then
the ladder reads: the brass refuse him, the army refuses him and offers him the merc, **he refuses
the honest illegitimate job** — and later accepts the counterfeit legitimate one. That refusal is
what makes the licence damning.

**Note this should REPLACE the existing alternative, not add to it.** *"Vulkan Security is always
hiring. And there's always the mercs… you can skip the physical"* is the same offer said twice.
One sharp version does more.
