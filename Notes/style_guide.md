# War Idol — style guide

Working document. Everything here was decided somewhere in the writing and is
easy to lose between sessions. Nothing is sacred; if a rule is wrong, change it
here first so it stops applying everywhere.

---

## 1. Tense

**Scenes are present. Summarised past events stay past.**

- Present: the recruiter, the fall, the bar, the alley. *"I about-face." · "She snatches it away." · "I accept it."*
- Past, deliberately: the discharge, the buddy's death, the boom and the fathers, the infestation exposition, the bar-crawl and the fight. Those *are* past, and keeping them past makes the shifts meaningful rather than accidental.

Never mix tense *inside one sentence*. That's the one place it reads as an error instead of a device.

---

## 2. The narrator

Hardboiled, dry, terse. He reports; he does not reflect.

**He keeps the subject when he acts, and drops it when he's acted upon.**

| he acts | he is acted upon |
|---|---|
| *"I pull out my las-pistol"* | *"Three recoils."* |
| *"I grab her wrist"* | *"A pipe across my back."* |
| *"I hobble to her"* | *"Four of those spent suspended on a torture rack"* |

That's not a fragment tic — it's dissociation, and the grammar does it for you. The torture is the one place in the chapter where he is purely the patient, so the "I" is correctly absent.

**He amends names privately.** *"Ex-Nemean, I think to myself."* · *"and I ain't an old man..."* He corrects labels in his head and out the side of his mouth, never to anyone's face. Two instances of this make it a habit — use it.

**He does not editorialise about her.** The same man who calls her *the goblin* and *the pink pixie* does not say *divine nymph*. Where she is elevated (Daphne, alabaster) the elevation is *earned* by something that just happened, and it is reported flat.

---

## 3. Naming and register

**One word per tribe. The noun identifies the speaker; you never have to write "she works in media."**

| register | term |
|---|---|
| paperwork / propaganda | **the Revelation** |
| what the Feed sells | **the Apocalypse** |
| what people say | **the Horned**, bugs, bots |
| the Feed | **the Kiss** |
| workers | **the pass** |
| marines | **a dry hump** |
| the platform | **the Feed** · derisively **the Trough** · **the Tube/Tuber** |
| the credential | **the tick** — ticketed, unticked |
| the stage on the vehicle | **the ring** |

Articles carry meaning too: *the pass* is the institution, *a dry hump* is one instance. *The Kiss* is a brand; *a White Cow* is a drink.

---

## 4. Reference and allusion

**He names things. He does not gesture at them.**

His myth references are all proper nouns — **Io, Juno, Argus Panoptes, Cicero, Nemean, Vulkan**. *"The bearing of a divine nymph"* is what someone says when they don't know which nymph; *"Bernini's Daphne"* is what he says. Specificity is the tell, and it's the character.

**And the one thing he can't name is load-bearing.** *"...something older underneath it that I haven't got a name for."* A man who names everything failing to name something is the strongest move available. Don't spend it.

**Never explain an allusion.** Cicero's tongue, Daphne's laurel — readers who know get it, readers who don't lose nothing. Explaining kills it, and the joke is never worth more than the allusion.

**Myth pays off in plot, not in prose.** Naming Cicero and then having her *talk him into a contract* is the payoff. Naming Cicero and then mentioning how he died is a footnote.

---

## 5. Euphemism is the house style

The world names catastrophes like a press office: **the Giant Leap Pioneer Project. The White Cow. The Kiss. The Revelation.** Never name a disaster plainly. That's how real institutions behave and it's the whole satire — the paperwork survives, the meaning changes.

Corollary: **the name is often the lie.** *The Revelation* claims the truth came out. It didn't.

---

## 6. Puns belong to characters, not to the narration

**Characters make jokes at each other. The narration notices consequences.**

*"Old-fashioned huh? But I don't mind that."* is a character being clever. If the *prose* starts winking, the narrator becomes a man performing that he's been through it, and the sincerity built on the stairs and the red pavement is spent.

---

## 7. The Eye

Jupiter's Great Red Spot is the indifferent watcher — *"that mocking red eye."* The visor and the Feed are the **manufactured** eye, and the licence is a **glass badge of an eye**. Keep them rhyming.

The Eye can be **blotted out** — cloud kills Jupiter. The rain is the only privacy on Io. Anything that hides the Eye is a gift; use it for a man who is otherwise always being filmed.

---

## 8. Props do the characterisation

- **His old-fashioned** vs **her martini glass** — tradition and deliberation against glamour and speed. A rocks glass and a cone on the same bar.
- **His tantalum cane** — the implant metal, and the thing they'd put *inside* him. He refuses the graft and leans on it.
- **The cloak** — the emblem rides on the *garment*, not the body, which is what lets him take it off and give it to her. The lion changes owners, and nobody says so.
- **The drinks** — four glasses is a stunt. That's her.

---

## 9. What the narrator never does

- Explains a mechanism. (The recuperator exists in *your* notes, never on the page.)
- Explains an allusion.
- Compliments her.
- Says a brand's word for something when a worker's word exists.
- Uses a pun the *narration* is proud of.

---

## 10. Engine syntax

```
* bold *        _ italic _        ,, sub ,,        ^^ sup ^^
```
Subscript and superscript are custom (`car/vn/script_effect.gd`) — stock Godot BBCode has neither. Single `^x^` also works for superscript. Tilde is **not** a mark; Chip's lines use `~` as style and it renders literally.

**Directives**

```
@ img <name>   @ sfx <name>   @ music <name>   @ cast A=Alpha, B
@ page         @ zoom <f>     @ pan <dx> <dy> [sec]   @ sat <v> [sec]
@ fade [s]     @ glitch [s]   @ shake          @ stage <text>
@ input_name   @ fast [mult]  @ fast off       @ preset name = fx + fx
```

- **A line is dialogue only if the text before the first `:` is ONE word, or matches a name on `@ cast`.** So `Chip:` works; `Our contract: 50/50` stays narration; `Captain Keno:` needs the cast line.
- **A mistyped directive fails silently.** No error, no effect. Check anything starting with `@` against the list above.
- **One line = one click.** Line breaks are pacing. `|` inside a line is an extra click mid-line.
- **Switching between narration and dialogue clears the accumulated narration page.** Use `@ page` at scene breaks and `@ stage` for short interior beats that sit between dialogue.
- **`@ fast` is sticky** (a mode). `@ fast` alone is 4×, `@ fast off` resets. Covers a *run* of lines — a chat flood, radio traffic. `@ fast 100` is effectively instant.

---

## 11. File conventions

- Dialogue files live in `car/vn/dialogue/`, named `NN_scene.txt`. Files starting `_` are ignored by the manifest scanner.
- **Lowercase asset filenames.** `keno.png`, not `Keno.png` — case sensitivity will bite on export.
- Re-run `powershell -File Notes\commission.ps1` after writing; it regenerates `Notes/asset_commission.md`, the list of every img/sfx/music the scripts ask for and which are still missing.

---

## Pre-flight for a new scene

1. Tense: scenes present, backstory past, no mixing within a sentence.
2. Every `@` directive exists in the list above.
3. `@ page` at scene breaks; no mode-flip stutter.
4. Names: one word per tribe, and the noun tells you who's talking.
5. Any myth or historical reference is a proper noun, and unexplained.
6. No mechanism explained, no allusion explained, no compliment from the narrator.
7. Re-run the commission script.
