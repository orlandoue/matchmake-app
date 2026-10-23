// MatchMake Tennis - independent deterministic physics and arcade rally kernel.
// No Three.js, DOM, timers or networking. All measurements in metres and seconds.
import {driveFootwork,strikeQuality,forecastIntercept} from "./tennis-feel.js";
export const DT=1/120;
export const COURT=Object.freeze({
  singlesHalf:4.115,doublesHalf:5.485,halfLength:11.885,
  playableHalfX:15.0,playableHalfZ:22.0,
  netCenter:.914,netPost:1.07,serviceLine:6.40,ballR:.0335
});
// ITF Type 2 ball dimensions; aerodynamics are tunable initial estimates, not measured calibration.
export const BALL_PHYSICS=Object.freeze({massKg:.0577,airDensity:1.2,dragCoefficient:.48});
const DRAG_FACTOR=.5*BALL_PHYSICS.airDensity*BALL_PHYSICS.dragCoefficient*Math.PI*COURT.ballR**2/BALL_PHYSICS.massKg;
const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
const hypot=(a,b)=>Math.hypot(a,b);
const signSide=s=>s==="south"?1:-1; // south player is at positive z
const other=s=>s==="south"?"north":"south";
const rng=s=>((s.seed=(Math.imul(s.seed,1664525)+1013904223)>>>0)/4294967296);
const precision=1e-8;
const shotProfiles=Object.freeze({
  flat:{flight:.72,spin:0,side:.03},
  topspin:{flight:1.08,spin:1.2,side:.045},
  slice:{flight:1.25,spin:-.5,side:.035},
  lob:{flight:1.70,spin:.45,side:.015}
});
export const SHOT_TYPES=Object.freeze(Object.keys(shotProfiles));
const makePlayer=(side)=>({side,x:side==="south"?-.35:.35,z:side==="south"?13.4:-13.4,
  vx:0,vz:0,faceX:0,faceZ:side==="south"?-1:1,
  setQuality:0,shot:null,charge:0,aim:0,depth:0,swingCooldown:0,splitTimer:0,
  stroke:null,strokeTimer:0,footworkPhase:0});
