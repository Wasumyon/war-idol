# The stealth minigame — spec

Status: **design agreed 2026-11-15, not built.** §10 lists what is still open. Project: root `vn/`,
folder `vn/stealth/`. Sources: the bible (Act 3, the heist), `outline.md` beats 16, 18, 27–28, 35,
38, 39, canon 8 and 11, `vn_game_design.md`, `maingame_spec.md` §3 and §5. Replaces the
provisional note `Boundarypush/heist-escape-minigame.md`.

Reference for feel only: the exploration layer of GFL2's Boundary Push (move one leader in real
time, read detection ranges, pick off exposed targets, noise draws the rest). Nothing of that
game's maps, units, names or interface is reused, and there is no battle layer behind it.

## 1. What it is

A short real-time sneak on foot. The player steers the narrator through a guarded space, reads
overlapping patrols, and peels the defence back in layers: bypass, distract, disable, knock out.
Clearing guards is never required. It is used two ways:

- **Story maps** at the outline's stealth beats, with a fixed objective.
- **The job** — a repeatable hub offer, the on-foot alternative to the runner: sneak in, take
  enough pictures to meet a quota, get out, get paid.

A map is 5–10 minutes. Depth comes from a small number of abilities against the layout, not from
map size.

## 2. Decisions

| question | decision |
|---|---|
| Where it appears | Story beats and a repeatable free-slot job |
| Control | One leader (the narrator) in real time; crew are abilities, not bodies |
| Detection | Alarm, then escape or hide. Caught while alarmed = back to the checkpoint |
| Takedowns | Knockout only, always, before and after the reveal |
| Pictures | An aim-mode action: Q, click the subject, it snaps. No hold. The snap makes noise |
| Overlay | Real time shows guard facing and filling meters; Q shows everything. On a debug toggle to compare |
| Character abilities | Only while that character is in the party |
| Bought items | Run improvements and consumables come from the shop |
| Kathay | Remote hacks by default; a body you escort at beats 16 and 18; sets and disarms traps |
| View | 3D, isometric by default, with a top-down camera on a debug toggle to compare |

## 3. Moving and being seen

- **Move:** WASD. Hold a key to crouch-walk: slower, smaller footstep noise.
- **Sight:** every guard has a vision cone drawn on the floor. Standing in it fills that guard's
  detection meter; it fills faster the closer you are and drains when you leave. Walls block it.
  Low cover blocks it only while crouched.
- **Height:** on high ground you are hidden from guards below. A guard on high ground does not see
  the floor below unless he is already alerted.
- **Concealment:** patches (steam vents, sulfur fog, hanging tarps) hide anyone inside them.
- **Hearing:** guards also have a hearing range, drawn as a fainter arc than the vision cone.
  Footsteps inside it fill the detection meter slowly; crouching shrinks your footsteps.
- **Noise:** an action's noise is a **red dashed outline** on the floor with a sound symbol,
  centred on whoever makes it and shown in aim mode before you commit. On the action, a soft
  white ring travels outward from the centre and stops at that outline. **Every guard inside the
  outline who was not knocked out by the action is alerted** and walks to the centre; everyone
  outside it is unaffected. Guards the outline would catch are marked while you aim.
- **Guard states:** patrol → suspicious (walks to what he noticed) → alarmed → searching → patrol.
  A knocked-out guard who is found by another raises suspicion in that guard.

The cones, circles and meters are the AR visor's overlay. That satisfies "no HUD without an
instrument" (`vn_game_design.md`) and gives the reveal something to take away (§10).

**What the overlay shows when** (decided 2026-11-16, to be confirmed in play):

- **In real time:** each guard's facing (a short marker on the floor) and his detection meter
  once it starts to fill. Nothing else.
- **In aim mode (Q):** the full picture — vision cones, hearing arcs, noise outlines, and which
  guards an action would alert.
- This is one exported setting on the segment root, switched from the Debug layer, with three
  values: `always` (cones in real time too), `facing` (the default above) and `aim_only` (nothing
  in real time, not even facing). Play all three on the first map, then keep one (§11 step 8).
  The risk with `aim_only` is that the best play becomes tapping Q every two seconds.

## 4. Aim mode and actions

One trigger key (Q) **stops the world** and opens aim mode. Everything in range lights up with
what can be done to it and the noise circle it would cause. Pick a target, pick the action,
confirm; the world resumes and the action plays. Leaving aim mode costs nothing.

Aim mode is for everything: crew abilities, items, planning and **pictures** (§5). There is one
way to act — stop, pick, confirm — and nothing is done by holding the mouse on a target.

