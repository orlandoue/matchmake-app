import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createGameState, stepGame, FIXED_DT } from "./simulation.js";

const run = (s, ticks, input = {}) => { for (let i = 0; i < ticks; i++) stepGame(s,input); return s; };
const norm = (a,b) => Math.hypot(a,b);
test("fixed 60Hz only; no variable frame time in physics", () => {
  assert.equal(FIXED_DT, 1/60);
  assert.throws(() => stepGame(createGameState(),{},1/30), /fixed 60 Hz/);
});
test("same seed and inputs produce byte-identical match snapshots", () => {
  function replay() {
    const s=createGameState(123456);
    run(s,120,{dx:1,dz:-1,e:true});
    run(s,60,{dz:-1,q:true});
    run(s,30,{a:true});
    run(s,42,{s:true});
    run(s,30,{});
    return JSON.stringify(s);
  }
  assert.equal(replay(),replay());
});
test("player accelerates rather than teleporting to top speed", () => {
  const s=createGameState();
  stepGame(s,{dx:1});
  assert.ok(s.player.vx>0 && s.player.vx<6.6);
  run(s,100,{dx:1});
  assert.ok(s.player.vx<=6.61);
  assert.ok(s.player.x<=9.0);
});
test("diagonal movement normalized to max speed", () => {
  const a=createGameState(),b=createGameState();
  run(a,40,{dx:1,dz:1}); run(b,40,{dx:1});
  assert.ok(norm(a.player.vx,a.player.vz)<=6.61);
  assert.ok(norm(b.player.vx,b.player.vz)<=6.61);
});
test("input actions do not move avatar as old WASD did", () => {
  const s=createGameState();
  run(s,20,{s:true,q:true,w:true});
  assert.equal(s.player.x,0);
  assert.equal(s.player.z,6);
});
test("first touch Q accepts plausible low-speed ball at the foot", () => {
  const s=createGameState();
  s.ball.z=5.23;
  stepGame(s,{q:true});
  assert.equal(s.ball.owner,"player");
  assert.equal(s.ball.contact,"FIRST_TOUCH");
  assert.ok(s.events.some(e=>e.type==="receive" && e.assisted));
});
test("ball outside physical touch range is not magnetized", () => {
  const s=createGameState(); s.ball.z=3.9;
  run(s,8,{q:true});
  assert.notEqual(s.ball.owner,"player");
});
test("very fast relative reception fails without fine control", () => {
  const s=createGameState(); s.ball.z=5.2;s.ball.vx=20;
  stepGame(s,{});
  assert.equal(s.ball.owner,null);
});
test("controlled ball follows player without teleportation", () => {
  const s=createGameState(); s.ball.z=5.28;
  stepGame(s,{q:true});
  assert.equal(s.ball.owner,"player");
  run(s,60,{dz:-1,q:true});
  assert.equal(s.ball.owner,"player");
  assert.ok(Math.hypot(s.ball.x-s.player.x,s.ball.z-s.player.z)<2.1);
});
function chargedShot(heldTicks) {
  const s=createGameState();
  s.ball.z=5.25;
  stepGame(s,{q:true});
  assert.equal(s.ball.owner,"player");
  for(let i=0;i<heldTicks;i++) {
    stepGame(s,{s:true});
    assert.ok(!s.events.some(e=>e.type==="shot"),"holding must not fire");
  }
  stepGame(s,{});
  assert.ok(s.events.some(e=>e.type==="shot"),"release must fire");
  assert.equal(s.ball.owner,null);
  return {speed:Math.hypot(s.ball.vx,s.ball.vz),s};
}
test("S charges once and release fires; long charge faster", () => {
  const tap=chargedShot(3), held=chargedShot(30);
  assert.ok(held.speed>tap.speed+4);
  assert.ok(held.speed<32);
  assert.equal(held.s.ball.contact,"RELEASED");
});
test("released ball cannot be recaptured on next tick", () => {
  const {s}=chargedShot(5);
  stepGame(s,{q:true});
  assert.equal(s.ball.owner,null);
  assert.ok(s.ball.releaseTicks>0);
});
test("goal adds one point and locks duplicate score during freeze", () => {
  const s=createGameState(); s.ball.z=-15.49;s.ball.vz=-4;
  stepGame(s,{});
  assert.equal(s.score.player,1);
  assert.ok(s.goalPauseTicks>0);
  run(s,50);
  assert.equal(s.score.player,1);
});
test("failed slide has cooldown and recovery", () => {
  const s=createGameState(); stepGame(s,{d:true});
  assert.ok(s.player.slideCooldown>0);
  assert.ok(s.player.slideTicks>0);
  assert.ok(s.events.some(e=>e.type==="slide" && !e.success));
  run(s,10,{d:true});
  assert.ok(s.player.slideCooldown>0);
  assert.ok(s.player.slideTicks<17);
});
test("arrows and ASDWQE are browser bindings, no space or shift", () => {
  const bridge=readFileSync(new URL("./gameplay-bridge.js",import.meta.url),"utf8");
  const html=readFileSync(new URL("./index.html",import.meta.url),"utf8");
  assert.match(bridge,/arrowleft.*arrowright/);
  assert.match(bridge,/"a","s","d","w","q","e"/);
  assert.doesNotMatch(html,/data-key="shift"|data-key=" "/);
  for(const k of ["arrowup","arrowdown","arrowleft","arrowright","a","s","d","w","q","e"])
    assert.ok(html.includes('data-key="'+k+'"'),"Missing control "+k);
});
