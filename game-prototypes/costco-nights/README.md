# Costco Nights

A tiny SCP-3008-style horror prototype: you're locked in a big-box warehouse
store after close, and something is doing the night shift with you.

Single self-contained `index.html` — no build step, no assets to download
beyond the Three.js module from a CDN. Just open it in a browser.

## Run it

```bash
# any static file server works, e.g.:
npx http-server game-prototypes/costco-nights -p 8080
```

Then open `http://localhost:8080` and click **Start**.

## Design notes

- **Maze**: procedurally generated each load (recursive-backtracker + a few
  knocked-down walls for loops), rendered as an `InstancedMesh` of shelving
  units so it stays cheap even on integrated GPUs / 4-8GB RAM machines.
- **Lighting**: no shadow maps. Ambient light is nearly zero — your flashlight
  (a single `SpotLight`) is the only real light source, everything else is
  emissive/unlit for atmosphere at ~zero extra GPU cost.
- **Enemy**: a single stalker with patrol/alert/search/chase states, grid
  BFS pathfinding, and a line-of-sight check raycast against the maze walls.
  Your flashlight and footstep noise both make it easier for it to find you;
  crouch-walking is quiet but slow.
- **Furniture**: crates/pallets/carts can be picked up (`E`) and dragged
  around. Dropped furniture fully blocks the enemy's grid pathfinding (a
  real barricade) while still being just a soft obstacle for your own
  finer movement, so you can barricade a corridor behind you and still
  squeeze past it yourself later.
- All audio (hum, footsteps, heartbeat, jumpscare stinger) is synthesized
  with the Web Audio API — no audio files either.

## Controls

`WASD` move · `Shift` sprint (loud) · `Ctrl`/`C` crouch (quiet) ·
mouse look · `F` flashlight · `E` grab/drop furniture
