# Dossier spec

The in-game files: world tidbits the player collects and rereads. Models: the Files screen in
*Paranormasight* (tabs, numbered list, one entry with sub-headings, highlighted terms and a
picture) and the Event Archive in *13 Sentinels* (a details block, a found counter). Build from
this spec with Sonnet; entry text is story work (Opus) and obeys canon like any scene.

## 1. What it is in Godot

A scene (`vn/dossier/dossier.tscn`), but **not a segment**: it is not in `calendar_data.gd`,
never emits `finished`, never spends a slot. It is an overlay like Pause, owned by MainGame.

- New layer **`Dossier`** (CanvasLayer) in `main_game.tscn`, placed **after `Pause`** in the
  tree and drawn above it (`layer` higher than Pause's). Being later in the tree it sees Esc
  before Pause, so Esc closes the files first, then the pause menu.
- `process_mode = ALWAYS`, so it works while the tree is paused.
- API: `open()`, `close()`, `notify_filed(id)`. Esc or the back button calls `close()`.
- **From the hub:** the `Dossiers` hotspot emits a new signal `dossiers_requested`; MainGame
  connects it to `dossier.open`. The hub never references the layer (its contract stays
  "setup + signals"). The hotspot label shows the unread count: `DOSSIERS · 3 NEW`.
- **From Pause:** a **Files** button between Resume and Quit calls
  `get_parent().dossier.open()`. The tree stays paused; closing returns to the pause menu.

## 2. Entries are text files

One file per entry, `vn/dossier/entries/<id>.txt`, read at startup. `id` is the filename.
Files starting `_` are ignored, as elsewhere.

```
title: The Nemean Cohort
category: military
order: 20
image: cohort_crest
info: Formed | 2187, Callisto
info: Strength | two droungoi

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
  `@ img` (`vn/img/`). `info:` lines are the details block, label `|` value, in file order.
- **`== before` / `== after`:** the pre- and post-reveal versions (§5). An entry with no
  `==` sections has one body for all time.
- **`## heading`** is a sub-heading (accent colour, the little square).
- **Inline marks** are the VN's (`**bold**`, `*italic*`, …, style guide §10), plus two:
  - **`[[id|shown text]]`** a highlighted term linking to entry `id`. Clickable only when that
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

A custom `RichTextEffect`, `vn/dossier/glitch_effect.gd`, `[glitch]…[/glitch]`, built like
`vn/script_effect.gd`: each character is swapped for a random block glyph a few times a second,
with a small horizontal jitter and a colour split. The true letter shows through for a frame now
and then, so a careful reader can half-read it. Span length is kept, so the noise matches the
word's shape.

## 7. Validation and test

`dossier_data.gd` loads and checks the entries. In debug builds MainGame pushes its problems
like `CALENDAR.validate()`:
- unknown category, duplicate `order` in a category, missing image;
- `[[id]]` pointing at no entry;
- `== after` present without `== before` (or the reverse) when both are expected;
- `@ file <id>` in any `vn/scenes/*.txt` naming no entry.

`tests/dossier_test.tscn`: loads all entries with 0 problems; sets `file:a`, checks the New tab
lists it; opens it, checks `seen:a`; sets `REVEAL_FLAG`, checks the `after` text and that `a`
is new again; checks a `{{x|f}}` span renders glitched, then clear after `f` is set.

## 8. Build steps (commit before each)

1. `dossier_data.gd`: parse entries, the two versions, links and glitch spans; validation.
2. `glitch_effect.gd`.
3. `dossier.tscn` + `dossier.gd`: tabs, list, entry pane, counter, toggle, toast.
4. MainGame: the `Dossier` layer; hub `dossiers_requested`; Pause **Files** button.
5. `vn.gd`: `@ file <id>` and the `filed` signal; add `@ file` to the style guide's directive list.
6. Three or four sample entries (placeholder text) and the test. The campaign test still passes.

## 9. Open points (story)

- The final category list.
- **Who wrote the files**, before and after: the Ministry's database, the visor's own
  annotations, Chip's notes? It sets the voice of every entry and who "revises" them.
- Whether glitched spans ever clear **before** the reveal (Act 2's cracks), and on which flags.
- Where `visor_revealed` is set in the outline.
