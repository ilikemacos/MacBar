# Gold Runner

A [Lode Runner](https://en.wikipedia.org/wiki/Lode_Runner)-inspired 2D dig-and-climb
game for [MakeCode Arcade](https://arcade.makecode.com), built to feel at home on a
retro handheld: run and climb ladders through a brick level, dig out the floor to
trap chasing guards, grab every piece of gold, then race to the top row to win.

## How to play it

1. Go to https://arcade.makecode.com and click **New Project**.
2. Switch to the **JavaScript** editor (top right of the code area).
3. Delete the placeholder code and paste in the full contents of `main.ts`.
4. The simulator on the left should start the game immediately.

(You can also drop `main.ts` in via **Import > Import File** if your version of
the editor supports importing a `.ts` file directly.)

## Controls

| Input        | Action                                  |
|--------------|------------------------------------------|
| Left / Right | Run                                       |
| Up / Down    | Climb ladders (only works while on one)   |
| A            | Dig the brick tile you're facing          |

## How it works

- The whole level is a plain grid (`LEVEL`, an array of strings in `main.ts`),
  not a MakeCode Tilemap — that's what lets this be a single copy-pasteable
  `.ts` file with no external tile/asset editor state.
- `#` is an indestructible wall, `B` is a diggable brick floor, `H` is a
  ladder, `G` is gold, `P` is the player's start, `E` is a guard's start.
- Movement is grid-stepped (one 8px tile per game tick) rather than
  pixel-smooth, matching the original game's feel.
- Digging turns a `B` tile into a temporary hole for a few seconds. Guards
  (and you!) fall through open holes automatically; anything still standing
  in the hole when it regenerates gets caught — guards respawn at their start
  tile and you lose a life.
- Win by collecting all the gold and reaching the very top row of the level.

## Ideas to extend it

- Add horizontal **ropes** you can hang from and shimmy along (classic Lode
  Runner feature, left out here to keep the first version simple).
- Hide the top exit ladder until all gold is collected, instead of always
  showing it.
- Add more levels and a level-select/transition screen.
- Give guards a chance to climb out of a hole early instead of always being
  caught when it closes.
- Add sound effects (`music.baDing.play()` on gold pickup, etc.) and a
  digging animation.
- For an authentic monochrome Game Boy look, try setting a custom 4-shade
  green palette in the project's `pxt.json`.
