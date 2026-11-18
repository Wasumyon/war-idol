WAR IDOL -- GAME DESIGN
=======================

The game design document: how the game plays. The day, the runner, the other minigames,
money, the hidden story stats, what the player sees, teaching, saving and scope. Where a
spec owns the detail, this gives the short version and points to it.

Canon 11 keeps the campaign beats -- the 40 days, checkpoints, Kathay's arrival, the shop
lines. The story bible keeps the fork and the endings. This document owns the systems.

Open questions are marked [OPEN]. The author's decisions are unmarked. Anything marked
"(mine)" is an observation from the design pass and "(proposed)" a suggestion; neither is
a decision. "(provisional)" is a decision locked in for now, with numbers to tune in
playtests or a note on what would reopen it.

Written as plain text on purpose -- no markup, so it reads correctly raw.


OVERVIEW
--------

  A hard-boiled sci-fi visual novel on Io, Jupiter's volcanic moon. A broke, one-legged
  veteran partners with Chip, a VTuber covering the war for money. Choices flag special
  events and lead to two endings. Between scenes he drives her rig down a five-lane runner
  while the player films the danger with the cursor. The twist: the AR visors render
  ordinary human colonists as monsters. (Bible, CLAUDE.md.) Feel: tense, scrappy,
  everything costs something; the runner sells danger, it is not a skill wall.

  This document covers the core systems, the runner included. Each other minigame's
  detail lives in its own spec: stealth in docs/stealth_spec.md, Tunnel in
  docs/tunnel/design.md and docs/tunnel_port_plan.md, the Chaac run in
  docs/chaac_run_spec.md. STEALTH AND OTHER MINIGAMES gives one paragraph each.

  Length: 40 in-game days, two slots a day; roughly 24-28 story days and about 12 free
  days, so about half the 80 slots are the player's (docs/main_spec.md).
  Platforms: PC (Godot 4.7, 960x540). Browser demos of each minigame on itch.io for
  playtests, exported from the same code (docs/demo_spec.md).

  Content warnings (mine, from the material so far): war violence and death, a disabled
  veteran, debt and predatory lending, propaganda, sexualised streaming culture, stalkers,
  a fan who enlists after watching Chip's videos.
  [OPEN] Audience and the age rating aimed at.
  [OPEN] Playthrough length in hours, and the rough split between VN, runner and stealth.
  [OPEN] Release platform; controller and touch (out of scope for stealth, open elsewhere).
  [OPEN] The content-warning list and where the player sees it.