Actions on a target:

| action | who | effect | noise |
|---|---|---|---|
| Knockout shot | Langley | One guard down. Fails on a guard in cover | Medium, at the target |
| Barrel shot | Langley | Sulfur-gas barrel bursts; everyone in the cloud is knocked out, the narrator included | Large |
| Distraction | Chip | Her drone or a hijacked speaker pulls guards to a point for a few seconds | Chosen by the player |
| Open / blind | Kathay | Opens a locked door, or blinds a camera or turret for a while | None |
| Trap | Kathay | Sets a trap on a marked point, or disarms one in the way. Spends her resource | Small |
| Takedown | the narrator | Knock out a guard from behind at arm's length | Small |
| Picture | the narrator | One shot of a subject in line of sight and in lens range (§5) | Medium, at the narrator |
| Gas canister | item | Thrown; a small knockout cloud | Small |

A knockout that another guard sees happening goes straight to alarm. Knocked-out guards stay
down for the rest of the map.

## 5. Pictures

- A picture is an aim-mode action (§4). Press Q, click a **subject** that is in line of sight and
  within lens range, and the shot is taken when the world resumes. There is no focus ring and no
  holding. *(Changed 2026-11-16 from hover-and-hold in real time.)*
- **The snap makes noise** (shutter and flash) by the rule in §3: its red outline, centred on the
  narrator, shows in aim mode while the subject is under the cursor, so you know who will hear it
  before you click.
- The risk is where you stand, not how long you wait: lens range forces you close, the outline
  decides who hears, and distance to danger (below) pays for nerve.
- Each subject — a guard post, a machine, a document, a room — holds a fixed number of **shots**
  and is exhausted after that. Exhausted subjects are marked.
- **Distance to danger** multiplies a shot's worth: the nearer an un-alerted guard's cone is to
  where you stand, the more it pays. A shot taken from safety pays the base value.
- Shots are **banked at checkpoints** and at the exit. Getting caught loses the unbanked ones.
- In the job, the map ends at the exit; the payout depends on banked value against the quota.
  Story maps may carry subjects too (the evidence in Beat 38 is one) but have no quota.

### The job in the fiction

The job is **collecting dirt**, not streaming. The crew photographs fortified positions — the
Ministry's side or the enemy's — and sells the pictures to dark buyers. Nothing goes on the
channel.

- **It pays a lot of cash and little or no Hype or followers.** The runner is the reverse. A
  free slot is a choice between money and audience.
- **The Ministry must not find out.** Being caught on a job is worse than a lost payout: catches
  and alarms on Ministry-side maps feed a trouble flag *(proposed: a Ministry visit, a fine, a
  search of the garage)*, the way the dials' dangerous ends do in `vn_game_design.md`.
- Subjects are what a buyer wants: gun positions, stores, rosters, who meets whom.
- **How the job opens: the loanshark** (author, 2026-11-15; scene not yet placed or written).
  Chip has borrowed from shady lenders. The first payment is made, and the collector — calm, and
  an automaton — produces a clause with compound interest. The narrator threatens him and gets
  nowhere. The collector shows a holodisc: coordinates and the schematics of a base. Do this job
  for his master and the debt is forgiven. That job is the **first stealth map**, scripted, and
  finishing it unlocks the repeatable job offer in the hub.
  - Calendar: a scripted VN segment followed by a `stealth` segment in `story` mode; its
    `outputs` clear the debt and set the flag the job offers require.
  - This answers `vn_game_design.md` open question 3 (the loanshark softlock): the debt is paid
    in service.
- *(mine)* After that the buyer is most naturally the info dealer — Ottenok, then Kathay — or the
  loanshark's master again. Not decided.

## 6. The alarm

- A full detection meter on any guard starts an **alarm** in that area: guards converge on where
  you were last seen.
- Break line of sight and stay unseen for a few seconds and they drop to **searching**, then
  return to patrol.
- Every alarm raises the map's **crisis level** by one for the rest of the run: detection meters
  fill faster, and in the job the payout multiplier drops a step. This is the cost of being loud.
- A guard who reaches you while alarmed **catches** you: back to the last checkpoint, unbanked
  shots lost, crisis level kept.
- Story maps have no fail state beyond the checkpoint, unless the beat scripts one.

## 7. The party

Character abilities exist only while that character is with the crew on that day. The segment's
`args` name the party; the calendar sets it per beat and the job offer derives it from flags.