export function newMatch(seed=20261023,difficulty="normal"){
  return {seed:seed>>>0,tick:0,phase:"ready",server:"south",lastWinner:null,pointTimer:0,
    difficulty:["easy","normal","hard"].includes(difficulty)?difficulty:"normal",
    score:{south:0,north:0},pointsPlayed:0,rallyHits:0,longestRally:0,
    events:[],players:{south:makePlayer("south"),north:makePlayer("north")},
    ball:{x:0,y:1.30,z:13.1,vx:0,vy:0,vz:0,spin:0,sidespin:0,
      lastHit:null,bounces:0,flight:0,netCrossed:false},
    serve:{toss:false,clock:0},
    inputPrev:{a:false,s:false,d:false,q:false,e:false},ai:{serveTimer:.75,readTimer:0,targetX:0,targetZ:-12}
  };
}
function emitted(s,type,more={}){s.events.push({type,...more});}
function setReady(s){
  for(const side of ["south","north"]){
    const p=s.players[side];
    Object.assign(p,makePlayer(side));
  }
  const server=s.server,p=s.players[server];
  s.ball={x:p.x,y:1.30,z:p.z-signSide(server)*.42,
    vx:0,vy:0,vz:0,spin:0,sidespin:0,lastHit:null,bounces:0,flight:0,netCrossed:false};
  s.phase="ready";s.serve={toss:false,clock:0};s.ai.serveTimer=.88;s.ai.readTimer=0;
}
export function pointTo(s,side,reason){
  if(s.phase!=="rally"&&s.phase!=="ready")return;
  s.score[side]++;s.pointsPlayed++;
  s.longestRally=Math.max(s.longestRally,s.rallyHits);
  s.lastWinner=side;
  emitted(s,"point",{winner:side,reason,score:{...s.score}});
  s.pointTimer=1.35;
  if((s.score.south>=7||s.score.north>=7) &&
     Math.abs(s.score.south-s.score.north)>=2){
    s.phase="finished";emitted(s,"match",{winner:side});
  }else{
    s.phase="point";
    // Short competitive tiebreak-inspired cadence: alternate server every 2 points.
    s.server=(Math.floor(s.pointsPlayed/2)%2===0)?"south":"north";
  }
}
const acceleration=(player,dx,dz,dt,sprint=false,prepared=false)=>driveFootwork(
  player,dx,dz,dt,{sprint,prepared,split:player.splitTimer>0,
    halfX:COURT.playableHalfX,halfZ:COURT.playableHalfZ}
);
function integrate(b,dt){
  const horizontal=Math.hypot(b.vx,b.vz);
  const total=Math.hypot(horizontal,b.vy);
  const drag=DRAG_FACTOR*total;
  const side=b.sidespin*.0080*horizontal;
  const top=b.spin*.0105*horizontal;
  const ax=-drag*b.vx + side*b.vz;
  const az=-drag*b.vz - side*b.vx;
  const ay=-9.81-drag*b.vy-top*horizontal;
  b.vx+=ax*dt;b.vy+=ay*dt;b.vz+=az*dt;
  b.x+=b.vx*dt;b.y+=b.vy*dt;b.z+=b.vz*dt;
  b.flight+=dt;
}
function firstBounce(start,seconds=3){
  const b={...start};
  const steps=Math.ceil(seconds/DT);
  let crossed=false,netHeight=0;
  for(let i=0;i<steps;i++){
    const old={...b};integrate(b,DT);
    if(!crossed && old.z*b.z<=0 && Math.abs(old.z-b.z)>precision){
      const t=old.z/(old.z-b.z);
      netHeight=old.y+(b.y-old.y)*t;
      crossed=true;
    }
    if(b.y<=COURT.ballR && b.vy<0){
      const t=clamp((old.y-COURT.ballR)/(old.y-b.y),0,1);
      return {x:old.x+(b.x-old.x)*t,z:old.z+(b.z-old.z)*t,
        t:(i+t)*DT,netHeight,crossed};
    }
  }
  return null;
}
export function projectLanding(ball,maxSeconds=3){
  if(!ball.lastHit)return null;
  return firstBounce(ball,maxSeconds);
}
function guessLaunch(x,y,z,targetX,targetZ,flight,spin=0,sidespin=0){
  const deltaX=targetX-x,deltaZ=targetZ-z;
  const start={x,y,z,vx:deltaX/flight,vy:(-y+COURT.ballR+.5*9.81*flight*flight)/flight,
    vz:deltaZ/flight,spin,sidespin,flight:0};
  // Bounded inverse ballistics solver: tune velocity against simulated landing,
  // ensuring spin and aerodynamic drag influence where the ball actually lands.
  for(let k=0;k<8;k++){
    const impact=firstBounce(start,3.4);
    if(!impact)break;
    const dx=targetX-impact.x,dz=targetZ-impact.z,dt=flight-impact.t;
    start.vx+=clamp(dx/flight,-5.5,5.5)*.85;
    start.vz+=clamp(dz/flight,-7.5,7.5)*.85;
    start.vy+=clamp(dt*9.81*.52,-2.8,2.8)*.85;
    if(Math.abs(dx)+Math.abs(dz)+Math.abs(dt)<.035)break;
  }
  return start;
}
export function solveShot(s,side,type,targetX,targetZ,charge=0.5,quality=1,serve=false){
  const p=s.players[side], b=s.ball;
  const profile=shotProfiles[type]||shotProfiles.flat;
  // Court-level assistance bounded: spin, timing, preparation and aim matter.
  let speedFactor=1-0.22*(1-quality);
  let flight=profile.flight*(1+.2*(1-charge)) / Math.max(.82,speedFactor);
  const fromY=serve?2.35:Math.max(.52,b.y);
  const intendedX=clamp(targetX,-COURT.singlesHalf+.20,COURT.singlesHalf-.20);
  const intendedZ=clamp(targetZ,-COURT.halfLength+.38,COURT.halfLength-.38);
  const spin=profile.spin, sidespin=profile.side*((intendedX-b.x)>=0?1:-1)*charge;
  const v=guessLaunch(b.x,fromY,b.z,intendedX,intendedZ,flight,spin,sidespin);
  return {...v,spin,sidespin,targetX:intendedX,targetZ:intendedZ,quality,charge,type};
}
function strike(s,side,type,serve=false){
  const p=s.players[side],b=s.ball;
  const prepared=clamp(p.charge/.65,0,1);
  const moving=hypot(p.vx,p.vz);
  const relative=hypot(b.x-p.x,b.z-p.z);
  const balance=clamp(1-moving/10,0,1);
  const reach=clamp(1-Math.max(0,relative-.55)/1.8,0,1);
  const quality=strikeQuality(p,b,{serve});
  const aimed=clamp(p.aim,-1,1),depth=clamp(p.depth,-1,1);
  const targetX=(aimed*3.92)+((rng(s)-.5)*(.54*(1-quality)));
  let targetZ=signSide(side)*(-10.1-1.0*depth);
  if(type==="lob")targetZ=signSide(side)*(-10.9);
  if(type==="slice"&&depth>0.4)targetZ=signSide(side)*(-6.4);
  if(serve){targetZ=signSide(side)*(-4.5-1.0*depth);}
  const v=solveShot(s,side,type,targetX,targetZ,prepared,quality,serve);
  Object.assign(b,{x:b.x,y:serve?2.35:b.y,z:b.z,vx:v.vx,vy:v.vy,vz:v.vz,
    spin:v.spin,sidespin:v.sidespin,lastHit:side,bounces:0,flight:0,netCrossed:false});
  p.swingCooldown=.20;p.shot=null;p.charge=0;p.aim=0;p.depth=0;
  p.stroke=type;p.strokeTimer=.39;
  if(serve){s.phase="rally";s.rallyHits=0;}
  s.rallyHits++;
  emitted(s,serve?"serve":"hit",{side,shotType:type,quality,targetX:v.targetX,targetZ:v.targetZ,
    charge:prepared,contact:{x:b.x,y:b.y,z:b.z},tick:s.tick});
}
function attemptReturn(s,side){
  const p=s.players[side],b=s.ball;
  if(!p.shot||p.swingCooldown>0||s.phase!=="rally"||b.lastHit===side)return false;
  if(Math.sign(b.z)!==signSide(side))return false;
  const d=hypot(b.x-p.x,b.z-p.z);
  const enoughHeight=b.y>.40 && b.y<2.5;
  const reach=1.75 + (p.shot==="slice"?.18:0) + (p.splitTimer>.01?.25:0);
  if(d<reach && enoughHeight && b.bounces<=1){
    strike(s,side,p.shot);return true;
  }
  return false;
}
function updatePlayerInput(s,input,dt){
  const p=s.players.south,b=s.ball;
  const x=clamp(input.x||0,-1,1),z=clamp(input.z||0,-1,1);
  const press=key=>!!input[key]&&!s.inputPrev[key];
  const action=Object.entries({a:"topspin",s:"slice",d:"flat",q:"lob"}).find(([key])=>press(key));
  if(press("e")){p.splitTimer=.3;emitted(s,"split",{side:"south"});}
  if(s.phase==="ready" && s.server==="south" && action){
    if(!s.serve.toss){
      s.serve.toss=true;s.serve.clock=0;
      p.shot=action[1];p.charge=.015;p.aim=0;p.depth=0;
      emitted(s,"toss",{side:"south",type:p.shot});
    }else if(s.serve.clock>.18){
      p.shot=action[1];
      p.charge=clamp(.36+Math.sin(Math.min(s.serve.clock,1.10)/1.10*Math.PI)*.35,.12,.74);
      strike(s,"south",p.shot,true);
      s.serve.toss=false;s.serve.clock=0;
    }
  } else if(s.phase==="rally" && action && !p.shot){
    p.shot=action[1];p.charge=.015;p.aim=0;p.depth=0;
    emitted(s,"prepare",{side:"south",type:p.shot});
  }
  if(p.shot && s.phase==="rally"){
    p.charge=clamp(p.charge+dt,0,.85);
    p.aim=clamp(p.aim+x*dt*1.75,-1,1);
    p.depth=clamp(p.depth-z*dt*1.05,-1,1);
  }
  // During shot preparation, lateral arrows influence court positioning slightly
  // while changing aim; ground positioning is still under user control.
  acceleration(p,x,z,dt,!!input.w,!!p.shot);
  // Serving ball follows the racket hand during preparation; no detached toss.
  if(s.phase==="ready" && s.server==="south"){
    b.x=p.x;b.z=p.z-.46;
    if(s.serve.toss){
      s.serve.clock+=dt;
      b.y=1.25+1.55*Math.sin(Math.min(1,s.serve.clock/1.15)*Math.PI);
      p.charge=clamp(s.serve.clock/1.05,0,1);
      p.aim=clamp(p.aim+x*dt*1.5,-1,1);
      if(s.serve.clock>=1.15){
        s.serve.toss=false;s.serve.clock=0;p.shot=null;p.charge=0;
        pointTo(s,"north","late_serve");
      }
    }else b.y=1.30;
  }
  for(const key of ["a","s","d","q","e"])s.inputPrev[key]=!!input[key];
  if(s.phase==="rally")attemptReturn(s,"south");
}
function updateCPU(s,dt){
  const p=s.players.north,b=s.ball;
  if(s.phase==="ready" && s.server==="north"){
    s.ai.serveTimer-=dt;
    if(s.ai.serveTimer<=0){
      p.shot=rng(s)>.35?"topspin":"slice";p.charge=.4;
      p.aim=(rng(s)-.5)*1.2;
      strike(s,"north",p.shot,true);
    }
    return;
  }
  if(s.phase!=="rally")return;
  const react={easy:.26,normal:.15,hard:.10}[s.difficulty];
  s.ai.readTimer+=dt;
  if(s.ai.readTimer>=react){
    s.ai.readTimer=0;
    if(b.lastHit==="south" && b.vz<0){
      const intercept=forecastIntercept(b,p,DT,integrate,
        {radius:COURT.ballR,ownSide:"north",maxSeconds:2.65});
      if(intercept) {
        s.ai.targetX=clamp(intercept.x,-COURT.playableHalfX,COURT.playableHalfX);
        s.ai.targetZ=clamp(intercept.z-.35,-COURT.playableHalfZ,-.7);
      }
    }else {
      s.ai.targetX=.6;s.ai.targetZ=-12.0;
    }
  }
  const dx=s.ai.targetX-p.x,dz=s.ai.targetZ-p.z;
  const l=hypot(dx,dz);
  acceleration(p,l>.25?dx/l:0,l>.25?dz/l:0,dt,false,l<1.2);
  if(b.lastHit==="south"&&b.vz<0 && b.z<0 && b.y<3.3){
    if(!p.shot){p.shot=(rng(s)<.2?"slice":"topspin");p.charge=.12;p.aim=0;p.depth=0;}
    p.charge=Math.min(.85,p.charge+dt);
    const bias=clamp((s.players.south.x>=0?-.88:.88)+(rng(s)-.5)*.07,-1,1);
    p.aim += (bias-p.aim)*Math.min(1,dt*3);
    attemptReturn(s,"north");
  }
}
function stepBall(s,dt){
  const b=s.ball,old={...b};
  integrate(b,dt);
  // Physical net crossing (unlike cosmetic net-only games).
  if(old.z*b.z<=0 && Math.abs(b.z-old.z)>precision){
    const t=old.z/(old.z-b.z);
    const y=old.y+(b.y-old.y)*t;
    if(y < COURT.netCenter+COURT.ballR && Math.abs(old.x+(b.x-old.x)*t)<COURT.doublesHalf+.55){
      emitted(s,"net",{by:b.lastHit});pointTo(s,other(b.lastHit),"net");return;
    }
    b.netCrossed=true;
  }
  if(Math.abs(b.x)>COURT.playableHalfX+3 || Math.abs(b.z)>COURT.playableHalfZ+3){
    // After a first legal bounce, the opponent loses if the ball gets away.
    // Do NOT reclassify a legal passing winner as an out fault.
    pointTo(s,b.bounces>=1?b.lastHit:other(b.lastHit),b.bounces>=1?"unreachable_winner":"out");
    return;
  }
  if(b.y<=COURT.ballR && b.vy<0){
    const fall=clamp((old.y-COURT.ballR)/(old.y-b.y),0,1);
    b.x=old.x+(b.x-old.x)*fall;
    b.z=old.z+(b.z-old.z)*fall;
    b.y=COURT.ballR;
    const inBounds=Math.abs(b.x)<=COURT.singlesHalf+.10 && Math.abs(b.z)<=COURT.halfLength+.10;
    const otherHalf=Math.sign(b.z)===-signSide(b.lastHit);
    // server short box only on first bounce; prototype ignores left/right diagonals.
    const serveBox=!(s.rallyHits===1) || Math.abs(b.z)<=COURT.serviceLine+.10;
    if(!inBounds||!otherHalf||!serveBox){
      emitted(s,"bounce",{x:b.x,z:b.z,legal:false});
      pointTo(s,other(b.lastHit),!inBounds?"out":!serveBox?"serve_fault":"wrong_side");return;
    }
    b.bounces++;
    emitted(s,"bounce",{x:b.x,z:b.z,legal:true,count:b.bounces});
    if(b.bounces>=2){pointTo(s,b.lastHit,"double_bounce");return;}
    // Calibratable hardcourt restitution and tangential friction impulse.
    b.vy=-b.vy*.73;
    b.vx*=.79;b.vz*=.79;
    const velocity=Math.hypot(b.vx,b.vz);
    if(velocity>1e-5){b.vx+=b.vx/velocity*b.spin*.8;b.vz+=b.vz/velocity*b.spin*.8;}
    b.spin*=.55;b.sidespin*=.55;
  }
}
export function tickMatch(s,input={},dt=DT){
  if(Math.abs(dt-DT)>1e-10)throw Error("MatchMake Tennis simulation requires 120Hz");
  s.events=[];
  if(s.phase==="finished")return s;
  s.tick++;
  if(s.phase==="point"){
    s.pointTimer-=dt;
    if(s.pointTimer<=0)setReady(s);
    return s;
  }
  for(const p of Object.values(s.players)){
    p.swingCooldown=Math.max(0,p.swingCooldown-dt);
    p.strokeTimer=Math.max(0,p.strokeTimer-dt);
    p.splitTimer=Math.max(0,p.splitTimer-dt);
  }
  updatePlayerInput(s,input,dt);
  updateCPU(s,dt);
  if(s.phase==="rally")stepBall(s,dt);
  return s;
}
