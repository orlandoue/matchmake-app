# MATCHMAKE TENNIS — Gameplay Research & Calibration Ledger
**Created:** 2026-10-23  
**Status:** Research + first cloud physics lab. This is *not* a demonstrated Virtua Tennis 3-equivalent game.

## Product hypothesis
Build an original, premium arcade tennis game with the accessibility and movement/good-shot reward principles of SEGA's Virtua Tennis 3, without copying code, characters, models, branding, assets, animations, audio or its exact implementation.

## Direct historical evidence (Virtua Tennis 3)
- SEGA's VT3 arcade service manual, section 3-6: eight-way joystick moves the player and aims. Top-spin and slice buttons; combo for lob. Incoming ball must be anticipated. Shot direction can be changed after pressing the stroke button and before contact. Earlier stroke-button preparation increases power. Serving uses a gauge. https://www.manualslib.com/manual/2140267/Sega-Virtua-Tennis-3.html?page=12
- PS3/PSP original manual: good anticipation and planted position allow more force and stronger control. Direction gets more extreme with longer held directional input. https://www.gamesdatabase.org/Media/SYSTEM/Sony_PSP/manual/Formated/Virtua_Tennis_3_-_Sega.pdf
- Contemporary original reviews: context-sensitive animations; early positioning, stable footing and holding the swing button enable stronger angled shots. https://www.gamespot.com/articles/virtua-tennis-3-hands-on/1100-6165952/

**Interpretation, not an extracted commercial formula:** A quality metric should combine (a) preparation before contact, (b) body balance, (c) proximity to optimal racket strike point, and (d) right shot selection; manual aiming must meaningfully affect where the ball lands. Do not implement fully automatic magical returns.

## Scientific foundation
1. S. R. Goodwill, S. B. Chin, S. J. Haake (2004), Aerodynamics of spinning and non-spinning tennis balls. DOI:10.1016/j.jweia.2004.05.004. Wind-tunnel drag and Magnus effects. Initial implementation uses tuneable arcade coefficients, not coefficients claimed calibrated to their measurements.
2. Cross (2001), Effects of friction between ball and strings in tennis, DOI:10.1046/j.1460-2687.2000.00052.x. String/ball friction, tangential impulses and spin; the current prototype does NOT yet simulate deformable strings.
3. Allen, Haake & Goodwill (2010), Effect of friction on tennis ball impacts, DOI:10.1243/17543371JSET66. Bounce friction and overspin. Simplified hardcourt coefficient-of-restitution and horizontal friction used; physical validation pending.
4. Differences in Movement Speed Before and After a Split-Step Between Professional and Junior Tennis Players, J Human Kinetics (2017), https://pmc.ncbi.nlm.nih.gov/articles/PMC5304280/ (8,545 recorded split steps; 82.9% of investigated movement situations featured a split step). Supports controlled stopping and direction-change mechanics, not direct player max-speed values.
5. Effects of neuromuscular function and split step on reaction speed in simulated tennis response (2014), DOI:10.1080/17461391.2013.785598. Supports designing a timed split-step input and recoverable initiation bonuses.
6. Tennis ball trajectory decomposition based on spatiotemporal tracking data, Sports Engineering (2026), https://link.springer.com/article/10.1007/s12283-026-00547-6. Emphasizes deriving speed/spin parameters from tracked trajectory and validating model on independent points.
7. Vid2Player: Controllable Video Sprites That Behave and Appear Like Professional Tennis Players (2021), DOI:10.1145/3448978. Inspiration for animations tied to court state, not a license to download footage for use.
8. ITF tennis court dimensions (23.77m by 8.23m singles, 10.97m doubles, .914m net center): https://www.itftennis.com/en/about-us/organisation/tennis-glossary/

## Repositories independently surveyed
- https://github.com/ryogrid/tetetennis: web 3D with separated logic/render; ball drag, spin, rebound, shot solver, AI, unit tests. Core physically informed example. License verification required before importing ANY code; current MatchMake Tennis imports none.
- https://github.com/leslieyip02/tennis: Three.js two-player shot-charge demonstration; author explicitly calls the physics janky; useful for avoiding poor control-feel, not an implementation baseline.
- https://github.com/ammaarreshi/argon-games : Argon Tennis gameplay and 3D architecture to evaluate; avoid assuming community demos are proven competitive games.
- https://github.com/ryogrid/tetetennis/tree/master/logic/physics : solver.mbt, bounce.mbt, constants.mbt, physics_test.mbt; architectural inspiration only.

## Current Tennis Physics Lab 0.1 implementation
Published path planned: /tennis/ under the existing static site, preserving football under /.
New independent files:
- tennis/tennis-sim.js : pure 120 Hz simulation, acceleration/braking, manual steering and aiming while preparing, dynamic shot preparation/quality, four stroke classes, seeded AI, physics (gravity, drag, Magnus-like spin term), numerical inverse target solver, net crossing, hard-court bounce, points to 7 by two.
- tennis/tennis-scene.js : independent court, original night environment, two articulated tennis avatars and simple racket meshes; references existing licensed/original MatchMake rig utilities.
- tennis/tennis.js : DOM/controller/render bridging, HUD, landing indicator, event animations; fixed-step simulation.
- tennis/tennis-sim.test.mjs and tennis/browser-test.mjs: determinism, court bounds, shot types, serve/score, CPU, JavaScript runtime in Chromium.

Current **limitations** (must not be hidden):
- Only one human and one CPU. No 2v2, ranking, matchmaking, online, seasons or payments.
- Short tiebreak-style scoring only; diagonal service boxes and full advantage-set rules are deferred.
- Court dimensions are grounded; lift/drag, stamina, AI timings and strike windows are hand-chosen first parameters, not validated to real ball tracking or VT3 responsiveness.
- Stroke animations adapt an existing original football procedural rig; motion matching, foot planting, timed actual racket contact and racket collisions remain underdeveloped.
- Serving is prepared-and-auto-launched; toss timing, second serve and double faults deferred.
- CPU reaction, movement speed, stroke selection and return coverage need substantial tuning against hard shot distributions.
- Audio, vibration, hit sweet-spot and accessibility are future work.
- This is a prototype designed for systematic iteration, not a claim of AAA quality.

## Iteration measurement (required before declaring quality)
For each build, record version, independent test corpus and baselines:
- median P90/P99 player input latency and response curve to arrow press/release, frames dropped
- acceleration/deceleration, lateral cross-court recovery, split-step timing advantage (bounded)
- ball predicted vs observed bounce position, net/out/serve-fault correctness
- three reference shot types: flat, topspin, slice, lob: mean landing position error and bounce height distributions
- preparation vs quality: power monotonic across 0/0.2/0.4/0.65s wind-up, contact window tolerances
- probability of return by human in scripted ball delivery training drills
- AI skill distribution and match balance after 100-1,000 seeded games; avoid winner by spawn side
- browser UI on desktop + mobile and visual actual racket contact.

## Milestones: measured, not promised
T0 physics lab and first 1v1 rally; T1 proper footwork / split-step / recovery; T2 contact-point animation sync + topspin/slice balance; T3 serve/lines/advantage gameplay rules; T4 training and playtest telemetry (privacy-aware); T5 multiplayer authority/prediction/reconciliation; T6 ranked skill-centric modes and seasons. Keep MatchMake football independent.

## Technology
Static frontend Three.js from a pinned CDN. Simulation pure JavaScript, deterministic PRNG, fixed 120 Hz. Automated Node tests and cloud Chromium in GitHub Actions. Hosted alongside football in Render static site. No installations on user's device.
