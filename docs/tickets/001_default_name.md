# Ticket 001 — default player name is Phoroneus

**For:** GPT / DeepSeek   **Written by:** Claude, 2026-11-16   **Status:** open

## Goal
When the player leaves the name blank, the game calls him Phoroneus instead of Commander.

## Read first
- `AGENTS.md`, `CLAUDE.md`
- `game/autoload/game_state.gd`, the `set_player_name` function and the code just above it

## You may change
- `game/autoload/game_state.gd`
- any test in `game/tests/` that expects the name "Commander"

## Do not touch
- Story docs and scene text, and anything not listed above.

## Decisions you need
The narrator's default name is Phoroneus (canon §4, settled 2026-11-16). The player still types
his own name at New Game; Phoroneus is only the fallback for an empty entry.

## Steps
1. In `game_state.gd`, replace the fallback name "Commander" with "Phoroneus" wherever it is
   used as the default.
2. Search `game/` for other places that hard-code "Commander" as the player's name and report
   them. Change them only if they are the same fallback.
3. Update any test that checks for "Commander".

## Done when
- [ ] A new game with an empty name shows Phoroneus in dialogue
- [ ] `powershell -File tools/run_tests.ps1` says 0 failed
- [ ] committed

## Report back
What changed, in plain words. How to check it. Any question you stopped on.
