# The Chaac run — spec

Status: **draft, not approved.** Replaces the cold-open shooter (`game/story/opener/`) on Day 1 with a
playable Battle of Chaac Patera in the runner, ending in `00_prologue`. Sources: the bible,
canon §4, §6, §12, §15, `outline.md` Beat 01, `main_spec.md` §5, the `sandbox/slice/` prototype.

## 1. Why

The first thing the player touches is the core game: the same five lanes, the same mouse, the
same reticle. At Chaac the mouse is a gun. On Day 1 it is a camera. The player learns the runner
by killing, and the rest of the game recontextualises it.

This reverses `_archive/HANDOVER_2026-11-16.md`'s "playtest the cut before adding an introduction".

## 2. Decided (2026-11-15)

- **The narrator commands the tank, and the order to push into the tide is his.** "Forward!"
  is what puts the tank in front of the wave. Canon §4 applies with full force: he never
  thinks about it, and **the page never says it was his order** — not in the prologue, not
  later in his narration. Other characters may.
- **The vehicle is a cheirosiphon, "Cheiro" for short**, crew of four: driver (the pilot),
  comms, leader (the narrator), gunner (canon §15). Never "tank" on the page; that is the
  engineer's name and an old Earth word (canon §10). Outline Beat 01 says APC; it changes at
  the docs step.
- **The crew call him "Dek"**, the clipping of *dekarchos* (§15). *Archos* is the fallback if
  playtests read "Dek" as his name.
- **The unit is the Nemean Cohort** (the Latin form, for readability). *Tourma* and the other
  Greek forms go in the dossiers.
- **The player names him at New Game**, before the briefing (§11). `03_car`'s name prompt goes;
  Chip still asks and he answers. Bible and canon §8 updated.
- **The Ministry's official word is *the Invasion*;** it says *the Infestation* too, depending
  on context. The briefing says *Invasion*.
- **"Landtide" is one word** (canon §12 updated).
- **The tide breaks over them.** The missile knocks him out just before the wave hits; the
  prologue's buckling is a *second* set. The line is now *"There… shouldn't be another
  landtide so soon?"* (`00_prologue.txt` updated).
- **The date is Jovian Standard.** The colonies still court Earth's support, so the official
  count keeps the Terran year Earth can read, branded as their own: `JOVIAN STANDARD 4050.163`
  (year.day). §15's quiet "year zero" can arrive later as the reform's own reckoning.
- **The crew and the Three overlap, but not by rule.** Some of the Three (§6) may be his
  Cheiro crew; none has to be. **At least one crew member from the opening shows up later**,
  and the player should be left to guess which, if any, of the others were in the Cheiro.
  Never confirm it on the page; voices, callsigns and the roll call are the clues.

## 3. Proposed, waiting on a yes

- **Roll-call payoff.** In the prologue, Bartok's roll call (*"I know all of them. Then
  mine."*) calls the name the player typed at New Game, and he cannot answer.
- **The briefing speaks Ministry; the crew speak the street.** The form says *the Settling*;
  the pilot says *landtide* (§15, language is allegiance).

## 4. Open

- **Ground "bugs".** Does the gun hit only machines, or also the visor-rendered ground enemies?
  Drones only keeps him clean; bugs make the player complicit before the twist.
- **The crew's names**, whether Bartok is comms, and which crew member is the one who
  returns.

## 5. The sequence (~2 min)

| # | beat | length | what the player does |
|---|---|---|---|
| 0 | **Briefing** — typed onto the visor as it boots (after New Game and the name, §11) | ~15s | read |
| 1 | **Ingress** — empty lanes, sulfur vents, crust cracks | ~15s | strafe |
| 2 | **Contact** — crossing drones, a few at a time | ~20s | shoot |
| 3 | **Pressure** — hover drones, emitters, first laser. The tide appears: a dark line on the horizon | ~25s | duck, shoot |
| 4 | **The order** — the tide is close; chatter (§6) | ~5s | — |
| 5 | **Power phase** — unlimited boost, super armor, drones flood in; the crest grows to two storeys | ~15s | shoot freely |
| 6 | **The sputter** — boost meter flickers, steering drifts half a second; chatter | ~4s | control briefly lost |
| 7 | **Missile** — lock-on warning on the left edge, unavoidable; impact just before the crest | ~2s | — |
| 8 | **Black** — hold, silence | ~2s | — |

Then `00_prologue` opens with `@ wake` (§8).

**Who the player is.** The player is Dek. The mouse is his cupola gun (the shooter crewman
works the main gun, scripted). Steering is his calls to the driver, which is why the driver
panicking in beat 6 takes control away.

**Briefing draft** (placeholders in brackets):
```
JOVIAN STANDARD [4050.163] · 4TH MONTH OF THE INVASION
NEMEAN COHORT — THE PROUD LIONS OF THE JOVIAN SYSTEM
VANGUARD // CHAAC PATERA
DEKARCHOS [NAME], COMMANDING CHEIROSIPHON [HULL NO.]
NEXT SETTLING: T+40
HOSTILE CONTACT. ARM UP.
```
`NEXT SETTLING: T+40` is the tide clock the ground proves wrong (§12).