TARGET EXPERIENCE                                     (proposed -- not yet settled)
-----------------

  Agreed in spirit only (decisions log 2026-11-17, an [idea]). The eight kinds of fun from
  MDA (Hunicke, LeBlanc, Zubek, 2004): Sensation, Fantasy, Narrative, Challenge, Fellowship,
  Discovery, Expression, Submission. Pick the feelings first, then judge every mechanic by
  which one it serves.

  Core       :  Narrative (the hard-boiled story, two endings). Fantasy (the MC, a gutter
                veteran and a War Idol of a different kind, keeping a reckless streamer
                alive). Sensation (the runner's danger must feel dangerous).
  Supporting :  Expression (VN choices, the rig's name, the lane pick). Discovery (snap
                shots, hidden event flags, the dossier's glitched entries). Challenge
                (optional only: grazing and upgrades, never a gate).
  Fellowship :  simulated -- chat, followers, super chats. It pays off as Narrative: Chip's
                concert scene where she meets a fan, and the dark turn that her videos
                inspired that kid to enlist.
  Avoid      :  Submission as grind.
  Per section: VN scenes -> Narrative, Expression. Runner -> Sensation, Fantasy; Challenge
  only through grazing. Snap shots and the dossier -> Discovery. Chat -> Fellowship.

  Rules of thumb:
    -  Chat reacts to the footage the player actually got, not generic lines.
    -  Signal hidden content: gallery silhouettes, Chip's "chat would've lost it" hints, a
       rare-shot tally after a run.
    -  Effects loud, lanes and hitboxes readable. Juice must not sneak difficulty back in.
    -  Seed the dossier's glitches early, so the "AR lies" lane pick after the EMP is earned.

  Playtest questions: which moment felt tense, which felt like you, when did you want to
  know what happens next. A beat whose answers miss its target needs work.
  [OPEN] Settle this section; then tag the outline beats with their targets.
  [OPEN] Chip's concert scene and the fan kid who enlists: not in canon or the outline yet.


THE DAY
-------

  The calendar drives the game: 40 days, a checkpoint every five, two slots a day (day and
  evening). Detail: docs/main_spec.md. A scripted slot plays fixed segments in order, VN
  scenes or minigames. Some days skip the hub (Day 1, the ice sequence, captivity). A
  free slot opens the hub, which lists every offer the player qualifies for: runner
  routes, the stealth job, interviews, evening scenes. Story days give Hype its floor;
  free slots give its window (THE METER).

  Canon 11's loop: choose a route (easy / medium / hard) -> vehicle mission -> shop ->
  canteen or evening scene. A route is a map (THE RUNNER). The shop is a hub hotspot,
  not a slot.

  A free slot is a choice. The runner pays audience: followers, donations, Hype. The job
  pays cash: a lot of money, little or no Hype (docs/stealth_spec.md, section 5). Rest pays no
  money but is never a net zero: it repairs, prepares and restores Hype (REST, below).
  Resting every time is still the only way to lose (MONEY).

  Checkpoints are a story gate on days 5, 10, ... and a debt wall (MONEY); main_spec also
  assumes a save to return to. Only the gate is built.
  [OPEN] Where interviews sit: free-slot offers, part of runs, or both (Watcher 6, outline
         Beat 12, is a story beat).
  (proposed) Interviews are VN scenes in design and code: dialogue and choices that set
  flags and move Hype or followers, built with the VN engine, not as a minigame. The hub
  lists them as offers like any other.
  [OPEN] Whether a warstream is its own segment or simply what a runner run is.

  THE OPENING CYCLES                                              (provisional)
    One new system per 5-day cycle, so the player is at home in the runner before
    anything else arrives.
      -  Cycle 1 (days 1-5): the runner, about 6 runs counting Day 1's Chaac run. Rest,
         repair and the hub's offer list come in here. The first interview (finding a
         connection) lands on day 2, afternoon, after three runs, as the first non-runner
         choice (author, 2026-11-17). It is a forced encounter, not a hub offer: it carries
         story canon and introduces the interview mechanic. Wall 1 on day 5 is easy to clear.
      -  Two creditors (author, 2026-11-17). The starting debt is the bank loan that set up
         the operation; the walls are its payments. The loanshark acts for a mysterious
         client, and it is the client who pays off the rest of the bank debt. From then on
         Chip owes the client, through the loanshark.
      -  At wall 1 the loanshark appears. He has watched the stream, and as a favour to a
         rising up-and-comer he offers to buy out the debt -- the bigger walls ahead look
         impossible. The buyout is scripted and does not need a missed wall. He asks for
         nothing yet (author, 2026-11-18): Chip takes it as a gift from heaven, the MC is
         skeptical, and the wait builds the tension.
      -  Cycle 2 (days 6-10): partway through, the audition shows up in the mission menu as
         an optional event, the first stealth map (author, 2026-11-18). The MC calls it
         fishy. The holodisc with the base plans is handed over at this event, as its
         briefing. The target is a secret facility, ARGUS.
           Take it: after the mission the MC realises what they just broke into and wants
         out; Chip had fun and likes the pay; the MC asks her to trust his gut. At wall 2
         the player can press him for information.
           Refuse it: at wall 2 the job is forced on the player, with the interest trap.
      -  Wall 2 on day 10 is the fakeout: the interest fine print. The rigged system shows
         itself; the player was set up, not careless. The interest hits either way; taking
         the audition early is read as passing a test. The servitor congratulates the
         player, the praise scaled to how well the audition went (a minimum clear gets the
         sneer, STEALTH), and the MC tells him where his client can shove it. It is a
         scripted story beat, not a real miss: every player gets it, however much they
         earned, so it doesn't break THE ONLY WAY TO LOSE IS TO KEEP RESTING.
      -  After wall 2 the stealth jobs come as special missions to pay down the big debt
         or defer the principal. The next offer stays open; the servitor snickers that the
         player should try to earn it the legitimate way, which can't be done, and the job
         is forced before the next wall. (provisional) How these are spaced over the
         remaining walls (8 in all) is for playtesting.
    Emotional key: the economy is rigged, and the player beats it through persistence,
    courage, creativity and stubbornness. A miss should feel like the system's fault,
    never the player's (MONEY, MISSING A WALL).

  REST
    Rest is a buff, never a net zero. For the MC, rest is planning and reinforcing. Chip
    always wants the adventure, and so does he, but he is a veteran: adventures without
    preparation get you killed. Rest gives the MC a win in Chip's own field, though he won't
    have the words for it.

    Design rule: no skills that don't get used. The game builds the "defence" side --
    preparing, repairing, staying alive -- into something that matters in play.

    Rest does three things:
      -  Repairs: restores HP, so the repair cost is mitigated (MONEY, THE SHOP).
      -  Prepares: a buff to the next played segment -- an extra heart, or any other
         gameplay part of it.
      -  Restores Hype: the audience gets time to miss you (THE METER).

    (provisional) Starting numbers, tune in playtests:
      -  Each rest repairs one point free (one heart). Further damage is billed (MONEY,
         REPAIR).
      -  Each rest offers one prep buff for the next segment, chosen at the table: in the
         runner an extra heart or a full boost at the start; in stealth extra stamina or a
         quieter shutter for one map. A buff lasts one segment and doesn't stack with a
         second rest.
      -  Each rest moves every tired segment type one step back toward full pay.
      -  The buff choice is a short scene: planning at the table, work on the rig.
    [OPEN] Whether rest also nudges a dial or plays a character scene.

    The scene that explains Hype (the MC wins the argument for rest with Chip's own
    analytics) is in Wesley's words in docs/story_inbox.md, 2026-11-17.

    REST, REPAIR, RECON
      Until the scene above plays, the hub shows a single option: Rest. After it, the same
      option is relabelled "Rest, Repair, Recon". The label change is the payoff of the
      scene: the game adopts the MC's view of what rest is.

      There is no pick between the three; rest always gives all three effects. A pick
      between them would be a dead choice: the right answer is almost always obvious from
      the hearts and the Hype, so it would be a chore, not a decision. The one real choice
      in a rest is the prep buff.
      (provisional) Revisit if rest gains more kinds of buff: with enough options that no
      answer is obvious, a pick between them (Rest / Repair / Recon as separate choices,
      each with a focus bonus) could become meaningful again.
        -  Before the scene: rest repairs the free heart and restores Hype. The prep buff
           is a fixed default.
        -  After the scene: the table offers three prep buffs drawn from a pool and the
           player takes one, and every rest rolls for a premium map.
      Design principle: randomness goes into what is offered, not into the result. The
      only roll is the premium map, and it is pure upside, so a miss never costs anything.
      (provisional) A 25% chance per rest. Tune in playtests.

      PREMIUM MAPS EXPIRE
        A premium map expires if not taken: someone else takes the route, the battlefield
        moves. Taking an interview or another kind of slot shouldn't feel punished.
        (provisional) A fixed, visible lifetime: 3 free slots, shown on the phone ("intel
        goes stale in 3"). Scripted slots don't count. The slot before it expires, a warning
        line ("another crew is eyeing it"). Visible beats random: the player can plan
        around it. With only two repeatable types, most players will take a runner slot
        within 3 anyway; revisit the lifetime if more slot types are added.


THE RUNNER
----------

  Chip's rig drives down five lanes. The player dodges with the keyboard and films
  dangerous events with the cursor. Code: game/minigames/runner/.

  CONTROLS (current build)
    A / D strafe, W / S boost and slow, Space jump, Ctrl duck into cover (dodges attacks
    aimed at the filmer, stops filming), Shift dash (super armour, smashes obstacles).
    Mouse aims the viewfinder, right mouse zooms, left mouse snaps.
    [OPEN] Final key layout (the build's two files disagree on Ctrl and S).

  FILMING AND SNAPS
    Holding the viewfinder on a subject earns followers over time; the reticle's colour
    shows the subject's tier, the tag above it the distance multiplier. A snap is one shot
    of a good subject: a burst of followers, then a cooldown. A good shot is a high-tier
    subject, close to danger, well framed; grazes and key events pay most, the burning
    finale most of all.
    A snap has the shape of a harpoon shot: aim -> release -> impact -> closure.
      Weight   :  Chip's camera visibly turns with the cursor; the viewfinder lags a little.
      Read     :  a focus ring tightens and changes colour as the shot gets better.
      Release  :  the shutter (below); the subject reacts and chat reacts.
      Closure  :  the frame shrinks into a polaroid that slides to the corner, its border
                  showing the grade.
    [OPEN] The shot grades and the subject tiers.

  SLOW MOTION AND THE SHUTTER
    In the runner slow motion makes the player sharper. Three tiers, never stacked; the
    strongest active one wins.
      1. Close call    :  a graze. Short and strong, with a cooldown so a run full of
                          grazes is not one long slow-motion run.
      2. Aiming a snap :  viewfinder over a filmable event. Gentle, a slight push-in.
      3. The finale    :  the last seconds before the MC turns back. Held throughout, with
                          the MC/Chip bail-out lines over it.

    The shutter is a hit-stop, not slow motion: a freeze of a few frames, white flash, hard
    click, then full speed again. That jolt is the shot's recoil.
    Sound carries half of it. Slowed, effects drop in pitch, music muffles, a heartbeat or
    Chip's breathing comes up. The click and Chip's line play at normal speed.

    The world slows; the cursor, viewfinder and HUD do not, so aiming never feels sluggish.
    Slowed time must not inflate scores: grazes score on real distance to the hazard.

    Starting values (proposed, tune in playtests): close call about 0.25 s at about 30%
    speed, easing back; aim slow-down about 50%; shutter freeze 2-4 frames.
    Stealth and Tunnel are evasion, where the player steers his own body, so their slow
    motion follows other rules: docs/tunnel/design.md and docs/stealth_spec.md.

  DIFFICULTY: TUNED FOR FEELING
    The VN half has no walls. The runner should make the player feel the thrill of danger
    (Chip, the adrenaline junkie) and the competence of keeping someone alive (the MC).
    Danger is sold through presentation and close calls, not a high failure rate. (Tunnel
    playtesters found the minigames harder than Wesley does.)

    -  Grazes stay: the more dangerous the situation, the more dangerous the footage, the
       higher the points. Close grazing is the skill layer, Touhou-style.
    -  Fake close calls: hazards that graze and leave a sliver of health, felt as clutch saves.
    -  Hidden forgiveness: hitboxes a bit smaller than the art, invisible mercy frames, a
       last hit that leaves 1 HP instead of zero.
    -  Presentation sells it: sound, screen shake, near-miss slow motion, nervous lines.

  FAILURE: NO RESTARTS, THE MC PULLS CHIP OUT
    Grazes pay and hits cost health. When the player would die, the run does not restart;
    it shortens. The MC calls it, and a last few seconds remain to grab points before they
    shuttle back home. Wesley's example:
      MC   :  "Alright! That's as much as she can take."
      Chip :  "No! Just a little more!"
      MC   :  "You ain't gonna take me along with your death wish, we're turning around!"

    The final shots, vehicle smoking and on fire, give amplified points.
    Story progress never depends on score. Any run that reaches the bail-out counts as
    finished; score only affects extras (bonus lines, gallery, optional flags).

    (proposed) Make the final seconds a moment (slight slow motion, a framed last shot).
    Push your luck: a long run is a big score, a short one smaller, every run ends with
    footage. Several sets of bail-out lines by how the run went (barely made it, cut short,
    huge score). Danger rises toward the end, so the pull-out lands at the most intense point.

    (mine) The current build still has R to restart and "RUN OVER" at zero shields.
    Early bail-out is a player choice: turn back early and bank the points. Cheap to add,
    and it adds a choice mid-run. (mine) Who uses it: a player at low HP who can't afford
    the repair, or one who already has the shot they wanted. The burning-finale lines and
    bonus stay with runs the MC calls at the end.
    [OPEN] The bail-out line sets.

  RUN LENGTH
    Leaning 60-90 s for a full run, shorter for the tutorial run. The build runs 90 s.
    [OPEN] Settle segment length (decisions log, still open).

  ROUTES AND LANES
    Routes are maps. Picking a route picks a different map, with different enemies, a
    different background and a different tone. Lanes are only the five positions the
    vehicle can hold on any map. The Chaac run's wave-timeline format later builds the
    routes by hand (docs/chaac_run_spec.md, section 7).
    A route also carries a difficulty, with follower and pay bonuses to match (canon 11's
    easy / medium / hard). Premium maps sit above hard.

  THE LANE PICK
    A separate thing: a story pick that happens inside runs (the rig's naming, the motif).
    Five lanes are part of the title's motif. The idea (decisions log 2026-10-29, [idea]):
    the lane pick recurs in different forms -- chat writes the options, answers under fire,
    the default turns dark, the AR lies after Aysel's EMP, callbacks.
    [OPEN] Where the lane pick appears and what a pick looks like in play.


STEALTH AND OTHER MINIGAMES
---------------------------

  STEALTH
    A real-time sneak on foot, 5-10 minutes a map: steer the narrator through a guarded
    space and take pictures of what is there. Story maps at outline beats 16, 18, 27-28,
    35, 38, 39, plus the audition, the loanshark's first map (an optional event in
    days 6-10, forced at wall 2 if refused: THE DAY, THE OPENING CYCLES). The audition
    opens the job, a repeatable free-slot offer to photograph fortified positions and sell the dirt. The job pays a lot of
    cash and little or no Hype; story maps pay in flags; snaps beyond the minimum pay
    extra. Minimum clear: a few successful snaps clear a map, and with them the player
    can bail out at any respawn point. This is the answer for story-only players. A
    minimum clear of the audition earns the loanshark's passive-aggressive insult, and
    he brings it up again at wall 2. The stealth game is built standalone first, as a
    test for the next game jam. Detail: docs/stealth_spec.md (section 12, minimum clear).
    [OPEN] How many snaps is "a few"; whether the spawn counts as a bail-out point.

  TUNNEL ESCAPE
    An escape sequence like Danganronpa 3's: a short stealth and light-puzzle walk in five
    chambers, on foot, by work lamp. A jam piece, now ported to game/minigames/tunnel/.
    Used at least twice: once after saving Kathay, and again for Aysel's later ambush.
    Not in the calendar yet. It always ends in an escape (deaths are counted, not
    failed), so the minimum clear is reaching the end. Detail: docs/tunnel/design.md,
    docs/tunnel_port_plan.md.
    [OPEN] What it pays, and where the two uses land in the three-act outline
           (docs/tunnel/design.md section 0 still has an old beat number).

  THE CHAAC RUN
    Day 1 opens with a playable Battle of Chaac Patera in the runner, about two minutes.
    The player is Dek, the cheirosiphon's commander: the mouse is his cupola gun, steering
    is his calls to the driver. No score, no pay and no game over: hull at zero cuts to
    the missile, so there is no minimum to clear. It ends in 00_prologue. Draft, not
    approved. Detail: docs/chaac_run_spec.md.


MONEY
-----

  FOLLOWERS AND DONATIONS
    -  Spectacular failures make followers jump massively: people love watching a fail.
    -  Followers raise the baseline donation rate: more followers, a steadier trickle.
    -  Certain actions and recorded moments draw extra donations (super chats) on top.

    Without Hype, followers go stale: dead subs, drying donations (THE METER).
    (proposed) Hype scales these payouts and rewards variety and rest (THE METER).

  REWARDS ALWAYS BEAT COSTS
    Even a disastrous run pays: a reward floor, and a higher ceiling for skill. Core rewards
    come from the filming, so they don't swing much with skill. Skill players get earnable
    upgrades, more spectacle, and close grazing. Balancing is delegated to Claude: numbers
    proposed, then tuned in playtests.

    (proposed) A disastrous run earns about 2x the followers of a clean run and about half
    its donations; a skilled run 2-3x a disastrous run's donations; no run below a set
    donation floor. Followers raise later baselines, so a crash is partly an investment.
    Upgrades are bought with donations, so they track skill; followers are long-term growth.

  THE ONLY WAY TO LOSE IS TO KEEP RESTING
    A player who keeps running always clears the debt walls. One who rests every time
    cannot make the money. Failure comes from choices, not skill. Rest has real value
    (THE DAY, REST), so the price of resting is only the money not earned that slot.

  DEBT WALLS AND THE CLOCK
    A running debt clock, Recettear-style: what is due, when, and how far off the player is.
    It lives on the phone and in the hub, possibly also on the pause screen if that serves
    the narrative. It is not an overlay during scenes or runs, so it keeps the no-HUD rule.

    A wall falls every 5 days, one per checkpoint: 8 over the 40 days.
    Walls are lenient. Floor-level income from about a third of the offered jobs clears
    each wall; the other slots can all be rest. Skill and follower growth make walls
    easier, never required.
      -  The clock reacts: the MC or Chip comment when a wall slips out of reach, so a
         player who keeps resting does it knowingly. No doomed save found hours later.
    [OPEN] The wall amounts.
    [OPEN] Whether the clock also shows on the pause screen.

    MISSING A WALL
      -  Missing should cost something, or the wall means nothing.
      -  The first miss is a fakeout, scripted at wall 2 (day 10): the loanshark's
         interest. It plays like the end, then a scene carries the debt (THE DAY, THE
         OPENING CYCLES). It is a story beat every player gets, not a real miss.
      -  A small shortfall after a real try is forgiven at a price: the gap rolls into
         the next wall with interest.
         (provisional) "Small" means within about 20% of the wall. "A real try" means at
         least a third of the cycle's slots went to paid jobs.
      -  Any other miss restarts the 5-day cycle from its first day. Skipping read
         dialogue keeps the replay cheap, so VN skip of read lines is a must-have
         (SETTINGS).
      -  Earning nothing at all toward a wall gets its own response, written for the
         player testing the limits. [OPEN] What that response is.

    AUTO RUN
      An auto option for the runner, and for later filming minigames, like Nikke's auto,
      for players who mainly want the story. It unlocks per route, after clearing that
      route by hand a few times: the crew are veterans now, it's a cakewalk, on to greener
      pastures.
      (provisional) Unlocks after 3 clears by hand (range 2-4).
      (proposed) Auto pays enough to clear the walls but less than playing by hand: it
      films only common subjects and never earns the low-HP bonus. In the fiction it is
      Chip's autopilot camera.
      [OPEN] Whether the easiest route allows auto from the start for story players.
      Stealth gets no auto, easy mode or skip. Its answer for story-only players is the
      minimum clear: a few snaps, then bail out at a respawn point (STEALTH).

  THE SHOP
    Canon 11's lines: personal gear (armour, lithium, alcohol), streaming gear (lens, gyro,
    signal booster), vehicle (armour, turret, NOS, turbo, treads, suspension), info (new
    zones and routes). Stealth adds its own run items (docs/stealth_spec.md, section 7).
    The phone has a Shop tab.

    A repair cost exists. It fits the scrappy world and the engine-debt gag, and under the
    rule above it is always smaller than the run's rewards. Rest mitigates it (REST).

  REPAIR
    Repair is a choice, made before each runner mission. Damage carries over between
    missions, and the player can head out hurt. There are three ways to fix the rig, each
    with its own speed and price:
      -  The MC does it himself while resting: free (THE DAY, REST).
      -  The garage does it while the rig is idle, because the player took a different kind
         of mission (stealth, an interview): a discounted heart. Varying the work pays twice,
         here and in Hype (THE METER).
      -  Rush repair right before a runner mission: full price plus a premium, for same-day
         work.

    Low HP pays more: the audience smells blood. Filming points get a baseline bonus the
    fewer hearts the vehicle starts with. This applies to the runner and to any later
    minigame that films for an audience. Failure must still cost something, or running on
    one heart becomes the best move: if the MC bails out, the footage is kept but the
    repair bill is full.

    The pre-mission screen shows hearts and the repair price, with repair already ticked,
    so most players just press go. Running damaged is something chosen on purpose.

    AUTO-REPAIR POLICY
      For players who don't want to engage with this, a checkbox: "Always repair before a
      run." The screen explains the trade-off when it is ticked: the rig always starts
      full, but every repair is billed at rush price and the low-HP bonus never applies.

    (provisional) Starting numbers, tune in playtests:
      -  Garage repair (rig idle): about half price per heart.
      -  Rush repair: about 1.5x price per heart.
      -  Low-HP bonus: +10% filming points per missing heart, capped at +30%.
    [OPEN] The base price of a heart, against a run's typical pay and the debt walls.
    [OPEN] What each runner upgrade changes in play.
    Gear comes from the shop, not from follower counts. Follower milestones bring fan
    mail instead, the way real fans post things to streamers they like: care packages,
    letters, odd gifts. (This replaces the old design doc's milestone gear.)
    (proposed) A package can hold a small consumable, a cosmetic, or a letter that opens a
    short scene -- a natural home for the fan kid.
    [OPEN] The milestone counts and what each package holds.

  The loanshark: see THE DAY, THE OPENING CYCLES, and EVENT FLAGS.


THE METER
---------

  HYPE
    Hype is staying fresh in the headlines. Doing dangerous things is not enough on its own:
    unless they are new, you get no activity.

    SEEING HYPE (decided 2026-11-17, reverses canon 11's "nobody sees Hype")
      The player should feel Hype having real effects, so it shows -- but never as an exact
      number.
      -  Analytics: the phone's analytics tab tries to give a Hype %, and the number
         strobes oddly and unpredictably. Hype is too far outside rational compute to
         measure. The joke is the point.
      -  Chip's Hype app: after a scene where Chip argues with the computer over the
         wild numbers, she builds her own app from illogical pieces -- astrology,
         misremembered mythology, what her toast did that morning. Its readout is a
         flame on the phone and in the hub (size and colour), plus a line of her
         reasoning ("toast landed butter-side up: bullish").
      (proposed) Under the nonsense, the flame is honest: it tracks real Hype in rough
      steps, so the player can read when they're going stale. The analytics number
      jitters around the true value within a band, so it is funny but never misleading.
      Randomness stays in the display, never in results.
      (proposed) The app scene sits in cycle 1, soon after the first run where staleness
      bites.
      Both live on in-world screens (phone, hub), so the no-HUD rule still holds.

    Followers are not everything. Without Hype, most of them become dead subs and the
    donations dry up. A big follower count can even hurt you without Hype. A story scene
    can explain this to the player.

    Earned by performing. Every dial below feeds it.

    Rest restores Hype, like leaving a field fallow so it pays out more the next time
    (THE DAY, REST).

    (proposed) In play, Hype rewards variety:
      -  Doing the same kind of segment again and again pays less each time. Switching
         between minigame types keeps the payouts high.
      -  Hype scales the followers and donations a segment pays, and high Hype flags events.
    So far there are only two repeatable types, the runner and the stealth job, unless
    Tunnel becomes a repeatable type too.

    It carries risk as well as pay: high Hype, and high danger, flag trouble events.


THE DIALS
---------

  Two are SIGNED AXES, where both ends have content to write.
  Two are ONE-DIRECTIONAL METERS, where the safe pole is the default and needs nothing
  written for it -- you only accumulate toward the dangerous end. This is why the safe
  pole of Bloodlust needs no "mercy" tree: being sane is the absence of a number.


  1. DRAMA <> SYMPATHY                          [signed axis -- THE DECIDER]
     Provoking, angering, creating problems for an interviewee or any other NPC.

       High Drama    :  [OPEN -- access not yet named]
       High Sympathy :  [OPEN -- access not yet named]

     This is the conduct axis and the only one carrying STORY paths. It picks the
     ending: the sign of the net total decides Whistleblower or Complicit.

     It is a conduct axis rather than a faction one, which is why it works -- it is
     available in every scene. You can offer it in a bedroom, a bar or a car.


  2. JINGOISM / PATRIOTISM <> BLEEDING HEART / CONSPIRACY      [signed axis]
     Propagandistic choices.

       Patriotism side :  access to the Military / Ministry tree.
       Conspiracy side :  access to the Conspiracy tree.
       Cross-effects   :  accosted by peaceniks (flag). Going hard one way costs you
                          the other tree.

     Patriotism is also the Ministry's belonging word (canon 13), so the Ministry's view
     of it belongs on paper -- a status line, a pass, a pay grade -- not in a face. It
     has no true antagonist: the opposite of a patriot is an absentee, not a position.


  3. BLOODLUST -> SANE                     [one-directional meter]
     Violence. Only bloodlust accumulates.

       Gains :  high Hype bonus. Access to the mercs and dangerous-individuals tree.
       Costs :  accosted by gangsters and the like (flag). Lose certain sponsorships.


  4. SEX APPEAL -> FAMILY FRIENDLY         [one-directional meter]
     Flirty choices. Only sex appeal accumulates.

       Gains    :  access to many male fans.
       Costs    :  go too far and you take a backlash from male and/or female fans.
                   Lose female fans at the top end. Lose sponsorships and opportunities.
       Flags    :  stalker trouble events.
       Rewards  :  sponsorship proposals while in the family-friendly range. Does not
                   need to be shown to the player.


EVENT FLAGS
-----------

  LOANSHARK           Buys out the debt at wall 1, scripted, asking nothing yet. Paid
                      back in the audition (optional, forced at wall 2 if refused), then
                      in interest at wall 2 (THE DAY, THE OPENING
                      CYCLES). Later pressure (the old idea: he hacks your computer,
                      damages your car) follows MISSING A WALL and never softlocks.

  SPONSORSHIP         Based on audience. Mostly flavour plus money.
    PROPOSAL

  MAKE-UP             Requires a female audience.

  VIRILITY PILLS      Requires a male audience.

  CONSPIRACY          Event type.
    THEORISTS

  PEACE PROTESTORS    Event type.


TROUBLE
-------

  The dangerous ends of the dials pay more Hype and flag trouble events: stalkers,
  bounty hunters, gangsters, peaceniks.

  The event names the cause, so the trouble IS the feedback. There is no meter to read.
  The stealth job adds Ministry trouble when caught (docs/stealth_spec.md, section 5).


MECHANICS RULES STILL IN FORCE (from canon 11)
----------------------------------------------

  No HUD. A number may only be displayed where the fiction holds an instrument for it --
  the phone, the wallet. Hype's payouts are visible; the meter only roughly, through
  in-world readouts that never give an exact number (SEEING HYPE). The deciding axis
  has no instrument BY DESIGN: sympathy is unmeasurable because it is real. The debt clock
  obeys this: it lives on the phone and in the hub (MONEY).

  Signed axes move +-1 per choice, uniformly. Uniform weights are what keep the marker
  honest, and a consistent marker on every axis choice is how the player infers a tally.
  One marker lands in the intro.

  The ending is [OPEN] -- three models, none settled. See THE ENDING below.

  Hype is floor plus window. The floor comes only from mandatory content and gates the
  story; the window comes from optional content and performance and gates the bonus.

  Hidden gate, diegetic invitation. The player sees a rough Hype (THE METER, SEEING
  HYPE) but never the gate's threshold; the invitation comes as a phone call.
  (Changed 2026-11-17: canon 11 said nobody sees Hype.)

  A locked bonus gate offers a shared fallback, written once, always worth strictly
  less than the full version.

  Nothing gated is load-bearing. A player who missed a gated beat must never meet a line
  that assumes they saw it.

  Sympathy must be a viable playstyle, not the losing one. Because spectacle pays, the
  Drama pole is also optimal play. If sympathy only ever costs, the axis stops measuring
  who he was and starts measuring whether the player engaged with the mechanics.


THE ENDING
----------

  [OPEN -- unsettled. Three models, none chosen; A and B are not compatible. This wants
  settling before the last chapter is written, and will be settled in a dedicated
  session. All are cheap to try.]


  MODEL A -- DETERMINATION

    The ending is the sign of the net Drama <> Sympathy total. There is no final menu.
    Checkpoints record the value for feedback; they do not decide.

    For     :  the ending is the run, and it cannot be contradicted.
    Against :  no scene at the climax, and the man becomes something without ever
               acting. Canon 13 wants Albrecht one scene of self-justification or the
               title is decoration, and this model gives him none.


  MODEL B -- THE OFFERS                                          (proposed)

    The axis decides WHICH OFFERS EXIST. The player decides which to accept.

      -  A high-Drama, established player is offered a seat at the table. Refusing it
         is the betrayal.
      -  A high-Sympathy player is never offered that seat, because nobody would offer
         it to him. He gets a different temptation, framed as relief rather than
         promotion.

    The run sets the menu; the player picks an item. Each ending's cost is set by the
    run, because what is being given up differs in each case.

    An extreme player may face a single offer. That is not lost agency -- they decided
    already, by becoming someone with no other door.

    For     :  the climax is a scene, and it lets him SELL OUT, which is the character.
               Canon 4: he cannot reconcile practicality and morality himself, so he
               subcontracts the job to legitimacy, which makes it absolution. That is
               a choice, not a tally being read out.
    Against :  a middle player can hold both offers and take either, so the ending can
               contradict the run.


  MODEL C -- THE CHOICE

    The author's framing. At the climax the player agrees or disagrees with Albrecht's
    designs, and either supports him or reports him. A straight two-door choice.

    It rules out pure Model A, and it gives Albrecht his scene.

    (proposed) Both doors stay open for everyone; the run sets how each door is framed
    and what it costs. A high-Drama player who reports him gives up the seat they
    earned; a high-Sympathy player who supports him is selling out. This keeps Model B's
    strength (the run prices the choice) without a middle player's ending contradicting
    the run.


  WHAT WOULD SETTLE IT

    Draft the last beat each way, short, and read them. This is a decision made by
    drafting rather than by argument -- twenty lines each would show it.

  [OPEN] How the run feeds the fork. A scene fork rules out pure Model A.
         docs/main_spec.md assumes neither: days 31-40 are gated on a route flag.


WHAT THE PLAYER SEES
--------------------

  Only what the fiction holds an instrument for. No meters, except Hype's rough in-world
  readouts on the phone and in the hub (THE METER, SEEING HYPE).

  The phone: the HUD layer holds only the phone (docs/main_spec.md, section 4). Its Feed,
  Wallet and Shop tabs show followers, the balance, the rig debt and its installment
  (game/ui/phone.gd). The debt clock lives here and in the hub.

  In a run: the runner is Chip's stream, so its numbers and chat are her broadcast's.
  Super chats flood it (outline Beat 09). (proposed) They show as chat messages with the
  amount, fired by graze chains, a great shot of a key event, the burning-finale shot, and
  scripted "money moments" per run.
  In stealth: the cones, circles and meters are the AR visor's overlay, which is what
  allows them (docs/stealth_spec.md, section 3).
  The dossier: the in-game files, with tabs, numbered entries, a picture and a found counter
  per tab; pre- and post-reveal versions and glitched text. Opened from the hub and the
  pause menu; never spends a slot. Detail: docs/dossier_spec.md.

  Gallery and hints (proposed, TARGET EXPERIENCE): silhouettes for shots not yet taken,
  Chip's "chat would've lost it" hints, a rare-shot tally after a run.
  [OPEN] Which run numbers stay on screen mid-run (the build shows followers, money and
         shields as plain labels), and how much chat the player reads while dodging.
  [OPEN] Whether there is a gallery, where it lives and what it holds.
  [OPEN] How missed story content is hinted, given that nothing gated is load-bearing.


FIRST HOUR AND TEACHING
-----------------------

  Day 1, in order: title -> New Game -> name entry (the visor booting; default Phoroneus)
  -> briefing -> the Chaac run -> prologue, intro, first stream, first shot, aftermath. No
  hub (docs/chaac_run_spec.md section 11, docs/main_spec.md section 2).

  The Chaac run teaches lanes, reticle and mouse, as a gun. The first stream run (outline
  Beat 07) is a half-tutorial: Chip and the narrator teach the controls in banter, each
  line fired by an event (first dodge, three dodges, first beam), and bicker over the rig's
  name. The tutorial run is shorter than a full run. The first shot (game/story/first_shot/)
  is Day 1's filming moment; its followers and donations show on the phone.
  The first dial marker lands in the intro (MECHANICS RULES).
  [OPEN] Which moment teaches the snap step by step: the first shot or the tutorial run.
  [OPEN] Where the lane pick is first taught, if it becomes a mechanic.
  [OPEN] When the shop and debt clock are first shown. (The hub's offer list comes in
         cycle 1, the stealth job after the audition: THE DAY, THE OPENING CYCLES.)


SAVING, SETTINGS AND ACCESSIBILITY
----------------------------------

  One campaign save, written when a segment starts and when it finishes, so a payout never
  applies twice and a quit resumes the segment in play (docs/main_spec.md, section 3).
  Stealth maps have their own checkpoints. Checkpoint days as saves to return to: not built.

  Settings, from the title menu: master, music and sfx volume, fullscreen, text speed;
  saved apart from the campaign (docs/chaac_run_spec.md, section 11).
  Skip of read lines in the VN is a must-have (MONEY, MISSING A WALL).
  [OPEN] Back-log and rollback in the VN.
  [OPEN] Manual saves or slots beyond the one campaign save.
  [OPEN] Assist options beyond AUTO RUN and stealth's minimum clear, key rebinding,
         chatter subtitles, colour-safe reticle tiers, shake and flash toggles.


SCOPE AND PRIORITIES
--------------------

  Build ONE dial end to end first (OPEN QUESTIONS 5).

  The minimum game is the VN, the runner, and the systems that tie them together in the
  story: debt walls, Hype, interviews, fan mail and auto run.
  (mine) Stealth story maps sit at outline beats 16, 18, 27-28, 35, 38, 39, plus the
  audition. If stealth is cut, those beats need VN or runner stand-ins.

  (proposed) Cut order: the stealth job first, then the Tunnel, then the stealth story
  maps.


OPEN QUESTIONS
--------------

  1.  THE ENDING. Moved to its own section above -- three models, unsettled. It needs a
      decision before the last chapter is written, in a dedicated session.

  2.  "Only Drama <> Sympathy has different paths" does not match the bullets above:
      propaganda has two trees and Bloodlust has one. If the distinction is STORY
      BRANCHES versus ACCESS TREES, say so and it is consistent.

  3.  THE LOANSHARK CAN SOFTLOCK YOU. Money is tight by design, and a collector who
      wrecks your car until you pay can make the game unwinnable. It needs an escape
      valve: pay in labour, in footage, in a favour.

      Answered: the starting debt is a bank loan; the loanshark acts for a mysterious
      client who pays off the rest of it. At wall 1 he buys out the debt "as a favour to
      a rising up-and-comer" and asks nothing yet; the favour is repaid in service
      with the audition, the first stealth map, optional in days 6-10 and forced at
      wall 2 if refused. Wall 2 (day 10) is the scripted interest fakeout.
      After it, stealth jobs pay down or defer the debt. Misses after that follow MISSING A WALL. (THE DAY, THE OPENING
      CYCLES.)

  4.  THE SEX-APPEAL MODEL is now the game's physics and nothing in the fiction remarks
      on it. If the crudeness is the platform's model being satirised, it should read as
      the platform's. Craft question, not a comfort one: does any character object?

  5.  SIZE. Four dials times (choices + reads + access trees + trouble events) is a lot.
      Recommendation (mine): fill the dials one at a time as scenes need them, and build
      ONE dial end to end first -- that is what proves the read verb and the event
      pipeline work at all.

  6.  HYPE AS A MECHANIC. Answered: it is a mechanic, and the player sees it roughly,
      through the strobing analytics % and Chip's Hype app flame (THE METER, SEEING HYPE).
      [OPEN] How the variety-and-rest model works in numbers (how fast a repeated type
      stops paying, how much rest restores). Whether a third repeatable type, perhaps
      Tunnel, is needed to give variety some room. A big follower count can hurt without
      Hype: how, in play?


ENGINE REQUIREMENTS
-------------------

  Nothing above can be authored yet.

  -  The script can WRITE stats and deeds today (+ hype 5 and + spared_warden 1 both
     work) and cannot READ them. get_stat and has_flag exist in autoload/game_state.gd and are
     called from nowhere in the project. One conditional verb is the entire addition,
     placed so it attaches to the node it precedes, like @ glitch and @ auto.

  -  make_plain.ps1 drops ? blocks, so the reading copy will silently lose every choice.
     This is now a hard requirement rather than a nicety, because the design depends on
     choices being authored.


DEPENDENCIES
------------

  canon 11 ................ the campaign beats, and the stat list this document supersedes.
  canon 13 ................ Patriotism as the Ministry's belonging word, and the authority.
  canon 3 ................. water, certification, the counter-market, money slang.
  io_story_bible.md ....... the fork and both endings.
  outline.md .............. the beats in order; the first-stream tutorial.
  main_spec.md ............ Main, the calendar, slots, the save, the 40-day placement.
  chaac_run_spec.md ....... Day 1's run, the title menu, name entry, settings.
  stealth_spec.md ......... stealth, the job, the loanshark's first map, stealth slow motion.
  tunnel/design.md ........ Tunnel Escape, and its slow-motion rules.
  tunnel_port_plan.md ..... Tunnel as a segment.
  dossier_spec.md ......... the in-game files.
  demo_spec.md ............ the browser demos.
  punchlist.md ............ open mechanical items, and the engine gap.
