# War Idol — how every agent works here

Every AI agent reads this file first, whatever tool it runs in. `CLAUDE.md` is the map of the
project (engine, folders, code rules). `STATUS.md` says what is being worked on now.

## Who does what
| who | role |
|---|---|
| **Wesley** | Director. Writes the story, decides canon, playtests. Nothing is "done" until he has played or read it. He knows little code: explain in plain words, say what changed and how to check it. |
| **Claude** | Lead. Story discussion, canon and outline work, design, specs, architecture, review. Writes tickets for the builders, checks their work, keeps `STATUS.md` and the decisions log. |
| **GPT, DeepSeek** | Builders. Do one ticket at a time: building from a spec, file moves, path fixes, converting script text, tool scripts, mechanical punchlist items. Wesley starts them (Codex or opencode) with "do ticket NNN". |
| **GPT, Grok (images)** | Image generation from a written brief. Output goes to `source_art/` first; Wesley picks what goes into `game/`. |

**All work is built directly in `game/`.** There is no separate area for AI-written code and no
rewrite step before it counts. What makes work count is the tests passing and Wesley playtesting it.

**When Claude is out of tokens,** GPT may carry on with build work: take the next open ticket, or
the next item under "Next" in `STATUS.md`. Story, canon and design decisions wait for Claude and
Wesley; note them in `STATUS.md` under "Waiting on Wesley" or in `docs/story_inbox.md`.

## What wins when files disagree
1. A decision in the decisions log that is not yet applied (Claude Project, `claude/decisions.md`).
2. `docs/io_story_bible.md`
3. `docs/canon/`
4. `docs/outline.md`
5. The written scenes.

**The writing is provisional until whole chunks are written out.** Do not "fix" canon to match a
draft, or a draft to match canon, without asking Wesley.

## Every session
1. Read this file, `CLAUDE.md` and `STATUS.md`. Claude also reads the decisions log.
2. Say the task back in one sentence before starting.
3. Load only the files the task needs. Never load art, `.import` files, `build/`, `_archive/`,
   or files starting with `_`.
4. One task per chat. Do the work.
5. Hand off (see below).

## Stop and ask
Stop and ask Wesley; do not guess and carry on. This applies when:
- a story or character question comes up that the docs do not answer;
- the task would change the bible, canon or the outline;
- the ticket and the code disagree, or the ticket is unclear;
- a test fails for a reason outside the task.

A builder who cannot ask directly writes the question at the top of its report and stops there.

## Story ideas that turn up mid-build
Wesley gets story ideas while working on the minigames. When he mentions one, add it to
`docs/story_inbox.md` in his own words with the date, then go back to the task. Do not act on it
and do not edit canon. Claude sorts the inbox into the decisions log in a story chat.

## How a feature moves
idea → decision (log) → written into its home doc → spec in `docs/` → ticket → built in `game/`
→ tests say 0 failed → Wesley playtests → done.

The runner and stealth are playtested through game jams. Jam feedback goes into
`docs/punchlist.md`, not straight into code.

## Tickets (Claude → builders)
One file per job in `docs/tickets/`, from `docs/tickets/TEMPLATE.md`. A ticket carries everything
the builder needs, including any decision from the log, because builders cannot see the log.

Builders:
- do only what the ticket says and touch only the files it lists;
- never edit `docs/io_story_bible.md`, `docs/canon/`, `docs/outline.md`, `docs/style_guide.md`
  or the scene text in `game/story/scenes/` unless the ticket is a script conversion;
- when converting script text, copy the words exactly. Never reword, trim or "improve" them.
  Flag anything odd in the report;
- run `powershell -File tools/run_tests.ps1` and report the result.

## Git
- Commit without asking: one step, one commit, with a message that says what changed.
- Commit before any risky step (moves, renames, bulk edits).
- Push when a whole chunk is finished and the tests pass. Remote: `https://github.com/Wasumyon/war-idol`.
- Canon, bible and outline edits are committed only after Wesley has said yes to them.

## Hand-off (end of every session)
- Commit.
- Update `STATUS.md`: what is done, what is next, what is blocked or waiting on Wesley.
- Claude: log any decision made in the chat; mark the ticket done after checking the work.
- Tell Wesley in plain words: what changed, how to see it in the game, what he needs to decide.
