import test from "node:test";
import assert from "node:assert/strict";
import {createMotionState,advanceMotion} from "../character-motion.js";
import {driveFootwork,FEEL} from "./tennis-feel.js";

const athlete=()=>({side:"south",x:0,z:10,vx:0,vz:0,faceX:0,faceZ:-1,
  setQuality:0,footworkPhase:0});
const dt=1/120;

test("tennis footwork reaches speed promptly and brakes within a planted step",()=>{
  const p=athlete();
  for(let i=0;i<15;i++)driveFootwork(p,1,0,dt);
  assert.ok(p.vx>=FEEL.walk-.01,"responsive initial acceleration");
  const x=p.x;
  for(let i=0;i<15;i++)driveFootwork(p,0,0,dt);
  assert.ok(Math.abs(p.vx)<.01,"full stop");
  assert.ok(p.x-x<.35,"controlled stopping distance");
  assert.ok(p.plantTimer>0,"brake footplant signalled");
});

test("tennis overlay changes lateral gait while default football pose stays unchanged",()=>{
  const actor={vx:5,vz:0,slideTicks:0,feintTicks:0};
  const ordinary=advanceMotion(createMotionState(),actor,.016);
  const unchanged=advanceMotion(createMotionState(),actor,.016,{tennis:false});
  assert.deepEqual(ordinary,unchanged);
  const shuffle=advanceMotion(createMotionState(),actor,.016,{tennis:true,lateral:1});
  assert.ok(Math.abs(shuffle.leftHipZ)>.05);
  assert.ok(Math.abs(shuffle.rightHipZ)>.05);
  assert.ok(Math.abs(shuffle.leftHipX)<Math.abs(ordinary.leftHipX)+.001);
});

test("braking and split-step produce distinct, bounded poses",()=>{
  const actor={vx:4,vz:0,slideTicks:0,feintTicks:0};
  const neutral=advanceMotion(createMotionState(),actor,.016,{tennis:true});
  const braking=advanceMotion(createMotionState(),actor,.016,{tennis:true,braking:1});
  const split=advanceMotion(createMotionState(),actor,.016,{tennis:true,split:.5});
  assert.ok(braking.rootY<neutral.rootY);
  assert.ok(split.rootY>neutral.rootY);
  assert.ok(Number.isFinite(split.leftKneeX)&&Number.isFinite(split.rightKneeX));
});
