# MatchMake Tennis — VT3/VT4 deep-design review and redesigned Physics Lab 0.2
Date: 2026-10-23. Owner: MatchMake cloud prototype. Status: grounded design specification + code evaluation; quality not yet human-validated.

## Decision
Original Tennis Lab 0.1 was mathematically plausible but insufficiently engaging:
1. Misleading court presentation: large generic asphalt but a small visual tennis footprint and an elevated camera made players/racket tiny.
2. CPU incorrectly targeted *bounce location*, rather than a reachable *return contact location*, producing short rallies.
3. Serve automatically fired after ~0.18s of preparation; the player had no real serve timing decision.
4. Racket floated at the side of an articulated athlete instead of tracking the forearm.
5. Sluggish directional start/stop and weak balance feedback despite deterministic 120 Hz updates.
6. Tests were physics- and error-focused; none required AI to return basic serves.

## Primary source: Sega Virtua Tennis 3 (2006–2007)
- Arcade service manual, controls section: 8-way joystick moves and aims; top spin/slice, combined lob; direction may change between button press and racket contact; more preparation increases shot power; serve uses toss then timing gauge. https://www.manualslib.com/manual/2140267/Sega-Virtua-Tennis-3.html?page=12
- Console manual, Returning Shots/Hitting Hard Shots: anticipation, swing wind-up, long directional input increases angle, apex of bounce and good footing increase power; misses and weak shots happen when poorly positioned. https://www.manualslib.com/manual/150515/Playstation-Virtuatennis-3-061213.html?page=5
- Contemporary gameplay review: smooth, positionally meaningful exchanges, automatic context-sensitive forehand/backhand, subtle slide during sharp changes. https://www.gamespot.com/articles/virtua-tennis-3-hands-on/1100-6165952/
- Reviews also identified shortcomings: infrequent control imprecision and unusually forgiving AI lobs. This is not a call to clone every historical bug. https://www.gamespot.com/reviews/virtua-tennis-3-review/1900-6167755/

## Primary source: Sega Virtua Tennis 4 (2011)
- Official arcade manual, control section: topspin, slice, high lob, timed double-button serve, match momentum and a situational Super Shot. https://segaretro.org/images/b/b8/VirtuaTennis4_Ringedge_UK_Manual.pdf 
- Wii manual: moment-to-moment gameplay still values balance and arrival time. VT4 adds Match Momentum and Super Shots. https://manualzz.com/doc/9955756/sega-virtua-tennis-4-video-game-instruction-booklet
- Independent reviews disagreed on improvement: GamesRadar described VT4 as slower, less precise, and less responsive than VT3; GameSpot criticized "gliding" and delayed footwork despite animation improvements. https://www.gamesradar.com/virtua-tennis-4-review/ and https://www.gamespot.com/reviews/virtua-tennis-4-review/1900-6312955/
Conclusion: use VT3's snap/mobility/early-preparation reward as the initial design target; borrow selective VT4 features later. Avoid momentum/Super Shot until base stroke timing and placement is satisfying.

## Court size vs presentation
- Regulation court lines are 23.77 m long, 8.23 m singles width, 10.97 m doubles. Do **not** arbitrarily inflate official lines as if accurate.
- For runoff, International preferred full tennis play area 40.23 m × 20.11 m (ITF Facilities Guide 2020). https://itf.uberflip.com/i/1255985-facilities-guide/11
- This prototype deliberately uses *oversized arcade facility* 48 × 32 world units including spectator and environmental margins; physics movement extent ±15 X, ±22 Z. This is NOT a claimed official ITF facility prescription; it is a tunable game map.
- Presentation: broadcast low-three-quarter camera with modest follow to prevent tiny characters; scale a 1.38x visible ball (collision remains regulation 0.105 m radius), racket attached to arm, neon lines and landing helper. "Readable" is a game design requirement rather than literal realism.

## Physics/controls hypotheses
- Fixed-step 120 Hz independent of variable GPU frame rate.
- Arrow keys steer athlete outside stroke; once a shot is prepared, arrow input simultaneously contributes directional placement, but movement remains available at a moderated speed.
- A topspin, S slice, D flatter shot, Q lob; W sprint; E split-step. Press early to arm the stroke; actual contact window determines execution.
- Initial 2-tap serve: 1st press toss, 2nd press hit near gauge peak. Later: first and second serve faults, deuce/ad advantage or tie-break official rules.
- Early preparation rewards quality (fraction of wind-up), planted stance, sweet-spot reach and contact height; all bounded so a quick emergency shot remains possible.
- CPU anticipates a *reachable* trajectory contact after bounce, instead of chasing a serve bounce at z≈-4 when it is positioned behind baseline z≈-13.
- Forehand/slice/lob/serve procedural upper-body animation pose; racket attached to articulated wrist/grip.
- No claims that existing drag/Magnus coefficients were fit to measurements or that arcadey inverse launch solver is physically unique.
- Super Shots, fantasy power bars, pay-to-win mechanics intentionally excluded until successful skill-based tests.

## Real tennis/biomechanics background
- International/other scientifically relevant basics: ITF guide above.
- Split-step timing: Uzu et al. (2017), "Differences in Movement Speed Before and After a Split-Step Between Professional and Junior Tennis Players" https://pmc.ncbi.nlm.nih.gov/articles/PMC5304280/
- World-class serve return timing (2019), DOI 10.1080/02640414.2019.1609392.
- Spatiotemporal preparation while receiving serves (2021), PubMed https://pubmed.ncbi.nlm.nih.gov/34530683/
- Goodwill et al. (2004) spinning ball aerodynamics DOI 10.1016/j.jweia.2004.05.004.
Papers motivate modelling, do NOT directly provide videogame-specific friction, cooldown or "fun" constants.

## Code/CI gates
- tennis-feel.js: pure velocity-limited movement and physical interception forecast, shot quality model.
- tennis-sim.js: fixed physics; two-hit serve; CPU forecast + balanced shots.
- tennis-scene.js: larger original urban shell with official line geometry and reparented racket.
- tennis.js: dynamic camera, net feedback, serve instructions and tennis stroke poses.
- New tests enforce short stopping distance, meaningful gap between strong/weak shot quality, 2-tap serve and a 28-serve headless rally benchmark; browser smoke requires 32x48 facility and successful toss/second hit.
- Preserve football in / and tennis in /tennis/; no deployments to MatchMake main or Supabase.

## Remaining unsolved criteria
1. Human playtest: can player intentionally direct shots cross-court and down-the-line?
2. Controller latency and frame pacing on budget mobile browser.
3. Distinct footplant and root-motion animations; no genuine motion-capture animation yet.
4. Character pose and racket head should align with collision; currently model-level approximation.
5. IA needs richer positioning, neutral/rally/attack recovery and smarter difficulty matching.
6. Serve rules (box diagonals, let, faults and second serve) and point/sets require review.
7. Audio/haptics/spectators and online authoritative protocol absent.
8. More robust benchmark: 100+ seeded games, batting contact statistics, P95 serve-in %, skill gradient, rally distribution and error classification.
9. External user feedback, not just CI success, determines playability quality. No claim of VT3 parity until evaluated against blinded video/manual comparative playtests.

Next design pass: intercept feedback + foot locking + measured racket impact synchronization + drills for each shot type.
