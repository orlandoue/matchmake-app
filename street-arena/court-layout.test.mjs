import test from "node:test";
import assert from "node:assert/strict";
import { COURT } from "./court-config.js";
import { createGameState, stepGame, WORLD, FIXED_DT } from "./simulation-v03.js";
import { readFileSync } from "node:fs";

test("arena ground expanded to 24x38 and scoring physics shares layout", () => {
  assert.equal(COURT.floorHalfWidth * 2, 24);
  assert.equal(COURT.floorHalfLength * 2, 38);
  assert.equal(WORLD.halfWidth, COURT.playHalfWidth);
  assert.equal(WORLD.halfLength, COURT.playHalfLength);
  assert.equal(WORLD.goalHalfWidth, COURT.goalScoreHalfWidth);
  assert.equal(WORLD.crossbar, COURT.goalHeight);
  assert.ok(COURT.playHalfWidth < COURT.floorHalfWidth);
  assert.ok(COURT.playHalfLength < COURT.floorHalfLength);
  assert.ok(COURT.playerHalfWidth < COURT.playHalfWidth);
  assert.ok(COURT.playerHalfLength < COURT.playHalfLength);
  assert.ok(COURT.goalScoreHalfWidth < COURT.goalHalfWidth);
  assert.ok(COURT.fenceHalfWidth > COURT.floorHalfWidth);
  assert.ok(COURT.fenceHalfLength > COURT.floorHalfLength);
});
test("kickoff with four players is symmetric and entirely inside field", () => {
  const s=createGameState();
  assert.equal(Object.keys(s.players).length,4);
  for(const p of Object.values(s.players)){
    assert.ok(Math.abs(p.x) < COURT.playerHalfWidth);
    assert.ok(Math.abs(p.z) < COURT.playerHalfLength);
  }
  assert.equal(s.players.player.z, -s.players.opponent.z);
  assert.equal(s.players.ally.z, -s.players.opponent2.z);
});
test("ball scores only by crossing new goal line between goal posts", () => {
  for(const dir of [-1,1]){
    const s=createGameState();
    s.ball.x=0;s.ball.z=dir*(WORLD.halfLength-.025);
    s.ball.vz=dir*7.5;s.ball.y=.46;
    stepGame(s);
    assert.equal(s.score[dir<0?"player":"opponent"],1);
    assert.ok(s.goalPauseTicks>0);
  }
});
test("ball outside goal mouth bounces off new end wall instead of scoring", () => {
  const s=createGameState();
  s.ball.x=WORLD.goalHalfWidth+.3;
  s.ball.z=-WORLD.halfLength+.02;
  s.ball.vz=-10;
  stepGame(s);
  assert.deepEqual(s.score,{player:0,opponent:0});
  assert.equal(s.ball.z,-WORLD.halfLength);
  assert.ok(s.ball.vz>0);
});
test("fast ball bounces from sideline at the same world coordinate", () => {
  const s=createGameState();
  s.ball.x=WORLD.halfWidth-.02;
  s.ball.z=0;s.ball.vx=12;
  stepGame(s);
  assert.equal(s.ball.x,WORLD.halfWidth);
  assert.ok(s.ball.vx<0);
});
test("4-player simulation stays in enlarged limits under sustained directional input", () => {
  const s=createGameState(23453);
  for(let i=0;i<700;i++) stepGame(s,{dx:1,dz:1,w:true},FIXED_DT);
  for(const p of Object.values(s.players)){
    assert.ok(Math.abs(p.x)<=COURT.playerHalfWidth+.001,p.id+" out of x");
    assert.ok(Math.abs(p.z)<=COURT.playerHalfLength+.001,p.id+" out of z");
  }
});
test("court decor is original generated geometry not remote image dependencies", () => {
  const source=readFileSync(new URL("./court-scene.js",import.meta.url),"utf8");
  const view=readFileSync(new URL("./game.js",import.meta.url),"utf8");
  assert.match(source,/from ".\/court-config.js"/);
  assert.match(source,/CanvasTexture/);
  for(const detail of ["team-bench","training-cone","sports-kit-bag","spare-football","fence-post","arena-floodlight","court-goal-post","matchmake-sponsor","city-building","spectator"])
    assert.ok(source.includes(detail),"Missing decoration "+detail);
  assert.match(view,/buildStreetCourt/);
  assert.doesNotMatch(source,/https?:\/\//);
});
