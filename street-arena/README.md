# MatchMake Street Arena — Alpha 0.2

Isolated, original, browser-based street-football playground. The main MatchMake application and its payment stack are untouched.

## Current playable features
- Night-time 3D court and procedural stylized athletes using the original Three.js rendering.
- Deterministic fixed-step 60Hz gameplay core in `simulation.js`, independent of DOM and WebGL.
- Accelerated movement, sprint, friction, ball possession states, controlled touches and Q-assisted first touch.
- Hold **S** and release for a variable-power shot; charge bar shown in the HUD.
- Experimental **A** short pass, **W** driven forward pass, **D** short feint when attacking / recovery slide when defending.
- 1v1 against a basic bot, match clock, goals, wall rebounds and touch-screen controls.

## Keyboard mapping (Alpha 0.2)
- **Arrow keys**: move exclusively.
- **A**: short pass when in control, standing tackle without possession.
- **S**: press and hold to charge, release to shoot.
- **D**: quick side feint when in control; defensive slide otherwise.
- **W**: driven long pass. Lofted/through-ball trajectory not yet supported.
- **Q**: softer first touch and slower controlled movement.
- **E**: sprint, increases speed but limits fine control.
- **Space and Shift are not gameplay controls.**
- On mobile: the 4 arrow buttons and the six A/S/D/W/Q/E action buttons.

## Local/CI testing
- `node --test street-arena/simulation.test.mjs` on Node 22.
- GitHub Actions workflow `.github/workflows/street-arena-tests.yml` runs test suite and static parse checks on commits in the isolated prototype branch.

## Hosting
Render Static Site: `matchmake-street-arena-prototype`.
Branch: `prototype/street-arena-cloud-20261022`. Publish directory: `street-arena`.
Render auto deploy disabled; use manual deploy after verified CI.
No installation required for players.

## Next development milestones
1. Tune reception vs. pressure, skill moves, running animation, responsive camera, directional aim.
2. Passing to selected teammates, interception prediction, higher/lower pass arcs, goal/physical contact audit.
3. 2v2 vs AI with team roles, optional manual avatar switch.
4. 2v2 online using a server-authoritative backend and tested network latency.

## Non-goals and cautions
Not an online multiplayer game. No persistent profiles, purchases, analytics, or ranking. All models are generated from original geometry without importing commercial football game assets. Some arcade mechanics are prototypes and need real device playtesting. The first touch is conditional rather than magic ball teleportation; collision and animation fidelity remain limited.
