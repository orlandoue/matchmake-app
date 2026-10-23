import test from "node:test";
import assert from "node:assert/strict";
import {newMatch,tickMatch,DT,COURT,solveShot,projectLanding,pointTo} from "./tennis-sim.js";

const advance=(s,ticks,input={})=>{for(let i=0;i<ticks;i++)tickMatch(s,input);return s;};
function startServe(type="d"){
  const s=newMatch(221,"normal");
  advance(s,16,{[type]:true}); // first tap tosses
  advance(s,30,{}); // allow the gauge to rise
  tickMatch(s,{[type]:true}); // second tap strikes
  assert.equal(s.phase,"rally");
  return s;
}
test("fixed deterministic 120Hz and official singles dimensions",()=>{
  assert.equal(DT,1/120);
  assert.equal(COURT.halfLength*2,23.77);
  assert.equal(COURT.singlesHalf*2,8.23);
  assert.equal(COURT.doublesHalf*2,10.97);
  assert.equal(COURT.netCenter,.914);
  assert.throws(()=>tickMatch(newMatch(),{},.016),/120Hz/);
});
test("repeatable seed, user input and AI produce identical physics state",()=>{
  function replay(){
    const s=newMatch(332,"hard");
    advance(s,55,{d:true});
    advance(s,140,{x:1,w:true});
    advance(s,170,{a:true,x:-1});
    return JSON.stringify(s);
  }
  assert.equal(replay(),replay());
});
test("player momentum accelerates, stops and respects near court bounds",()=>{
  const s=newMatch();
  const p=s.players.south;
  tickMatch(s,{x:1});
  assert.ok(p.vx>0&&p.vx<6);
  advance(s,350,{x:1,w:true,z:1});
  assert.ok(p.x<=COURT.playableHalfX);
  assert.ok(p.z<=COURT.playableHalfZ);
  assert.ok(p.z>=.65);
  const speed=Math.hypot(p.vx,p.vz);
  advance(s,30,{});
  assert.ok(Math.hypot(p.vx,p.vz)<speed);
});
test("serve requires a deliberate second press, and rally shot preparation holds",()=>{
  const s=newMatch();
  advance(s,24,{d:true,x:1});
  assert.equal(s.phase,"ready");
  assert.equal(s.serve.toss,true);
  assert.ok(s.ball.y>1.4);
  assert.equal(s.ball.lastHit,null);
  advance(s,8,{x:1});
  tickMatch(s,{d:true,x:1});
  assert.equal(s.phase,"rally");
  assert.ok(s.ball.lastHit==="south");
  const r=newMatch();
  r.phase="rally";r.ball.lastHit="north";
  r.ball.x=0;r.ball.z=-4;r.ball.y=1.4;
  advance(r,24,{d:true,x:1});
  assert.ok(r.players.south.charge>=.18);
  assert.ok(r.players.south.aim>.1);
});
test("ballistic target solver yields a landable outgoing serve inside service box",()=>{
  const s=newMatch();
  const v=solveShot(s,"south","flat",1.2,-4.4,.7,.8,true);
  const impact=projectLanding({...s.ball,...v,lastHit:"south"},3);
  assert.ok(impact, "trajectory lands");
  assert.ok(impact.crossed,"trajectory crosses net");
  assert.ok(impact.netHeight>COURT.netCenter+COURT.ballR,"serve must clear net");
  assert.ok(Math.abs(impact.x-1.2)<.8, "landing x accurate: "+impact.x);
  assert.ok(Math.abs(impact.z+4.4)<.9, "landing z accurate: "+impact.z);
});
test("topspin, slice and lob have distinct trajectories and spin",()=>{
  const s=newMatch(),type=["topspin","slice","lob","flat"];
  const shots=type.map(x=>solveShot(s,"south",x,1,-9,.75,1,false));
  assert.ok(shots[0].spin>0);
  assert.ok(shots[1].spin<0);
  assert.ok(shots[2].vy>shots[3].vy);
  assert.ok(shots.every(v=>Number.isFinite(v.vx)&&Number.isFinite(v.vz)));
});
test("server starts a point from south and tracks a legal return trajectory",()=>{
  const s=startServe("d");
  assert.ok(s.ball.lastHit==="south");
  assert.ok(s.ball.vz<0);
  assert.ok(s.rallyHits>=1);
  assert.ok(s.ball.y>.1);
});
test("wrong-side landing awards point and enters transition state",()=>{
  const s=startServe();
  s.ball.x=0;s.ball.y=.11;s.ball.z=10;s.ball.vy=-3;s.ball.vz=2;
  tickMatch(s,{});
  assert.equal(s.score.north,1);
  assert.equal(s.phase,"point");
});
test("out-of-bounds ball awards point against hitter",()=>{
  const s=startServe();
  s.ball.x=COURT.singlesHalf+1;s.ball.y=.11;s.ball.z=-4;s.ball.vy=-4;
  tickMatch(s,{});
  assert.equal(s.score.north,1);
});
test("second bounce awards point to last hitter",()=>{
  const s=startServe();
  s.ball.x=0;s.ball.y=.11;s.ball.z=-4;s.ball.vy=-4;s.ball.bounces=1;
  tickMatch(s,{});
  assert.equal(s.score.south,1);
});
test("player can earn seven-point short-set victory with two-point margin",()=>{
  const s=startServe();
  for(let i=0;i<6;i++){
    pointTo(s,"south","test");
    assert.equal(s.phase,"point");
    advance(s,170);
    assert.equal(s.phase,"ready");
  }
  pointTo(s,"south","test");
  assert.equal(s.score.south,7);
  assert.equal(s.phase,"finished");
});
test("AI serves and rally state advances on its turn",()=>{
  const s=newMatch();
  s.server="north";s.phase="ready";s.ai.serveTimer=.03;
  advance(s,10);
  assert.equal(s.phase,"rally");
  assert.equal(s.ball.lastHit,"north");
});
test("return timing requires racket reach and ball height",()=>{
  const s=startServe();
  s.ball.x=4;s.ball.y=1;s.ball.z=10;s.ball.vx=0;s.ball.vz=3;
  s.players.south.x=-4;
  advance(s,10,{a:true});
  assert.equal(s.ball.lastHit,"south"); // no new return from outside reach
  // Distinguish no contact by rally count:
  assert.equal(s.rallyHits,1);
});
