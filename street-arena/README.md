# MatchMake Street Arena — Alpha 0.5 (expanded urban 2v2)

Alpha 0.5 builds on articulated Alpha 0.4. Static browser 3D game on an isolated GitHub branch and manual Render deployment.

## New urban court
- Court artwork 24 x 38 units (formerly 20 x 32): **20% wider, 18.75% longer**, 42.5% more surface area.
- Shared `court-config.js` is the single source of truth for game physics, goal mouth, field lines, fence, props and match camera. Playable physics box: 22.7 x 36.4.
- Original canvas-textured worn asphalt, corner markers, center circle, penalty areas, penalty spots and neon edge lights.
- New aligned goal frames with back nets; tall wire fencing and side barriers.
- Original MATCHMAKE / STREET ARENA signs, benches, gym bags, cones, spare balls, floodlights and a procedural city skyline.
- No third-party textures or models or external visual asset downloads.
- Perspective is opened up for the larger pitch; no new local installation needed.
- Court scenery is in `court-scene.js` and stays separate from the deterministic gameplay engine and character rig.

## Validation
- Fixed-step 60 Hz game physics remains in `simulation-v03.js`.
- `court-layout.test.mjs` checks center, scoring plane, rebounds, limits and shared dimensions.
- Chromium test asserts expected geometry and procedural props, verifies animated player limbs and checks page errors.
- Performance still needs human playtesting on lower-end mobile devices; a screenshot and green CI are necessary but not sufficient.


## Previous gameplay / animation work

Original browser-based arcade street football. Isolated from MatchMake app development and payment production code.

## What changed from Alpha 0.2

- 2v2 local: one human-controlled cyan athlete, one AI partner; two AI opponents.
- The cyan partner offers support and automatically becomes controlled when receiving a pass. While defending, **Q** switches the controlled cyan athlete.
- Shot direction and power: hold **D** to charge, use **LEFT / RIGHT ARROWS** while holding D to adjust the visible aim marker at the opposing goal, release **D** to shoot.
- Curve/controlled shot: hold **Q** and **D** together; a distinct spin term curves the ball in flight. Spin and power are separate.
- Through passes: **A** grounded, **E** elevated with gravity and bounces; **S** directed short pass with limited receiver assist.
- Defence: **A** standing steal; **E** sliding challenge. Failed slides commit the defender to recovery.
- **W** sprint, **Q** skill move/feint when in control; arrows move outside the shot-aim stance.
- 60 Hz deterministic engine, independent from Three.js rendering; seeded AI and testable match state.
- All geometry original; no FIFA/PES code or proprietary assets.

## Keyboard controls

| Button | Attack | Defence |
| --- | --- | --- |
| Arrows | Move; left/right aim while D held | Move |
| A | Ground through pass | Standing steal |
| S | Directed pass | Hold position / intercept by movement |
| D | Charged shot | — |
| W | Sprint | Sprint |
| E | Lofted through pass | Slide |
| Q | Feint/dribble (hold for finer control) | Switch cyan player |
| Q+D | Finesse curled shot | — |

The current version uses one human and three local bots, **not** internet multiplayer or four human players.
Physical simulation is stylized 2.5D; real-world precision and full animation systems are not yet implemented.

## Run and test

The static site serves `street-arena/index.html`.
Run `npm test --prefix street-arena` under Node 22 for both Alpha 0.2 legacy and Alpha 0.3 physics tests.
The branch `prototype/street-arena-cloud-20261022` is tested with GitHub Actions, and Render static site deployment is manual after CI success.

## Technical research references

- EA SPORTS FC shot assistance: https://www.privacyappendix.ea.com/able/resources/ea-sports-fc/fc-26
- eFootball official command mapping: https://www.konami.com/efootball/es/page/mobile_controller
- Gameplay research ledger: `street-arena/docs/RESEARCH_GAMEPLAY_V02_2V2_2026-10-22.md`

## Known limitations

This is still a gameplay prototype. Passing, opponent tactics, curve calibration, contact animation, foul decisions, accessibility, camera and touch action layout require live device playtesting. The match is only local. The primary MatchMake application, databases, and payment systems are unchanged.

## Alpha 0.4: Procedural character animation

- `character-rig.js` creates **original articulated 3D low-poly athletes** with separate hip, knee, ankle, shoulder, elbow, torso and head groups, generated on page load with Three.js. Four player models use the same rig.
- `character-motion.js` is a pure, unit-tested animation pose engine: gait phase is proportional to travel speed; walk and sprint differ in stride length/frequency; legs and arms swing in opposition; braking fades out footsteps; idle breathes subtly.
- Kick/pass, finesse, ball reception, dribbling feint, standing tackle and slide have distinct transient motion poses. Shots use a leg swing and torso counterbalance, while slides lower the torso and extend a leg.
- `gameplay-bridge-v03.js` connects simulation events and velocity to animation poses **without influencing the deterministic 60 Hz match physics**. `window.__streetArenaMotionDebug()` is a read-only visual diagnostic for browser CI.
- CI now includes `character-motion.test.mjs`, module syntax checks and a Playwright smoke test that **measures shoulder and hip joint rotation in Chromium**, not merely a successful page load. Headless screenshots are stored in GitHub Actions artifacts.
- **Still stylized procedural motion, not photorealistic motion capture**; polishing footsteps/foot locking, movement transitions, kick-to-ball frame timing and real skeletal GLB assets can be a later upgrade. No licensed third-party animation clips or downloaded human models were introduced.

Technical reference: https://threejs.org/docs/pages/Object3D.html and https://threejs.org/manual/pages/animation-system.html . Future rigged assets can use SkinnedMesh + AnimationMixer, retaining the existing deterministic gameplay simulation.