| who | from | ability |
|---|---|---|
| The narrator | always | Moves, takedown, the camera |
| Chip | always | Distraction |
| Langley | Beat 26 (reorganised crew); earlier where a beat places her | Knockout shot, barrel shot. Limited rounds per map |
| Kathay | After she takes Ottenok's chair (Beat 26) | Remote: open / blind, limited uses. Traps where a map marks points, limited by her resource |
| Kathay, escorted | Beats 16 and 18 only | A body that follows the narrator, makes more noise than he does, and can be told to wait. She can still set and disarm traps |
| Aysel | Beats 38–39 | Her access: some doors and guards let the party pass *(proposed)* |

**Shop items** improve a run and belong to nobody: gas canisters, soft soles (smaller footsteps),
a quieter shutter, a longer lens (more lens range), extra rounds for Langley, extra
resource for Kathay. They join canon 11's shop lines as personal gear and streaming gear.

## 8. View

- 3D, orthographic camera, fixed isometric angle. Walls between the camera and the narrator fade
  or cut away.
- Grey-box rooms and capsule or chibi stand-ins first. Characters sit behind one scene each so
  the modeller's work replaces them without touching the game.
- The camera is a rig with two presets, isometric and top-down, switched from the Debug layer.
  Build the first map, play both, then keep one. Recommendation: isometric, because characters
  and height read better; top-down only wins if cones behind walls prove unreadable.

## 9. Segment contract

A `minigame` segment like the runner (`maingame_spec.md` §5). Root scene
`res://stealth/stealth.tscn` with `signal finished(result: Dictionary)` and `func begin(args)`.
It never changes scene, advances the day, or writes the save.

`args`:

| key | meaning |
|---|---|
| `map` | which map scene to load |
| `mode` | `job` or `story` |
| `party` | list of ids: `chip`, `langley`, `kathay`, `kathay_escort`, `aysel` |
| `quota` | job only: the banked value that counts as met |
| `items` | consumables carried in |

`result`:

| key | meaning |
|---|---|
| `outcome` | `clean` (no alarm), `loud` (one or more alarms), `short` (job left under quota) |
| `footage` | banked shot value |
| `alarms`, `catches`, `knockouts` | counts, for outputs and later scenes |
| `flags` | story flags a map sets (a subject filmed, an optional room reached) |
| `items_used` | so `Game` can deduct them |

The calendar's `outputs` choose a set by `outcome`, as the runner's do by `capture` / `miss`.
Knockouts do not feed Bloodlust.

Files: `vn/stealth/stealth.tscn` and `.gd` (the segment root), `guard.gd`, `player.gd`,
`subject.gd`, `noise.gd`, `aim_mode.gd`, `camera_rig.gd`, `maps/*.tscn`. Maps are data: guards
with patrol paths, subjects, cover, concealment, checkpoints, exit, barrels, trap points.

## 10. Open points

- **The job's loose ends** (§5): who the dark buyers are, what the Ministry trouble event is, and
  what "the enemy's fortified areas" look like through the visor before the reveal — a colonist
  position rendered as a nest, whose pictures would mean something else afterwards.
- **The overlay after the EMP.** Cones and circles are the visor's. In beats 35–39 the visors
  are dead or untrusted. Either Kathay's intrusion supplies the overlay, or the late maps run with
  less of it. Story decision.
- **Aysel's ability** and whether she is a body on the heist map.
- **The recruiter's standoff** (Beat 38) is a VN scene inside the map or after it.
- **The cost of getting out** (Beat 39): whether the escape reuses the heist map alarmed.
- **Numbers:** cone sizes, meter speeds, shots per subject, the distance multiplier, crisis
  steps, uses per ability. Tuned on the first map, then written here.
- **Controller and touch** are out of scope.

## 11. Build steps (commit before each)

1. Grey-box test map, the narrator's movement, crouch, the camera rig with both presets.
2. Guards: patrol paths, cones, detection meter, the state machine, the alarm and the checkpoint.
3. Noise circles and concealment, cover and height.
4. Aim mode, with the narrator's takedown and Chip's distraction.
5. Pictures as an aim-mode action: subjects, lens range, shots, distance to danger, banking.
6. The segment root: `begin(args)`, `finished(result)`, and one job offer in `calendar_data.gd`.
   Extend `tests/first_shot_campaign` to play it headless (0 failures).
7. Langley, barrels and gas. Kathay remote, then traps, then the escort.
8. Play both camera presets and settle §8; play the three overlay settings and settle §3. Tune
   and record the numbers.
9. Story maps, one per beat, each after its beat is approved in the outline.
