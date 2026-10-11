# 01_intro.txt — punch list

Line numbers match the file as of commit `6b27872`. Ordered by what hurts most first.

---

## A. Breaks the run (nothing renders)

- **L278 `@ sfx lightning-flash`** — file doesn't exist. Needs `car/vn/sfx/lightning-flash.ogg|wav|mp3`. Logs a warning and plays nothing.
- **L279 `@ img chip-skull`** — file doesn't exist. Needs `car/vn/img/chip-skull.png|webp|jpg`. This is the chapter's only image, and it's the best one (the skull behind her face). Currently the beat lands on a blank backdrop.
- **No other `@ img` anywhere.** The whole chapter plays over a flat colour. Minimum viable: one bar interior, one alley.
- **No `@ music` at all.** A bar scene with no ambience.

---

## B. Continuity / facts to reconcile

- **L55 vs L201** — *"Only one other made it out"* (so two survivors) against *"THE THREE RETURNED"*. Either the crowd is chanting the unit's name — Io, Europa, Ganymede, the lion's three heads — or the numbers disagree. As written, a reader does the maths and finds it doesn't work.
- **L225 / L265 / L288 — the cloak does three jobs.** He drapes her in it, it flows around her, and then he pulls it over her again. Pick two.
- **L133 / L221 / L233 — the pistol.** You've settled on laser + recuperator, which makes *"three recoils"* and *"cold steel"* and *"burned-out craters"* all consistent. **Nothing to change** — this is just the note that it's now decided, so don't let an editor talk you out of the recoil.
- **L116 vs the title card (L31)** — the card reads *WAR IDOLS*, the game is **War Idol**. The in-world plural is fine in *"the rules of the War Idols"*; the title card is the one a player reads as the game's name.

---

## C. Grammar / typos — quick wins

- **L55** `in time buddy.` → `in time, buddy.`
- **L57** `bespectacled beady eyes` → `bespectacled, beady eyes`
- **L58** two **catches** four words apart → *"Something snags his eye... before he catches himself"*
- **L80** `Well laugh damn you!` → `Well, laugh, damn you!`
- **L88** `They called it many things like they knew what happened` → `as if they knew` — the sentence is missing its conjunction
- **L89** `End of the world.` → `The end of the world.` (and consider whether *"our pride in the fire sea of Loki Patera"* should be *"the colony's pride, on the fire sea of Loki Patera"*)
- **L104** `launch what the other needs towards each other` → the *"towards each other"* is already carried by *"what the other needs"*
- **L111** `Can't remember the first two bars, or was it three?` → needs a dash: `— or was it three?` And **Pyrrhic** wants its noun — *"a Pyrrhic victory"* — or the word is stranded.
- **L116** `the "White Cow".` → period inside the quote if you're using US style (you are: *license*, *center*, *rumor*)
- **L148** `off of it` → `off it`
- **L157** `Notifications ring off her phone reading off donations` → **two "off"s**, and phones don't *ring off*. `Notifications ring out of her phone as it reads donations`
- **L238** `I told you you were going to` → `I told you that you'd get`
- **L246** `too shining` → `too shiny`
- **L249** `Anyone can film whatever they want on Io, no one can stop you.` → comma splice *and* a pronoun flip (they → you)
- **L255** `Not power in politics or capital nor the barrel of a gun` → `Not power in politics or capital, nor in the barrel of a gun`
- **L291–292** double blank line before the contract → one blank = one paragraph gap

---

## D. Repetition and patterns (worth knowing, not errors)

- **The narrator keeps measuring her by her smallness.** L133 *"small chest"*, L147 *"tiny back"*, L147 *"slim arm"*, L264 *"slender fingers"*, L274 *"tiny arms"*, L203 *"pink pixie"*, L152 *"the goblin"*. **This may be deliberate** — a big man with a cane seeing her as slight — and it *sets up* her winning. But at this density it reads as a tic. Keep two, vary the rest.
- **L175 — one martini glass, four drinks.** *"lifts the martini glass and pours the will-o'-the-wisp... Then the White Cow, and the Peacock, and the Gadfly."* Four pours from one glass. Line up four glasses, or cut to two.
- **L76 — four verbs in one sentence**: *bares / swallowing / emblazoned / commanding*. Split it.
- **L264–265 — three comparisons stacked**: Cicero, divine nymph, alabaster skin. Pick one.

---

## E. Open questions needing your call

- **L112 `ducking left hook`** — minced oath, or the boxer's duck? Still unresolved, and a reader can't tell.
- **L79 `The show only lands harder because of the stairs.`** — whose show? The fall, or his war record? Wrong word at the most important beat.
- **L142 `The transformation bewilders my senses.`** — abstract where everything around it is concrete. What transformation, and what did it feel like?
- **L118–119 and L193–195 — Keno speaks, but as narration.** The `@ cast` line now exists, so `Captain Keno:` works. Two lines where the barman's mouth should be doing the work.
- **L165 `_And I ain't an old man..._`** — an interior aside *inside* a spoken line. It renders as him saying it out loud. Deliberate?
- **L231 `holds it in to a whimper`** — reduced her crying to a whimper, or held it in until she whimpered?
- **L253** `gives them authority` sits in past-tense exposition (*sanctioned*). Fine, but the tense shift is visible.
- **`@ input_name` is never called** — so the player is "Blockhead" from start to finish. Either call it or commit to the default.

---

## F. Opportunities (no bugs, just upside)

- **L264 — the Cicero payoff is sitting right there.** You named the orator; the chapter already dwells on her tongue twice (L173 *"gnaws on the syllables"*, L218 *"lashing tongues"*). Cicero died by the mouth — hands nailed up, tongue pierced. One clause would bind the image to the man.
- **The naming system** — *the Revelation* (the paperwork), *the Apocalypse* (what the Feed sells), *the Horned / bugs / bots* (what people say). One word per tribe, and the tribe identifies itself.
- **The water as the vector** — L100 plants the rumour. That's the first crack in the official story, and it currently sits mid-paragraph. It's a line that deserves its own air.
- **L52 title card** — *WAR IDOLS* centred and large is the first thing a player sees. Worth a `@ page` after it so it holds for a beat.
