# MatchMake Street Arena — prototype 0.1

A deliberately isolated, original browser-based street-football experiment.

## Scope
- Rendered in Three.js (pinned CDN dependency); all field geometry, athletes, skyline and procedural scenery are generated in code.
- One local 1v1 match against a simple deterministic-rules bot (with a small random shot variation).
- Ball movement, bounces, shooting, tackling, score tracking and 150-second match clock.
- Keyboard and touch controls, responsive browser presentation.
- No authentication, personal data, payment processing, database, online matchmaking, or telemetry.
- No third-party game assets, commercial club logos, FIFA branding or copyrighted character models.

## Run
Open from a static web server (ES modules cannot reliably run from file://); entrypoint: street-arena/index.html.
The player downloads the game in the browser; no application installation is necessary.
Three.js is fetched as a version-pinned module from jsDelivr.

## Deploy
Render **Static Site** source: orlandoue/matchmake-app, branch: prototype/street-arena-cloud-20261022.
Build command: echo "Street Arena static prototype".
Publish path: street-arena.
Do not deploy or merge this branch into the MatchMake production application.

## Controls
WASD / arrows to move; Space to shoot; Shift to sprint; E to steal. On mobile, use touch controls.

## Known limitations
Gameplay physics are simplified; this is not a full soccer simulation.
Visual appearance depends on the browser GPU.
AI, collision, touch feel, and camera need hands-on playtesting.
No multiplayer, accounts, ranking, persistence, production anti-cheat, audio, or accessibility audit.
Never market this as a fully competitive release.

## Exit criteria for 0.2
Human playtest on mobile + desktop; fix interaction and rendering issues; design new mechanics; then assess dedicated multiplayer authoritative servers separately.