**The tide, by canon §12.** Feet first: camera rumble, then the horizon dips and rises, then the
dust front crosses the plain. "Exaggerated" means a shorter wavelength, not a bigger number: a
steep set, not a 100 m wall. Where the crust parts it glows.

## 6. Chatter (draft)

Subtitled radio, not VN text boxes. The runner keeps running underneath.

> **PILOT:** Dek! I ain't never seen a landtide this big! We gotta turn back!
> **DEK:** BELAY THAT! We turn, we're sitting ducks! The next column's counting on us! Burn it to the bunker — FORWARD!

*(power phase)*

> **PILOT:** We're not gonna make it — abort! Abort!
> **DEK:** EYES ON THE ROAD, PILOT! Bogey, nine o'clock — MISSILE!

Comms (Bartok?) relays the net throughout as background orders.

## 7. Mechanics: changes from `sandbox/slice/`

| car (filming) | Chaac run (gunner) |
|---|---|
| LMB takes a snap | LMB fires the cupola gun; heat or cooldown so it is not a bullet hose |
| drones only shoot | drones take hits and explode (`drone.gd` needs `take_hit()`, like `fighter.gd`) |
| followers, money | no score; **hull** replaces shields; no game over — hull at zero cuts to beat 7 |
| Ctrl duck | same, read as dropping into the hatch |
| Shift dash | the Cheiro's **blast engine**; in beat 5 unlimited, with super armor |
| random spawner | an **authored wave timeline** (below) |

**The blast engine callback.** At Chaac the engine gives boost *and* super armor. Later, the
engine salvaged from the Chaac wreck goes on Isabella (outline, "boost vs super-armor
trade-off") and makes you choose.

**Wave timeline.** A list of timed entries the spawner plays instead of rolling dice:
`{t, kind, params}` — e.g. `{t = 18.0, kind = "drone", mode = "cross", side = -1}`,
`{t = 40.0, kind = "tide_start"}`, `{t = 62.0, kind = "chatter", id = "order"}`. The same
format later builds the hand-made easy / medium / hard routes.

**One runner, two weapons.** `weapon = gun | camera` decides what LMB and the reticle do.

## 8. `@ wake` (VN effect)

Opens a scene from black. Each click is a blink: an eyelid mask opens a little wider and the
audio bus low-pass rises from muffled toward clear. After N blinks (3–4) the image is fully
open and normal clicks resume. In `00_prologue` it opens onto `leg_pool` ("blackness opens"),
and the next click is *"A leg."* Battle ambience plays under it, far away, then near.

## 9. Segment and calendar

- `minigame` segment `d01_chaac_run`, scene `res://minigames/runner/runner.tscn`,
  args `{weapon = "gun", timeline = "chaac"}`, returns `{}`. It never fails: every path ends at
  beat 8.
- Day 1 becomes `[d01_chaac_run, opening VN]`. The opener (`game/story/opener/`) is retired.
- The segment contract of `main_spec.md` §5 applies: `begin(args)`, `finished(result)`, no
  scene changes.

## 10. Build order (commit before each)

1. **Build the run** in `game/minigames/runner/` (a new scene beside `run.tscn`, so the filming
   run stays): gun mode, `drone.take_hit()`, hull, the wave timeline, the tide set piece, chatter
   subtitles, the scripted missile. Placeholder art and text. Playtest the feel.
2. **Write down what step 1 proved:** the timeline format and the two weapons, in this spec.
3. **Wrap it** behind the segment contract; `GameState.lane_x()` moves out of `GameState`.
4. **`@ wake`** in `vn.gd`; add it to `00_prologue.txt`.
5. **Calendar:** Day 1 swaps the opener for `d01_chaac_run`; update the campaign test.
6. **Docs:** `outline.md` Beat 01 (tank, the order), `main_spec.md` §1 and §2 Day 1,
   the bible (naming), `CLAUDE.md`.

## 11. Front end: title menu and name entry

Amends `main_spec.md` §5 step 1: a fresh launch boots to the title, not straight into the
calendar.

**Look.** Simple green, techy: phosphor-green text on near-black, monospace, thin rules, a
faint scanline. It is the **same palette as the visor**, so the first screen the player sees
already speaks in the voice of the device that lies to him.

**Title menu.**
| item | does |
|---|---|
| CONTINUE | only when a save exists; resumes through the calendar as today |
| NEW GAME | asks to confirm if a save exists (there is one campaign save), then name entry |
| SETTINGS | master / music / sfx volume, fullscreen, text speed; saved apart from the campaign |
| QUIT | |

**Name entry** (the visor booting): `NAME: ____`. Not "callsign": Chip later asks *"what do I
call you"*, and `{player}` is used as a name throughout. Empty falls back to the
default, **Phoroneus** (canon §4). Then the briefing (§5 beat 0).

**Debug builds.** The title shows in debug builds too; F3's Debug layer is unchanged. Add a
`--skip-title` command-line flag (and use it in `tests/first_shot_campaign.tscn`) so tests and
quick iteration go straight to the calendar.

**Build.** Independent of the runner: it can land before the Chaac run, with the briefing as a
placeholder screen that hands off to today's opener. Touches `game/main/`, a new `game/title/`
scene, `vn.gd`'s `@ input_name` (removed from `03_car.txt`), and the campaign test.
