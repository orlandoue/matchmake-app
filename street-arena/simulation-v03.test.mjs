import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createGameState, stepGame, FIXED_DT, WORLD } from "./simulation-v03.js";

const advance=(s,n,input={})=>{for(let i=0;i<n;i++)stepGame(s,input);return s};
const freeBall=(s,x,z)=>Object.assign(s.ball,{x,z,y:.46,vx:0,vz:0,vy:0,spin:0,owner:null,releaseTicks:0,releasedBy:null});
const ownBall=(s,id="player")=>{
  const p=s.players[id];
  Object.assign(s.ball,{x:p.x+p.faceX*.75,z:p.z+p.faceZ*.75,y:.46,vx:0,vz:0,vy:0,spin:0,owner:id,releaseTicks:0,releasedBy:null});
  return s;
};
test("4 on-field players; two distinct teams; deterministic 60Hz",()=>{
  const s=createGameState(345);
  assert.deepEqual(Object.keys(s.players),["player","ally","opponent","opponent2"]);
  assert.equal(Object.values(s.players).filter(p=>p.team==="cyan").length,2);
  assert.equal(Object.values(s.players).filter(p=>p.team==="pink").length,2);
  assert.equal(FIXED_DT,1/60);
  assert.throws(()=>stepGame(s,{},.02),/fixed 60/);
});
test("same seed and inputs repeat all positions/events",()=>{
  const simulate=()=>{
    const s=createGameState(502);
    advance(s,60,{dz:-1,w:true});
    advance(s,22,{q:true,dx:1});
    advance(s,26,{d:true,dx:1});
    stepGame(s,{q:true});
    advance(s,300);
    return JSON.stringify(s);
  };
  assert.equal(simulate(),simulate());
});
test("only arrow directions move controlled athlete; W increases speed",()=>{
  const s=createGameState(),x0=s.players.player.x,z0=s.players.player.z;
  advance(s,8,{w:true});
  assert.equal(s.players.player.x,x0);
  assert.equal(s.players.player.z,z0);
  const sprint=createGameState(),walk=createGameState();
  advance(sprint,25,{dz:-1,w:true});
  advance(walk,25,{dz:-1});
  assert.ok(sprint.players.player.z<walk.players.player.z);
});
test("S is a directed pass to teammate, never charges shot",()=>{
  const s=ownBall(createGameState());
  stepGame(s,{s:true});
  const ev=s.events.find(e=>e.type==="directed_pass");
  assert.ok(ev);
  assert.equal(s.shot.held,false);
  assert.equal(s.ball.owner,null);
  assert.ok(s.ball.vx>0,"pass points toward teammate to the right");
});
test("A and E both create through balls; E has real positive vertical flight",()=>{
  const a=ownBall(createGameState()),e=ownBall(createGameState());
  stepGame(a,{a:true});
  stepGame(e,{e:true});
  assert.ok(a.events.some(x=>x.type==="ground_through"));
  assert.ok(e.events.some(x=>x.type==="lob_through"));
  assert.equal(a.ball.vy,0);
  assert.ok(e.ball.vy>0);
  advance(e,10);
  assert.ok(e.ball.y>.46);
});
test("D held charges and arrow-right moves aiming point, with no lateral dash",()=>{
  const s=ownBall(createGameState());
  const initialX=s.players.player.x;
  advance(s,22,{d:true,dx:1});
  assert.ok(s.shot.held);
  assert.ok(s.shot.charge>.3);
  assert.ok(s.shot.aimX>3.8);
  assert.equal(s.players.player.x,initialX);
  assert.equal(s.ball.owner,"player");
  stepGame(s,{});
  assert.ok(s.events.some(x=>x.type==="shot"));
  assert.ok(s.ball.vx>0,"aim right yields positive x velocity");
  assert.equal(s.shot.held,false);
});
test("D held with left aim can send shot towards opposite corner",()=>{
  const s=ownBall(createGameState());
  advance(s,20,{d:true,dx:-1});
  stepGame(s,{});
  assert.ok(s.ball.vx<0);
});
test("Q+D finesse has spin and lower launch speed than same-charge D",()=>{
  const normal=ownBall(createGameState()),finesse=ownBall(createGameState());
  advance(normal,27,{d:true,dx:1});
  advance(finesse,27,{q:true,d:true,dx:1});
  stepGame(normal,{});stepGame(finesse,{});
  assert.ok(normal.events.some(e=>e.type==="shot"));
  assert.ok(finesse.events.some(e=>e.type==="finesse_shot"));
  assert.ok(finesse.ball.spin>0);
  assert.ok(Math.hypot(finesse.ball.vx,finesse.ball.vz)<Math.hypot(normal.ball.vx,normal.ball.vz));
});
test("defence A robs on foot; defence E slides with recovery",()=>{
  const a=createGameState(),e=createGameState();
  for(const s of [a,e]){
    const p=s.players.player;
    freeBall(s,p.x,p.z-.8);
    s.ball.owner="opponent"; // simulated opponent arrival
  }
  stepGame(a,{a:true});
  stepGame(e,{e:true});
  assert.ok(a.events.some(x=>x.type==="tackle"&&x.who==="player"));
  assert.ok(e.events.some(x=>x.type==="slide"&&x.who==="player"));
  assert.equal(a.players.player.slideTicks,0);
  assert.ok(e.players.player.slideTicks>0);
  assert.ok(e.players.player.tackleCooldown>a.players.player.tackleCooldown);
});
test("teammate receive switches controlled player to receiver",()=>{
  const s=createGameState();
  s.players.ally.x=5;s.players.ally.z=5;
  freeBall(s,5,4.6);
  stepGame(s,{});
  assert.equal(s.ball.owner,"ally");
  assert.equal(s.selected,"ally");
  assert.ok(s.events.some(e=>e.type==="switch"&&e.who==="ally"));
});
test("goal crossing adds only one, resets all four players after celebration",()=>{
  const s=createGameState();
  freeBall(s,0,-15.48);s.ball.vz=-10;
  stepGame(s,{});
  assert.equal(s.score.player,1);
  assert.ok(s.goalPauseTicks>0);
  advance(s,30);
  assert.equal(s.score.player,1);
  advance(s,60);
  assert.equal(Object.keys(s.players).length,4);
  assert.equal(s.ball.owner,null);
});
test("all four avatars stay within legal playable bounds during long simulation",()=>{
  const s=createGameState(901);
  advance(s,5500,{dz:-1,w:true});
  for(const p of Object.values(s.players)){
    assert.ok(Math.abs(p.x)<=9.06,p.id);
    assert.ok(Math.abs(p.z)<=14.96,p.id);
  }
});
test("browser bindings and gameplay references include v03, six action keys",()=>{
  const bridge=readFileSync(new URL("./gameplay-bridge-v03.js",import.meta.url),"utf8");
  const html=readFileSync(new URL("./index.html",import.meta.url),"utf8");
  const view=readFileSync(new URL("./game.js",import.meta.url),"utf8");
  assert.match(bridge,/simulation-v03.js/);
  assert.match(view,/attachGameplayV03/);
  assert.ok(view.includes("opponent2"));
  for(const k of ["arrowup","arrowdown","arrowleft","arrowright","a","s","d","w","q","e"])
    assert.ok(html.includes('data-key="'+k+'"'),"Missing control "+k);
  assert.doesNotMatch(html,/data-key="shift"|data-key=" "/);
  assert.match(html,/Q\+D/);
});
