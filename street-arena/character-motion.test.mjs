import test from "node:test";
import assert from "node:assert/strict";
import { advanceMotion, createMotionState, playMotion } from "./character-motion.js";

const idle = {vx:0,vz:0,slideTicks:0,feintTicks:0};
const running = {vx:0,vz:-7.2,slideTicks:0,feintTicks:0};
function iterate(m,p,n,dt=1/60,flags={}) {
  let output;
  for(let i=0;i<n;i++)output=advanceMotion(m,p,dt,flags);
  return output;
}
test("idle has subtle breathing but cannot walk in place",()=>{
  const m=createMotionState();
  const poses=Array.from({length:90},()=>advanceMotion(m,idle,1/60));
  assert.ok(poses.every(p=>Math.abs(p.leftHipX)<1e-7&&Math.abs(p.rightHipX)<1e-7));
  assert.ok(poses.some(p=>Math.abs(p.rootY)>.005));
  assert.ok(poses.every(p=>Math.abs(p.stride)<1e-7));
});
test("speed produces alternating legs and opposing arms",()=>{
  const m=createMotionState();
  const frames=Array.from({length:80},()=>advanceMotion(m,running,1/60));
  assert.ok(Math.max(...frames.map(p=>p.leftHipX))>.26);
  assert.ok(Math.min(...frames.map(p=>p.leftHipX))<-.26);
  assert.ok(frames.some(p=>p.leftHipX>0.15&&p.rightHipX<-.15));
  assert.ok(frames.some(p=>p.leftHipX>0.15&&p.leftShoulderX<-.08));
  assert.ok(frames.some(p=>Math.abs(p.leftKneeX)>.45));
});
test("sprint has larger stride than walking",()=>{
  const a=iterate(createMotionState(),{...idle,vz:-3.0},90);
  const b=iterate(createMotionState(),{...idle,vz:-9},90);
  assert.ok(b.stride>a.stride*1.6);
});
test("stopping fades gait without a snapping joint teleport",()=>{
  const m=createMotionState();
  iterate(m,running,100);
  const before=advanceMotion(m,running,1/60);
  const after=advanceMotion(m,idle,1/60);
  assert.ok(Math.abs(after.leftHipX-before.leftHipX)<.30);
  const rest=iterate(m,idle,90);
  assert.ok(rest.stride<.001);
});
test("procedural action keys play for finite durations",()=>{
  const m=createMotionState();
  for(const kind of ["shot","ai_shot","finesse_shot","ground_through","lob_through","directed_pass","feint","receive","tackle","slide"]){
    assert.equal(playMotion(m,kind),true);
    const midway=iterate(m,idle,5);
    assert.equal(midway.action,kind);
    const ended=iterate(m,idle,100);
    assert.equal(ended.action,"locomotion");
  }
  assert.equal(playMotion(m,"impossible"),false);
});
test("shot swings kicking leg and counterbalances torso",()=>{
  const base=iterate(createMotionState(),idle,10);
  const m=createMotionState();
  playMotion(m,"shot");
  const poses=Array.from({length:26},()=>advanceMotion(m,idle,1/60));
  assert.ok(Math.max(...poses.map(p=>p.rightHipX))>base.rightHipX+.75);
  assert.ok(Math.min(...poses.map(p=>p.torsoX))<base.torsoX-.1);
});
test("Q+D finesse uses opposite kick foot vs power kick",()=>{
  const a=createMotionState(),b=createMotionState();
  playMotion(a,"shot");playMotion(b,"finesse_shot");
  const shot=iterate(a,idle,9),finesse=iterate(b,idle,10);
  assert.ok(shot.rightHipX>shot.leftHipX+.5);
  assert.ok(finesse.leftHipX>finesse.rightHipX+.4);
});
test("slide inclines body and extends front leg",()=>{
  const m=createMotionState();
  playMotion(m,"slide");
  const p=iterate(m,{...idle,slideTicks:13},8);
  assert.ok(p.torsoX<-.5);
  assert.ok(p.leftHipX>.7);
  assert.ok(p.rootY<-.17);
});
test("feint twists torso, no camera/root teleport",()=>{
  const m=createMotionState();playMotion(m,"feint",-1);
  const p=iterate(m,{...idle,feintTicks:10},8);
  assert.ok(Math.abs(p.torsoY)>.15);
  assert.ok(Math.abs(p.rootY)<.10);
});
test("shot-aim stance stills feet while preserving arm balance",()=>{
  const m=createMotionState();
  iterate(m,running,90);
  const a=advanceMotion(m,running,1/60);
  const b=advanceMotion(m,running,1/60,{aiming:true});
  assert.ok(Math.abs(b.leftHipX)<Math.abs(a.leftHipX)+.08);
  assert.equal(b.leftShoulderX,-.20);
});
test("bounded animation outputs when tab resumes after large frame gap",()=>{
  const m=createMotionState();
  const p=advanceMotion(m,{vx:200,vz:-200,slideTicks:20,feintTicks:12},5,{aiming:true});
  for(const [key,value] of Object.entries(p))
    if(typeof value==="number")assert.ok(Number.isFinite(value),"Non-finite pose field: "+key);
  assert.ok(m.time<=.075);
});
