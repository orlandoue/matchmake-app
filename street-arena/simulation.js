// MatchMake Street Arena — deterministic gameplay kernel, Alpha 0.2.
// This module has no DOM, Three.js, networking, or clock dependencies.
export const FIXED_DT = 1 / 60;
export const WORLD = Object.freeze({ halfWidth: 9.5, halfLength: 15.5, goalHalfWidth: 2.95 });

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const length = (x, z) => Math.hypot(x, z);
const decay = (rate, dt) => Math.exp(-rate * dt);
const normal = (x, z, defaultX = 0, defaultZ = -1) => {
  const l = length(x, z);
  return l > 0.00001 ? [x / l, z / l] : [defaultX, defaultZ];
};
function rand(state) {
  state.seed = (Math.imul(state.seed, 1664525) + 1013904223) >>> 0;
  return state.seed / 4294967296;
}
function actor(id, z, faceZ) {
  return { id, x: 0, z, vx: 0, vz: 0, faceX: 0, faceZ, slideTicks: 0,
    slideCooldown: 0, feintTicks: 0, feintCooldown: 0, tackleCooldown: 0 };
}
export function createGameState(seed = 221) {
  return {
    seed: seed >>> 0, tick: 0, timeLeft: 150, phase: "playing", goalPauseTicks: 0,
    score: { player: 0, opponent: 0 }, events: [],
    player: actor("player", 6, -1),
    opponent: actor("opponent", -6, 1),
    ball: { x: 0, z: 0, vx: 0, vz: 0, owner: null, contact: "FREE", releaseTicks: 0, firstTouchTicks: 0 },
    shoot: { held: false, charge: 0 },
    previousInput: { a: false, s: false, d: false, w: false }
  };
}
function resetKickoff(s) {
  Object.assign(s.player, actor("player", 6, -1));
  Object.assign(s.opponent, actor("opponent", -6, 1));
  Object.assign(s.ball, { x: 0, z: 0, vx: 0, vz: 0, owner: null,
    contact: "FREE", releaseTicks: 0, firstTouchTicks: 0 });
  s.shoot.held = false;
  s.shoot.charge = 0;
}
function moveActor(p, dirX, dirZ, topSpeed, acceleration, dt) {
  if (p.slideTicks > 0) { // committed lunge, little steering; defending must be readable
    p.slideTicks--;
    p.vx *= decay(2.2, dt); p.vz *= decay(2.2, dt);
  } else {
    const [nx, nz] = length(dirX, dirZ) > .01 ? normal(dirX, dirZ) : [0, 0];
    const targetX = nx * topSpeed, targetZ = nz * topSpeed;
    const changeX = targetX - p.vx, changeZ = targetZ - p.vz;
    const maxChange = (length(nx, nz) > 0 ? acceleration : acceleration * 1.9) * dt;
    const scale = length(changeX, changeZ) > maxChange ? maxChange / length(changeX, changeZ) : 1;
    p.vx += changeX * scale; p.vz += changeZ * scale;
    if (nx || nz) {
      const [fx, fz] = normal(p.faceX * .43 + nx * .57, p.faceZ * .43 + nz * .57);
      p.faceX = fx; p.faceZ = fz;
    }
  }
  p.x = clamp(p.x + p.vx * dt, -9.0, 9.0);
  p.z = clamp(p.z + p.vz * dt, -15, 15);
  if (Math.abs(p.x) >= 9.0 && p.vx * p.x > 0) p.vx = 0;
  if (Math.abs(p.z) >= 15 && p.vz * p.z > 0) p.vz = 0;
}
function canTouch(s, who) {
  const p = s[who], b = s.ball;
  return length(b.x - p.x, b.z - p.z) < 1.25;
}
function releaseBall(s, who, dx, dz, speed, kind) {
  const p = s[who], b = s.ball;
  if (b.owner !== who && !canTouch(s, who)) return false;
  const [nx, nz] = normal(dx, dz, p.faceX, p.faceZ);
  // Ball launches from the actual ball position; no warping or homing to recipients.
  b.vx = nx * speed + p.vx * .18;
  b.vz = nz * speed + p.vz * .18;
  b.owner = null; b.contact = "RELEASED"; b.releaseTicks = 13; b.firstTouchTicks = 0;
  s.events.push({ type: kind, who, speed });
  return true;
}
function firstTouch(s, who, assist) {
  const p = s[who], b = s.ball;
  if (b.owner || b.releaseTicks > 0) return;
  const dist = length(b.x - p.x, b.z - p.z);
  const relativeSpeed = length(b.vx - p.vx, b.vz - p.vz);
  const limit = assist ? 13.5 : 8.3;
  if (dist > (assist ? 1.15 : .94) || relativeSpeed > limit) return;
  const orientation = (b.x - p.x) * p.faceX + (b.z - p.z) * p.faceZ;
  if (!assist && orientation < -.48) return;
  b.owner = who;
  b.contact = "FIRST_TOUCH";
  b.firstTouchTicks = assist ? 12 : 7;
  b.vx = p.vx + (b.vx - p.vx) * (assist ? .3 : .58);
  b.vz = p.vz + (b.vz - p.vz) * (assist ? .3 : .58);
  s.events.push({ type: "receive", who, assisted: !!assist });
}
function controlledBall(s, dt) {
  const b = s.ball;
  if (!b.owner) return;
  const p = s[b.owner];
  const ahead = p.feintTicks > 0 ? .83 : .73;
  const tx = p.x + p.faceX * ahead, tz = p.z + p.faceZ * ahead;
  const ex = tx - b.x, ez = tz - b.z;
  if (length(b.x - p.x, b.z - p.z) > 2.1) {
    b.owner = null; b.contact = "FREE"; return;
  }
  // Damped virtual foot contact. Limited impulses, no teleports or magnetic reach.
  const k = b.firstTouchTicks > 0 ? 33 : 58;
  const damp = b.firstTouchTicks > 0 ? 13 : 17;
  let ax = ex * k + (p.vx - b.vx) * damp;
  let az = ez * k + (p.vz - b.vz) * damp;
  const a = length(ax, az);
  const limit = b.firstTouchTicks > 0 ? 60 : 95;
  if (a > limit) { ax *= limit / a; az *= limit / a; }
  b.vx += ax * dt; b.vz += az * dt;
  b.contact = b.firstTouchTicks > 0 ? "FIRST_TOUCH" : "CONTROLLED";
  if (b.firstTouchTicks > 0) b.firstTouchTicks--;
}
function tackle(s, who, isSlide = false) {
  const p = s[who], b = s.ball;
  if (p.tackleCooldown > 0) return;
  p.tackleCooldown = isSlide ? 65 : 30;
  const dx = b.x - p.x, dz = b.z - p.z, dist = length(dx, dz);
  const forward = dist > .001 ? (dx * p.faceX + dz * p.faceZ) / dist : 1;
  if (isSlide) {
    p.slideTicks = 17; p.slideCooldown = 72;
    p.vx = p.faceX * 9; p.vz = p.faceZ * 9;
  }
  if (dist < (isSlide ? 2.05 : 1.3) && forward > (isSlide ? .08 : .33)) {
    if (b.owner !== who) {
      b.owner = null; b.contact = "CONTESTED"; b.releaseTicks = 11;
      const [nx, nz] = normal(dx, dz, p.faceX, p.faceZ);
      b.vx = nx * (isSlide ? 9 : 6);
      b.vz = nz * (isSlide ? 9 : 6);
      s.events.push({ type: isSlide ? "slide" : "tackle", who, success: true });
      return;
    }
  }
  s.events.push({ type: isSlide ? "slide" : "tackle", who, success: false });
}
function checkGoal(s) {
  const b = s.ball;
  if (b.z <= -WORLD.halfLength && Math.abs(b.x) < WORLD.goalHalfWidth && b.vz < 0) {
    s.score.player++; s.goalPauseTicks = 78; s.events.push({ type: "goal", who: "player" }); return true;
  }
  if (b.z >= WORLD.halfLength && Math.abs(b.x) < WORLD.goalHalfWidth && b.vz > 0) {
    s.score.opponent++; s.goalPauseTicks = 78; s.events.push({ type: "goal", who: "opponent" }); return true;
  }
  return false;
}
function ballWalls(s) {
  const b = s.ball;
  if (b.x < -WORLD.halfWidth) { b.x = -WORLD.halfWidth; b.vx = Math.abs(b.vx) * .72; b.owner = null; }
  if (b.x > WORLD.halfWidth) { b.x = WORLD.halfWidth; b.vx = -Math.abs(b.vx) * .72; b.owner = null; }
  if (b.z < -WORLD.halfLength) { b.z = -WORLD.halfLength; b.vz = Math.abs(b.vz) * .72; b.owner = null; }
  if (b.z > WORLD.halfLength) { b.z = WORLD.halfLength; b.vz = -Math.abs(b.vz) * .72; b.owner = null; }
}
function separateActors(a, b) {
  const dx = a.x - b.x, dz = a.z - b.z, dist = length(dx, dz);
  if (dist < .85 && dist > .0001) {
    const n = (.85 - dist) / (2 * dist);
    a.x = clamp(a.x + dx * n, -9, 9);
    a.z = clamp(a.z + dz * n, -15, 15);
    b.x = clamp(b.x - dx * n, -9, 9);
    b.z = clamp(b.z - dz * n, -15, 15);
  }
}
function decrementCooldowns(s) {
  for (const p of [s.player, s.opponent]) {
    p.feintCooldown = Math.max(0, p.feintCooldown - 1);
    p.slideCooldown = Math.max(0, p.slideCooldown - 1);
    p.tackleCooldown = Math.max(0, p.tackleCooldown - 1);
    p.feintTicks = Math.max(0, p.feintTicks - 1);
  }
}
export function stepGame(s, input = {}, dt = FIXED_DT) {
  if (Math.abs(dt - FIXED_DT) > 1e-8) throw new Error("Simulation requires fixed 60 Hz steps.");
  s.events = [];
  if (s.phase !== "playing") return s;
  s.tick++;
  if (s.goalPauseTicks > 0) {
    s.goalPauseTicks--;
    if (!s.goalPauseTicks) resetKickoff(s);
    return s;
  }
  s.timeLeft = Math.max(0, s.timeLeft - dt);
  if (s.timeLeft <= 0) { s.phase = "ended"; s.events.push({ type: "end" }); return s; }
  decrementCooldowns(s);

  const x = clamp(input.dx || 0, -1, 1), z = clamp(input.dz || 0, -1, 1);
  const [dx, dz] = length(x, z) > 1 ? normal(x, z) : [x, z];
  const sprint = !!input.e, fine = !!input.q;
  const speed = (fine ? 4.1 : sprint ? 9.15 : 6.6);
  moveActor(s.player, dx, dz, speed, fine ? 30 : 40, dt);

  const b = s.ball, ai = s.opponent, user = s.player;
  let targetX = b.x + b.vx * .16, targetZ = b.z + b.vz * .16;
  // When opponent owns it, move forward; otherwise approach ball predictively.
  if (b.owner === "opponent") { targetX = b.x * .65; targetZ = Math.min(15, b.z + 3); }
  const ex = targetX - ai.x, ez = targetZ - ai.z;
  const [edx, edz] = length(ex, ez) > .35 ? normal(ex, ez) : [0, 0];
  moveActor(ai, edx, edz, 4.6, 28, dt);
  separateActors(user, ai);

  const rising = key => !!input[key] && !s.previousInput[key];
  const falling = key => !input[key] && !!s.previousInput[key];

  if (rising("d")) {
    if (b.owner === "player" && user.feintCooldown === 0) {
      user.feintCooldown = 55; user.feintTicks = 14;
      const side = dx === 0 && dz === 0 ? 1 : (dx * user.faceZ - dz * user.faceX < 0 ? -1 : 1);
      user.vx += -user.faceZ * side * 2.5;
      user.vz += user.faceX * side * 2.5;
      s.events.push({ type: "feint" });
    } else if (b.owner !== "player" && user.slideCooldown === 0) tackle(s, "player", true);
  }
  if (rising("a")) {
    if (b.owner === "player") releaseBall(s, "player", user.faceX, user.faceZ, 12.8, "pass");
    else tackle(s, "player");
  }
  if (rising("w") && b.owner === "player") {
    releaseBall(s, "player", user.faceX, user.faceZ, 17, "through_pass");
  }

  if (!!input.s) {
    s.shoot.charge = clamp(s.shoot.charge + dt, 0, .72);
    s.shoot.held = true;
  } else if (falling("s") && s.shoot.held) {
    const u = clamp(s.shoot.charge / .68, 0, 1);
    const smooth = u * u * (3 - 2 * u);
    releaseBall(s, "player", user.faceX, user.faceZ, 16.5 + 13.0 * smooth, "shot");
    s.shoot.charge = 0; s.shoot.held = false;
  } else { s.shoot.held = false; s.shoot.charge = 0; }

  for (const key of ["a", "s", "d", "w"]) s.previousInput[key] = !!input[key];
  if (b.releaseTicks > 0) b.releaseTicks--;

  // FIRST_TOUCH may only start from an actual contact under a relative speed threshold.
  firstTouch(s, "player", fine);
  firstTouch(s, "opponent", false);

  if (b.owner === "player" && length(b.x - ai.x, b.z - ai.z) < .87 && ai.tackleCooldown === 0) {
    tackle(s, "opponent");
  }
  if (b.owner === "opponent" && length(b.x - ai.x, b.z - ai.z) < 1.3 && ai.tackleCooldown === 0) {
    // AI's possession is a series of touches; do not fire each tick.
    if (rand(s) < .12) releaseBall(s, "opponent", -.17 * b.x + (rand(s) - .5) * .2, 1, 13.3, "ai_shot");
    ai.tackleCooldown = 45;
  }
  controlledBall(s, dt);
  b.x += b.vx * dt; b.z += b.vz * dt;
  const friction = decay(b.owner ? .35 : 1.12, dt);
  b.vx *= friction; b.vz *= friction;
  if (!checkGoal(s)) ballWalls(s);
  return s;
}
