# Dossier spec

The in-game files: world tidbits the player collects and rereads. Models: the Files screen in
*Paranormasight* (tabs, numbered list, one entry with sub-headings, highlighted terms and a
picture) and the Event Archive in *13 Sentinels* (a details block, a found counter). Build from
this spec with Sonnet; entry text is story work (Opus) and obeys canon like any scene.

**Status (2026-11-16):** built and merged; §8 steps 1–7 and §11 are done. The entries are
placeholders and no scene files one yet; §9 is open. Test: `game/tests/dossier_test.tscn`. In a
debug build, F4 files every entry and F5 toggles `visor_revealed`.

## 1. What it is in Godot

A scene (`game/dossier/dossier.tscn`), but **not a segment**: it is not in `calendar_data.gd`,
never emits `finished`, never spends a slot. It is an overlay like Pause, owned by MainGame.

- New layer **`Dossier`** (CanvasLayer) in `main_game.tscn`, placed **after `Pause`** in the
  tree and drawn above it (`layer` higher than Pause's). Being later in the tree it sees Esc
  before Pause, so Esc closes the files first, then the pause menu.
- `process_mode = ALWAYS`, so it works while the tree is paused.
- API: `open(id := "")` (opens on that entry when given), `close()`, `notify_filed(id)`. Esc or the back button calls `close()`.
- **From the hub:** the `Dossiers` hotspot emits a new signal `dossiers_requested`; MainGame
  connects it to `dossier.open`. The hub never references the layer (its contract stays
  "setup + signals"). The hotspot label shows the unread count: `DOSSIERS · 3 NEW`.
- **From Pause:** a **Files** button between Resume and Quit calls
  `get_parent().dossier.open()`. The tree stays paused; closing returns to the pause menu.

## 2. Entries are text files

One file per entry, `game/dossier/entries/<id>.txt`, read at startup. `id` is the filename.
Files starting `_` are ignored, as elsewhere.

```
title: The Nemean Cohort
category: military
order: 20
image: cohort_crest
info: Formed | 2187, Callisto
info: Strength | two droungoi
source: canon/15_military.md, io_story_bible.md
terms: Nemean Cohort, the Cohort

== before
## The Ministry's Own
The Cohort is the colony's answer to the {{swarm|seen_hive}}. Its tourmarch reports to the
[[ministry|Ministry of Supply]] ...

== after
## The Ministry's Own
...
```

- **Header lines** until the first blank line. `category` must be one of the tab ids (§4).
  `order` sorts the list and gives the number shown beside the title. `image` resolves like
  `@ img` (`game/img/`). `info:` lines are the details block, label `|` value, in file order.
  `source:` lists the repo files the entry's facts come from (never shown in game; see §10).
  `terms:` lists the exact forms of the entry's name that are linked automatically wherever
  they appear (§11).
- **`== before` / `== after`:** the pre- and post-reveal versions (§5). An entry with no
  `==` sections has one body for all time.
- **`## heading`** is a sub-heading (accent colour, the little square).
- **Inline marks** are the VN's (`**bold**`, `*italic*`, …, style guide §10), plus two:
  - **`[[id|shown text]]`** a hand-made link, for wording that isn't one of the entry's
    `terms:` (those link themselves, §11). Links to entry `id`. Clickable only when that
    entry is filed; otherwise plain highlighted text. `[[id]]` alone shows the target's title.
  - **`{{text}}`** a **glitched** span: the visor or the record is unsure of it. It renders as
    noise (§6). **`{{text|flag}}`** clears to plain text once `flag` is set.
- Links and glitches are **pulled out before the mark passes and put back after**, like the
  escapes, so ids such as `nemean_cohort` can't trigger the two-underscore hazard.

## 3. Unlocking and "new"

State lives in `Game.flags`, so nothing new goes in the save format.

- **Filed:** flag `file:<id>`. Set by:
  - a new VN directive **`@ file <id>`** (attaches to the next node like `@ sfx`). `vn.gd` sets
    the flag and emits a new signal `filed(id)`; MainGame forwards it to
    `dossier.notify_filed(id)`, which shows a short toast: *File added — The Nemean Cohort*.
  - a segment's outputs (`{"flags": {"file:<id>": true}}`), for minigames.
- **Read:** flag `seen:<id>`, set when the entry is opened. **New** = filed and not seen.
  When the reveal flips an entry to its `after` version, `seen:<id>` is cleared, so revised
  files come back as new.
- **The dossier never saves.** It sets flags in memory; they are written with the next commit.
  Saving from the pause menu mid-VN would commit the scene's half-applied stat effects, and the
  scene would apply them again when it is resumed. Worst case after a crash: a "new" dot returns.

## 4. Layout (960×540)

- **Top:** back button (Esc), title **FILES**, then tabs: **New · All** and the categories.
  Proposed categories (story to confirm): `people` People, `military` Cohort & Ministry,
  `io` Io & the Colony, `media` Media & Streams, `guide` Field Guide.
- **Left (≈300 px):** scrolling list of filed entries in the tab: number, title, a dot if new.
  A counter under the tabs: `12 / 40 filed` (filed / total entries in that tab).
  Unfiled entries are not listed. (No "???" slots: the total already says how much is missing.)
- **Right:** title, rule, details block, then body (RichTextLabel, scrolling) with the image
  floated right at the top. Post-reveal entries carry a **REVISED** stamp and an
  **Original filing** toggle that shows the `before` text.
- Keyboard and pad: left/right switch tabs, up/down move the list. Links are mouse-only in v1.
- Look: placeholder in the hub palette. Final art direction (CRT/terminal, a Ministry archive,
  Chip's notes) is a later art pass and changes only this scene.

## 5. The two versions

`const REVEAL_FLAG := "visor_revealed"` in the dossier script. Before it is set, entries show
`before`; after, `after` (falling back to the single body). Where in the outline the flag is
set is an outline decision; the dossier only reads it.

## 6. Glitched text

A custom `RichTextEffect`, `game/dossier/glitch_effect.gd`, `[glitch]…[/glitch]`, built like
`game/script_effect.gd`: each character is swapped for a random block glyph a few times a second,
with a small horizontal jitter and a colour split. The true letter shows through for a frame now
and then, so a careful reader can half-read it. Span length is kept, so the noise matches the
word's shape.

## 7. Validation and test

`dossier_data.gd` loads and checks the entries. In debug builds MainGame pushes its problems
like `CALENDAR.validate()`:
- unknown category, duplicate `order` in a category, missing image;
- `[[id]]` pointing at no entry;
- `== after` present without `== before` (or the reverse) when both are expected;
- `@ file <id>` in any `game/scenes/*.txt` naming no entry;
- a `source:` path that doesn't exist (checked in the test, which runs from the repo).

`tests/dossier_test.tscn`: loads all entries with 0 problems; sets `file:a`, checks the New tab
lists it; opens it, checks `seen:a`; sets `REVEAL_FLAG`, checks the `after` text and that `a`
is new again; checks a `{{x|f}}` span renders glitched, then clear after `f` is set.

## 8. Build steps (commit before each)

1. `dossier_data.gd`: parse entries, the two versions, links and glitch spans; validation.
2. `glitch_effect.gd`.
3. `dossier.tscn` + `dossier.gd`: tabs, list, entry pane, counter, toggle, toast.
4. MainGame: the `Dossier` layer; hub `dossiers_requested`; Pause **Files** button.
5. `vn.gd`: `@ file <id>` and the `filed` signal; add `@ file` to the style guide's directive list.
6. `tools/stale_dossiers.ps1` (§10).
7. Three or four sample entries (placeholder text) and the test. The campaign test still passes.

## 9. Open points (story)

- The final category list.
- **Who wrote the files**, before and after: the Ministry's database, the visor's own
  annotations, Chip's notes? It sets the voice of every entry and who "revises" them.
- Whether glitched spans ever clear **before** the reveal (Act 2's cracks), and on which flags.
- Where `visor_revealed` is set in the outline.

## 10. When canon changes

Entries are **presentation, not source**. A fact lives in the bible or a canon file; an entry
retells it in-world and names those files on its `source:` line. Rules:

- Never put a new fact in an entry first. Settle it in canon (or `claude/decisions.md`), then
  write or revise the entry.
- Write entries late: an entry for a topic waits until its canon file has stopped moving. Until
  then the build uses placeholder entries.
- **Staleness check:** a tool script, `tools/stale_dossiers.ps1`, lists every entry whose
  `source:` files have a later git commit than the entry itself. Run it after a canon session;
  each hit is an entry to reread (often still fine), not an automatic rewrite.
- A canon change that renames a thing (*Tourma*, a unit, a place) is also a grep across
  `game/dossier/entries/` and the `[[links]]`; validation catches broken link ids.

## 11. Terms in the story

A file opens only once the story has shown it (`@ file`, §3). From then on, **every**
appearance of one of its `terms:` is underlined, so a player who forgot what *the Kiss* or the
*Nemean Cohort* is can check it at any point.

- **Where:** VN dialogue and narration (`vn.gd`), and dossier entry bodies. Not choice buttons,
  the phone or the hub.
- **When:** a term links only if its entry is filed **when the line is shown**. The line that
  carries `@ file <id>` is already linked, so the first mention is the first underline. Before
  that the term is plain text: no locked links, no spoilers.
- **Matching:** case-sensitive, whole words, longest form first (*Nemean Cohort* wins over
  *Cohort*). Writers list every form they use (`Nemean Cohort, the Cohort`). A backslash before
  a term's first letter (`\The Kiss`) leaves that one occurrence plain, for an ordinary use of
  the words. Text inside a `{{glitch}}` span is never linked. Linking runs before the inline
  mark passes, like `[[ ]]`.
- **Look:** underline in the accent colour, regular weight. Every occurrence, but quiet.
- **Click:** opens the dossier on that entry (`dossier.open(id)`). The click must not also
  advance the line: `vn.gd` swallows the click that hit a link. Opened from the VN, the
  dossier pauses the tree and unpauses on close (unless the pause menu was already open).
- **Validation:** a term listed by two entries; a term that appears in a scene before any
  `@ file` of its entry (warning only: usually a missing `@ file`).
- **Build:** after §8 step 5, as step 5b, with a test case: a filed term is underlined and
  clicking it opens the entry; an unfiled one is plain; `\Term` is plain.
