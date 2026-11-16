# War Idols opening slice

## Project layout

- `game/` is the destination Godot project and the proposed campaign entry point. It owns story progression, durable saves, and minigame handoffs.
- The current VN source lives in `sandbox/vn/`. `sandbox/` is the driving and filming prototype. Its quarantined mechanics sandbox should remain available for playtesting.
- `tunnel/` is a separate minigame. Integrate it when its campaign beat needs it.

## Opening direction

Start in the simplified first mission as a playable shooter. Give the player a chance to hit a target and dodge a readable threat, then use a clear scripted setback to transition into the existing in-medias-res VN prose. Playtest the cut before adding an introduction. If players need context, try a single transition line. Later, Chip introduces filming through one requested shot. Increase stage pressure gradually and introduce only a few mechanics at a time.

## Build order

1. **Plan the minimal port · Sol Light.** Read-only. Trace the scenes, resources, input actions, and autoloads used by `sandbox/vn/` and the assets proposed for the cold open. Identify which files need to land under `game/`, which references need updating, and how to verify the port. Flag any structural decision that requires a larger migration before editing.
2. **Port the VN and connect the opener · Sol Medium.** First verify the VN independently in `game/`. Preserve the existing prose pacing, page breaks, effects, audio, speaker aliases, player-name entry and substitution, and aftermath branches. Then make a fresh launch enter the simplified shooter and follow the planned loss into the VN. Verify the transition from a normal launch in Godot.
3. **Connect filming, payout, and debt · Sol Medium.** Capture and miss should both reach the aftermath with different Chip callbacks and phone payouts. Save campaign progress, followers, cash, and rig debt. Verify a repayment and confirm that loading or revisiting the aftermath never applies a payout or payment twice. Use Astra Light for a focused review if the save and transition design needs a second opinion.
4. **Tune one follow-on stage · Sol Light.** Human-playtest the opening and first stream without coaching. Increase pressure on a learned skill in the next stage, then assess whether to introduce another control.

## Decisions to carry forward

- The lane-choice vehicle name and later flashback callback are the stated intent. The outline currently places vehicle naming after the escape. Resolve the authored placement before implementing it and keep the vehicle name separate from the player name.
- Hidden Hype, conduct axes, trouble events, and ending selection sit outside this opening milestone.
- Use Sol Light to split work with dependencies. Use Luna for bounded checklists or build prompts after the dependencies are settled. Give each build only its ticket and relevant files.
