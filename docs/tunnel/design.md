# War Idols — Tunnel Escape: design

Copied from the Google Doc "War Idol Tunnel Escape" on 2026-10-24
(https://docs.google.com/document/d/12EQ9c2c1CfabkXirdTMJqGdKGY4KgA2DNwFxwMNJjBE/edit).
**This file is now the working copy**: edit here, not in the Doc.

The design was written for another universe and is being re-themed to War Idols. Bold text marks the doc's own open notes.

## 0. War Idols re-theme (settled 2026-10-26)

- **Story slots** (two uses, author 2026-11-17): Aysel's later ambush, and earlier, right after
  Ottenok's ambush where the crew saves Kathay (outline Beat 14). The first use is described here: the
  damaged vehicle is stashed in an abandoned deep-bore tunnel and they go on foot. The jam build
  stands alone; judges need no lore.
- **Player:** the MC, the one-legged veteran. The missing leg is why there's no jumping.
  **Look (settled):** black double-breasted greatcoat with gold buttons and trim, peaked cap, a
  black faceplate/visor with gold ear units, black gloves, a gold eagle-head cane, and a grey
  mechanical prosthetic leg. Outfits: canonical cape (black outside, cream lining, tattered hem,
  gold winged-compass crest on the back), service coat, short jacket, off duty. For the jam, use
  the service coat or short jacket; the cape is costly to animate. The cane goes into the walk
  cycle, and the hide pose can be him flattening against the wall with the cane tucked in.
- **Vines:** tubeworm-like growths, part of the bio-terraforming project. *(New fact; if it sticks,
  move it into canon.)*
- **Guards, including the spotlight and catwalk guard:** AR monsters. In canon these are humans
  in exosuits that the visor renders as monsters; the AR transformation stays on for the whole jam
  piece.
- **Stretch goal:** design the Ministry (searchlights, uniforms, signage) if time allows.
- **Chamber 0 corpse (settled):** a dead "bug" with **no AR deformation**: a plain human in an
  industrial exosuit. This is the one hint at the twist. Suggested logic: the visor only skins
  live targets, so a corpse shows as it really is. Optionally the overlay flickers on and off once.
- **Light source (leaning):** the MC pulls a work lamp off the corpse's suit. It's the same model the
  guards carry, so his light and theirs read alike. The player is carrying the "monster's" light.
- **Environment reference:** the GPT mockups (9 panels): brutalist industrial facility, amber/orange
  structure, grey concrete, yellow strip lights, white tubeworm clusters with red plumes. Rough map:
  panel 2 (catwalk over glowing pit) → Chamber 4; panel 4 (pillars and catwalk) → Chamber 3;
  panel 9 (warm room, furnace, bed) → Chamber 5, with the furnace replacing the campfire.
  The mockups are in 3/4 perspective; the game is a side-scroller, so each room needs a flat side view.
- **Still open:** how much more of the AR twist the jam piece shows beyond the corpse.


---

## 1. Game design — chamber by chamber

### Chamber 0 — the fall (16–28 s, 4–7 beats)
You fall, tumbling into the chambers. In the last dusty beam of light you find a torch
(natural / electric / **magic / fusion?**) in the arms of a skeleton (like Dark Souls). You rend it
from his hands and activate it, lighting up the surroundings. The camera pans out.

### Chamber 1 — the tutorial (~45 s)
- **Layout:** a single straight hallway dipping into a shallow pit
  (**shallow toxic-coloured pit, squishy SFX, acid sizzle, no damage**).
- **How it plays:** the player walks forward and hits a wall of writhing, squelching 3D-rendered
  vines (**inspired by weird tubeworms**). They press the button to turn on the torch. The vines
  shrink away into the ceiling. They walk through.
- **Coding load:** extremely low. Player movement, the torch on/off toggle, and a trigger zone that
  plays a hide animation on the vines when light enters it.

### Chamber 2 — the direct threat (~60 s)
- **Layout:** a flat corridor with a locked exit door, a floor switch in the middle, and a single
  robotic/human guard pacing back and forth.
- **How it plays:** the player stands in the starting shadow. When the guard turns his back, the
  player runs to the switch, turns the torch *on* to power it, turns it *off* to hide as the guard
  (**big and fucked up, pre-industrial-looking suit**) looks back, then dashes through the door.
- **Coding load:** medium. A patrol loop (move to A, wait 2 s, flip sprite, move to B) and a
  vision-cone script.

### Chamber 3 — the scale shift (~90 s)
- **Layout:** a wide, cinematic screen with 3–5 massive pillars spaced across a bridge.
- **How it plays:** a massive background spotlight slowly sweeps left to right. The player runs
  pillar to pillar. Pressing "up" against a pillar triggers the hide state: the character hugs the
  wall, the torch is forced off, and the spotlight passes harmlessly over.
- **Coding load:** low. The alcoves are zones. Overlapping a pillar and pressing hide sets
  `is_hidden = true`; if the spotlight passes while `is_hidden` is true, nothing happens.

### Chamber 4 — the climax (~120 s)
- **Layout:** the floor is lined with deadly vines. A guard patrols a raised catwalk above,
  **sweeping his light on the floor below**. A heavy crate sits near the start.
- **How it plays:** the player pushes the crate across the floor. They must stay inside the
  guard's moving light cone so the floor vines don't kill them, but must **position the crate so
  its shadow blocks a wall-mounted sensor** at the end of the room to open the exit hatch.
- **Coding load:** medium. Box pushing via Godot's `CharacterBody2D`. Logic check:
  *player in shadow → kill player; sensor in shadow → open door.*

### Chamber 5 — the resolution (~30 s)
- **Layout:** a warm, empty room with a campfire.
- **How it plays:** the player walks forward. Controls drop away. The character sits.
- **Coding load:** none. A transition scene.

---

## 2. Scene tree

### Player.tscn
Standalone scene, dropped into every chamber.
- **CharacterBody2D** `Player` — script `Player.gd`
  - **Sprite2D** `CharacterSprite` — pre-rendered 2D sheets
  - **CollisionShape2D** `BodyCollider` — capsule or rectangle
  - **PointLight2D** `TorchLight` — soft circular gradient texture
  - **AnimationPlayer** `SpriteAnimator` — idle, walk, hide, tumble
  - **AudioStreamPlayer2D** `FootstepSFX`
  - **AudioStreamPlayer2D** `PanicGaspSFX`

### EnemyGuard.tscn
Standalone scene, copied into levels as needed.
- **Node2D** `EnemyPatrolGroup`
  - **Marker2D** `PointA` — patrol start
  - **Marker2D** `PointB` — patrol turnaround
  - **CharacterBody2D** `EnemyGuard` — script `EnemyGuard.gd`
    - **Sprite2D** `GuardSprite` — the pre-industrial hulking suit
    - **CollisionShape2D** `BodyCollider`
    - **Area2D** `VisionCone`
      - **CollisionPolygon2D** `ConeShape` — triangle/cone pointing forward
    - **RayCast2D** `LineOfSightRay` — target pointing forward
    - **PointLight2D** `TorchBeam` — sharp triangular flashlight texture

### Chamber_Template.tscn
Every puzzle chamber (1–5) uses this layout.
- **Node2D** `ChamberMaster`
  - **DirectionalLight2D** `GlobalDarkness` — dark blue/black, energy ~0.15
  - **TileMapLayer** or **Node2D** `EnvironmentWalls` — the 3D-rendered background wall layers,
    with static-body colliders so the player doesn't fall through
  - **Node2D** `PuzzlesAndHazards` — switches, crates, vines
  - **Node2D** `Enemies` — `EnemyGuard.tscn` instances
  - **Area2D** `CheckpointZone`
    - **CollisionShape2D** `TriggerCollider`
  - instance of `Player.tscn`
  - **Camera2D** `MainCamera` — position smoothing on, follows like Limbo
  - **CanvasLayer** `UserInterface`
    - **Control** `HUD`
      - **TextureRect** `Vignette` — dark blurred border, claustrophobic
      - **ColorRect** `FadeScreen` — black overlay for respawn fades

---

## 3. Coding prompt

Godot 4, GDScript, 2D side-scrolling stealth-puzzle for a game jam. Must be optimised for web
export (HTML5, Compatibility renderer). Clean, modular code, no placeholders, strict typing
(`: int`, `: float`, `: Vector2`), comments explaining the logic.

### 3.1 GameManager.gd (autoload)
- Tracks the active checkpoint (`Vector2`), player death and global flags.
- `respawn_player()` reloads the scene or resets the player to the checkpoint, with a camera fade.

### 3.2 Player.gd (CharacterBody2D)
- **Movement:** responsive left/right, gravity, smooth acceleration/deceleration. No jumping.
- **Torch:** `is_torch_on: bool = false`. `action_torch` (Space or E) toggles it and the
  PointLight2D's `.visible`. When on, a subtle organic flicker in `_process()` (noise or random
  range) modulates `energy` and `texture_scale`.
