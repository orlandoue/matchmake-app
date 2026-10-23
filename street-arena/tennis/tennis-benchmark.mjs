import assert from "node:assert/strict";
import {writeFileSync} from "node:fs";
import {newMatch,tickMatch,COURT,solveShot,projectLanding} from "./tennis-sim.js";

const serveKeys=["d","a","s"];
const attackTypes=["flat","topspin","slice","lob"];
const legalLanding=(p,service=false)=>!!p&&p.crossed&&
  p.netHeight>COURT.netCenter+COURT.ballR&&Math.abs(p.x)<COURT.singlesHalf&&
  p.z<0&&Math.abs(p.z)<(service?COURT.serviceLine:COURT.halfLength);
const counter=()=>({cases:0,legal:0,returns:0});
function measure(){
  const serves=counter(),attacks=counter();
  const byServe=Object.fromEntries(serveKeys.map(k=>[k,counter()]));
  const byAttack=Object.fromEntries(attackTypes.map(k=>[k,counter()]));
  for(let seed=0;seed<256;seed++){
    const key=serveKeys[seed%serveKeys.length],s=newMatch(seed,"normal");
    for(let i=0;i<16;i++)tickMatch(s,{[key]:true});
    for(let i=0;i<30;i++)tickMatch(s,{});
    tickMatch(s,{[key]:true});
    const legal=legalLanding(projectLanding(s.ball,4),true);
    let returned=false;
    for(let i=0;i<500&&s.phase==="rally";i++){
      tickMatch(s,{});
      if(s.events.some(e=>e.type==="hit"&&e.side==="north"))returned=true;
    }
    for(const row of [serves,byServe[key]]){
      row.cases++;row.legal+=Number(legal);row.returns+=Number(returned);
    }
  }
  for(let seed=0;seed<256;seed++){
    const type=attackTypes[seed%attackTypes.length],s=newMatch(seed,"normal");
    s.phase="rally";
    Object.assign(s.ball,{x:0,y:1.15,z:5,lastHit:"north"});
    const targetX=(seed%2?1:-1)*[3.2,3.8,4][seed%3];
    const v=solveShot(s,"south",type,targetX,-10.8,.8,.95,false);
    Object.assign(s.ball,v,{lastHit:"south",bounces:0,flight:0,netCrossed:false});
    s.rallyHits=2;
    s.players.north.x=-Math.sign(targetX)*3.8;
    s.players.north.z=-13.4;
    const legal=legalLanding(projectLanding(s.ball,3));
    let returned=false;
    for(let i=0;i<500&&s.phase==="rally";i++){
      tickMatch(s,{});
      if(s.events.some(e=>e.type==="hit"&&e.side==="north")){returned=true;break;}
    }
    for(const row of [attacks,byAttack[type]]){
      row.cases++;row.legal+=Number(legal);row.returns+=Number(returned);
    }
  }
  return {version:1,seedRange:"0..255",simulationHz:120,
    ballCollisionRadiusM:COURT.ballR,serves,attacks,byServe,byAttack};
}
const report=measure();
assert.deepEqual(measure(),report,"same scenarios must replay identically");
assert.ok(report.serves.legal>=250,"serve-in regression");
assert.ok(report.serves.returns>=220,"basic CPU return regression");
assert.ok(report.attacks.legal>=250,"attack landing regression");
assert.ok(report.byAttack.flat.returns>=10&&report.byAttack.flat.returns<=48,
  "flat drives should be difficult but not automatic winners");
writeFileSync("street-arena/tennis/tennis-benchmark-result.json",JSON.stringify(report,null,2)+"\n");
console.log("MATCHMAKE TENNIS 512-CASE BENCHMARK PASS",JSON.stringify(report));
