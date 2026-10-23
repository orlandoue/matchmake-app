import test from "node:test";
import assert from "node:assert/strict";
import { FEEL,driveFootwork,strikeQuality } from "./tennis-feel.js";
import { COURT,DT,newMatch,tickMatch,projectLanding } from "./tennis-sim.js";

const player=()=>({side:"south",x:0,z:12,vx:0,vz:0,faceX:0,faceZ:-1,setQuality:0,footworkPhase:0});
test("responsiveness: acceleration, quick brakes, strong pivots",()=>{
 const p=player();
 driveFootwork(p,1,0,DT,{halfX:15,halfZ:22});
 assert.ok(p.vx>0&&p.vx<FEEL.walk);
 for(let i=0;i<20;i++)driveFootwork(p,1,0,DT,{halfX:15,halfZ:22});
 assert.ok(p.vx>6.5);
 const velocity=p.vx;
 for(let i=0;i<9;i++)driveFootwork(p,0,0,DT,{halfX:15,halfZ:22});
 assert.ok(p.vx<velocity*.2);
 for(let i=0;i<20;i++)driveFootwork(p,-1,0,DT,{halfX:15,halfZ:22});
 assert.ok(p.vx< -5.5);
});
test("early shot prep allows movement, sprint raises velocity",()=>{
 const p1=player(),p2=player();
 for(let i=0;i<35;i++){
  driveFootwork(p1,1,0,DT,{prepared:true,halfX:15,halfZ:22});
  driveFootwork(p2,1,0,DT,{sprint:true,halfX:15,halfZ:22});
 }
 assert.ok(p1.vx>5 && p1.vx<6);
 assert.ok(p2.vx>7.5);
});
test("preparation, reach and balance affect power quality",()=>{
 const p=player(),b={x:0,z:11.3,y:1.2};
 const rushed=strikeQuality({...p,vx:7,charge:.05},b);
 const early=strikeQuality({...p,vx:0,charge:.65,setQuality:1},b);
 const stretch=strikeQuality({...p,vx:0,charge:.65,setQuality:1},{x:2.1,z:11.3,y:.5});
 assert.ok(early>rushed+.25);
 assert.ok(stretch<early);
});
test("expanded playable tennis space retains official painted lines",()=>{
 const m=newMatch();
 for(const t of ["flat","topspin","slice","lob"])
  assert.ok(projectLanding({...m.ball,lastHit:"south",vy:4,vz:-15,spin:t==="topspin"?1:0},3));
 assert.ok(COURT.playableHalfX>COURT.singlesHalf+5);
 assert.ok(COURT.playableHalfZ>COURT.halfLength+6);
});
test("opponent reads a serve instead of standing static",()=>{
 const m=newMatch(123);
 for(let i=0;i<12;i++)tickMatch(m,{d:true});
 for(let i=0;i<38;i++)tickMatch(m,{});
 tickMatch(m,{d:true});
 assert.equal(m.phase,"rally");
 const initial=m.players.north.z;
 for(let i=0;i<110&&m.phase==="rally";i++)tickMatch(m,{});
 assert.ok(m.ai.targetZ<-2 && m.ai.targetZ>=-22);
 assert.ok(m.players.north.z!==initial || m.ball.lastHit==="north");
});
