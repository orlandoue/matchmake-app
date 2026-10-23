import test from "node:test";
import assert from "node:assert/strict";
import { newMatch,tickMatch } from "./tennis-sim.js";

function simulateService(seed,difficulty="normal"){
  const s=newMatch(seed,difficulty);
  for(let i=0;i<7;i++)tickMatch(s,{d:true});
  for(let i=0;i<43;i++)tickMatch(s,{});
  tickMatch(s,{d:true}); // second deliberate hit
  let cpuHit=false,events=0,steps=0;
  while(s.phase==="rally" && steps++<700){
    tickMatch(s,{});
    if(s.ball.lastHit==="north")cpuHit=true;
    events+=s.events.filter(e=>e.type==="hit").length;
  }
  return {cpuHit,events,phase:s.phase,points:{...s.score},steps};
}
test("rally laboratory: baseline CPU returns a meaningful fraction of legal serves",()=>{
  const results=Array.from({length:28},(_,i)=>simulateService(1000+i));
  const returned=results.filter(r=>r.cpuHit).length;
  const points=results.filter(r=>r.phase==="point"||r.phase==="finished").length;
  console.log("TENNIS_RALLY_BENCH",JSON.stringify({sample:results.length,returns:returned,points,examples:results.slice(0,4)}));
  assert.ok(points>=20,"most scripted serves must resolve to a point");
  assert.ok(returned>=5,"rally AI should return at least 5 of 28 basic serves, observed "+returned);
});