- **Hiding:** `is_hidden: bool = false`. While hidden, the torch is forced off and the player
  can't move.
- **Animations:** `SpriteAnimator` plays "idle", "walk", "hide", "tumble" (intro).

### 3.3 EnemyGuard.gd
- **Patrol:** back and forth between two Marker2D nodes at constant speed; flip sprite and
  vision cone on turnaround.
- **Vision cone:** child Area2D with a CollisionPolygon2D cone.
- **Line of sight:** in `_physics_process()`, when the player is in the cone: ignore if
  `player.is_hidden`; otherwise raycast from the guard to the player, and if it hits the player
  unblocked, call `GameManager.respawn_player()`.

### 3.4 Trigger scripts
- **ReactiveVines.gd (Area2D):** if the torch light overlaps and `player.is_torch_on`, play
  "retract"; if the torch goes off while the player is inside, play "grow". In Chamber 4, touching
  expanded vines kills the player.
  **Built as `tubeworm_cluster.gd`, rule settled 2026-10-26:** grown worms are a safe solid wall;
  being *inside* a cluster when it regrows kills (`kill_if_caught`). Touch-to-kill (`deadly`) is kept
  but off, in case Chamber 4 needs it.
- **LightSensor.gd (Area2D):** emits `sensor_activated` when a light (or the torch) hits it;
  toggles when a crate blocks the light.

Deliverables asked for: `GameManager.gd`, `Player.gd` (with torch toggle and flicker),
`EnemyGuard.gd` (with raycast line of sight).
