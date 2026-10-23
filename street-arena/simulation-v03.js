// MatchMake Street Arena Alpha 0.3 — four-player, fixed-step arcade football.
// Simulation is standalone: no renderer, input hardware, timers, network or assets.
import { COURT } from "./court-config.js";
export const FIXED_DT = 1/60;
export const WORLD = Object.freeze({halfWidth:COURT.playHalfWidth,halfLength:COURT.playHalfLength,goalHalfWidth:COURT.goalScoreHalfWidth,crossbar:COURT.goalHeight});
const clamp=(a,min,max)=>Math.max(min,Math.min(max,a));
const mag=(x,z)=>Math.hypot(x,z);
const unit=(x,z,fx=0,fz=-1)=>{const m=mag(x,z);return m>1e-7?[x/m,z/m]:[fx,fz]};
const dist=(a,b)=>mag(a.x-b.x,a.z-b.z);
const forTeam=t=>t==="cyan"?-1:1;
function rng(s){s.seed=(Math.imul(1664525,s.seed)+1013904223)>>>0;return s.seed/4294967296;}
function makePlayer(id,team,x,z){
  return {id,team,x,z,vx:0,vz:0,faceX:0,faceZ:forTeam(team),slideTicks:0,
    tackleCooldown:0,feintCooldown:0,feintTicks:0};
}
export function createGameState(seed=221){
  return {seed:seed>>>0,tick:0,timeLeft:150,phase:"playing",goalPauseTicks:0,
    score:{player:0,opponent:0},events:[],selected:"player",
    players:{
      player:makePlayer("player","cyan",-3.4,8.0),
      ally:makePlayer("ally","cyan",3.7,9.4),
      opponent:makePlayer("opponent","pink",-3.4,-8.0),
      opponent2:makePlayer("opponent2","pink",3.7,-9.4)
    },
    ball:{x:0,z:0,y:.46,vx:0,vz:0,vy:0,spin:0,owner:null,
      contact:"FREE",firstTouchTicks:0,releasedBy:null,releaseTicks:0},
    shot:{held:false,charge:0,aimX:0,finesse:false},
    previousInput:{a:false,s:false,d:false,e:false,q:false}
  };
}
function resetKickoff(s){
  const fresh=createGameState(s.seed);
  s.players=fresh.players;
  Object.assign(s.ball,fresh.ball);
  s.selected="player";
  Object.assign(s.shot,fresh.shot);
  s.previousInput=fresh.previousInput;
}
function move(p,dx,dz,speed,dt,brake=false){
  if(p.slideTicks>0){p.slideTicks--;p.vx*=.965;p.vz*=.965;}
  else{
    const m=mag(dx,dz),[nx,nz]=m>1?[dx/m,dz/m]:[dx,dz];
    const tx=brake?0:nx*speed,tz=brake?0:nz*speed;
    const ax=tx-p.vx,az=tz-p.vz,accel=(brake?82:m>.01?43:77)*dt;
    const scale=mag(ax,az)>accel?accel/mag(ax,az):1;
    p.vx+=ax*scale;p.vz+=az*scale;
    if(m>.01&&!brake){
      const face=unit(p.faceX*.3+nx*.7,p.faceZ*.3+nz*.7);
      p.faceX=face[0];p.faceZ=face[1];
    }
  }
  p.x=clamp(p.x+p.vx*dt,-COURT.playerHalfWidth,COURT.playerHalfWidth);
  p.z=clamp(p.z+p.vz*dt,-COURT.playerHalfLength,COURT.playerHalfLength);
  if(Math.abs(p.x)>=COURT.playerHalfWidth&&p.vx*p.x>0)p.vx=0;
  if(Math.abs(p.z)>=COURT.playerHalfLength&&p.vz*p.z>0)p.vz=0;
}
function kick(s,id,dx,dz,speed,type,{vy=0,spin=0}={}){
  const p=s.players[id],b=s.ball;
  if(b.owner!==id && (dist(p,b)>1.25||b.y>.9))return false;
  const [nx,nz]=unit(dx,dz,p.faceX,p.faceZ);
  b.owner=null;b.contact="RELEASED";b.releasedBy=id;b.releaseTicks=11;b.firstTouchTicks=0;
  b.vx=nx*speed+p.vx*.12;b.vz=nz*speed+p.vz*.12;
  b.vy=vy;b.spin=spin;b.y=Math.max(.46,b.y);
  s.events.push({type,who:id,speed,spin,vy});
  return true;
}
function teammate(s,id){
  const p=s.players[id];
  return Object.values(s.players).find(other=>other.team===p.team&&other.id!==id);
}
function targetPass(s,id,type,dx,dz){
  const p=s.players[id],b=s.ball,mate=teammate(s,id);
  const heading=forTeam(p.team);
  if(type==="directed_pass"){
    const dir=mag(dx,dz)>.12?unit(dx,dz):unit(mate.x-b.x,mate.z-b.z);
    const toMate=unit(mate.x+mate.vx*.18-b.x,mate.z+mate.vz*.18-b.z);
    const dot=dir[0]*toMate[0]+dir[1]*toMate[1];
    const weight=dot>.40?.40:0; // assist only when direction already reasonably close
    kick(s,id,dir[0]*(1-weight)+toMate[0]*weight,dir[1]*(1-weight)+toMate[1]*weight,14.2,type);
    return;
  }
  const lead=type==="lob_through"?3.5:2.4;
  const tx=clamp(mate.x+mate.vx*.33,-COURT.playerHalfWidth+.7,COURT.playerHalfWidth-.7);
  const tz=clamp(mate.z+mate.vz*.3+heading*lead,-COURT.playerHalfLength+.8,COURT.playerHalfLength-.8);
  // The ball never homes to the teammate after the kick.
  kick(s,id,tx-b.x,tz-b.z,type==="lob_through"?18.6:16.2,type,
    type==="lob_through"?{vy:7.2}:{});
}
function standingTackle(s,id,slide=false){
  const p=s.players[id],b=s.ball;
  if(p.tackleCooldown>0)return false;
  p.tackleCooldown=slide?69:28;
  if(slide){p.slideTicks=18;p.vx=p.faceX*10.4;p.vz=p.faceZ*10.4;}
  const d=dist(p,b),[nx,nz]=unit(b.x-p.x,b.z-p.z,p.faceX,p.faceZ);
  const forward=nx*p.faceX+nz*p.faceZ;
  const success=b.y<.9&&d<(slide?2.05:1.28)&&forward>(slide?.06:.25)&&b.owner!==id;
  if(success){
    b.owner=null;b.contact="CONTESTED";b.releasedBy=id;b.releaseTicks=8;
    b.vx=nx*(slide?10:6);b.vz=nz*(slide?10:6);b.spin=0;b.vy=Math.max(0,b.vy);
  }
  s.events.push({type:slide?"slide":"tackle",who:id,success});
  return success;
}
function feint(s,id,dx,dz){
  const p=s.players[id];
  if(p.feintCooldown>0)return;
  p.feintCooldown=48;p.feintTicks=15;
  const rightX=-p.faceZ,rightZ=p.faceX;
  const sign=(dx*rightX+dz*rightZ)>=0?1:-1;
  p.vx+=rightX*sign*3.2;p.vz+=rightZ*sign*3.2;
  s.events.push({type:"feint",who:id});
}
function receive(s){
  const b=s.ball;
  if(b.owner||b.y>.95)return;
  const eligible=Object.values(s.players).map(p=>{
    const d=dist(p,b),rejected=b.releasedBy===p.id&&b.releaseTicks>0;
    const relative=mag(b.vx-p.vx,b.vz-p.vz);
    const limit=p.id===s.selected?13.8:11;
    return {p,d,relative,valid:!rejected&&d<1.10&&relative<limit};
  }).filter(e=>e.valid).sort((a,b)=>a.d-b.d || a.p.id.localeCompare(b.p.id));
  if(!eligible.length)return;
  const {p}=eligible[0];
  b.owner=p.id;b.contact="FIRST_TOUCH";b.firstTouchTicks=9;b.spin=0;
  b.vx=p.vx+(b.vx-p.vx)*.40;
  b.vz=p.vz+(b.vz-p.vz)*.40;
  s.events.push({type:"receive",who:p.id});
  if(p.team==="cyan" && s.selected!==p.id){
    s.selected=p.id;s.events.push({type:"switch",who:p.id});
  }
}
function footControl(s,dt){
  const b=s.ball,p=s.players[b.owner];
  if(!p)return;
  const ahead=p.feintTicks>0?.98:.74;
  const tx=p.x+p.faceX*ahead,tz=p.z+p.faceZ*ahead;
  const ex=tx-b.x,ez=tz-b.z;
  if(dist(p,b)>2.25){b.owner=null;b.contact="FREE";return;}
  const k=b.firstTouchTicks>0?38:66,damper=b.firstTouchTicks>0?12:19;
  let ax=ex*k+(p.vx-b.vx)*damper,az=ez*k+(p.vz-b.vz)*damper;
  const m=mag(ax,az),a=90;
  if(m>a){ax*=a/m;az*=a/m;}
  b.vx+=ax*dt;b.vz+=az*dt;
  if(b.firstTouchTicks>0)b.firstTouchTicks--;
  b.contact=b.firstTouchTicks?"FIRST_TOUCH":"CONTROLLED";
}
function aiMove(s,id,dt){
  const p=s.players[id],b=s.ball,team=forTeam(p.team);
  const mates=Object.values(s.players).filter(q=>q.team===p.team&&q.id!==id);
  const rivalWithBall=b.owner?s.players[b.owner]:null;
  let tx=p.x,tz=p.z,speed=5.4;
  if(b.owner===id){
    tx=clamp(p.x*.55,-9.8,9.8);tz=team*(WORLD.halfLength-2.2);speed=5.8;
  }else if(rivalWithBall&&rivalWithBall.team===p.team){
    // Open lateral support passing lane instead of chasing teammate.
    const m=mates[0];
    tx=clamp(m.x+(p.x<m.x?-5.2:5.2),-9.9,9.9);
    tz=clamp(m.z+team*3.55,-16.9,16.9);
  }else{
    const defenders=Object.values(s.players).filter(q=>q.team===p.team);
    const first=defenders.every(q=>q.id===id||dist(p,b)<=dist(q,b));
    if(first){
      tx=clamp(b.x+b.vx*.13,-10.25,10.25);tz=clamp(b.z+b.vz*.13,-17,17);
    }else{
      const threat=Object.values(s.players).filter(q=>q.team!==p.team)
        .sort((a,b)=>dist(a,p)-dist(b,p))[0];
      tx=clamp((b.x+p.x)*.48+(threat?.x||0)*.10,-9.9,9.9);
      tz=clamp(b.z-team*3.2,-16.9,16.9);
      speed=4.8;
    }
  }
  const vx=tx-p.x,vz=tz-p.z,[dx,dz]=mag(vx,vz)>.25?unit(vx,vz):[0,0];
  move(p,dx,dz,speed,dt);
}
function updateAI(s,dt){
  const b=s.ball;
  for(const id of ["ally","opponent","opponent2","player"]){
    if(id===s.selected)continue;
    aiMove(s,id,dt);
  }
  const owner=s.players[b.owner];
  if(owner && owner.id!==s.selected && owner.feintTicks===0){
    const attackDir=forTeam(owner.team);
    const closeGoal=attackDir<0?owner.z<-6:owner.z>6;
    const immediateThreat=Object.values(s.players).some(p=>p.team!==owner.team&&dist(p,owner)<2);
    if(closeGoal && (immediateThreat || Math.abs(owner.z)>10) && rng(s)<.018){
      kick(s,owner.id,-b.x,attackDir*WORLD.halfLength-b.z,17.7,"ai_shot");
    }else if(immediateThreat&&rng(s)<.016){
      targetPass(s,owner.id,"directed_pass",0,0);
    }
  }
  if(b.owner && owner.team!==s.players[s.selected].team){
    // One opposing player presses; tackle has a cooldown and geometry check.
    for(const p of Object.values(s.players)){
      if(p.id===s.selected||p.team===owner.team||p.tackleCooldown>0)continue;
      if(dist(p,b)<1.10){standingTackle(s,p.id);break;}
    }
  }
}
function separate(s){
  const all=Object.values(s.players);
  for(let i=0;i<all.length;i++)for(let j=i+1;j<all.length;j++){
    const a=all[i],b=all[j],d=dist(a,b);
    if(d<.84&&d>.001){
      const off=(.84-d)/d/2;
      a.x=clamp(a.x+(a.x-b.x)*off,-COURT.playerHalfWidth,COURT.playerHalfWidth);
      a.z=clamp(a.z+(a.z-b.z)*off,-COURT.playerHalfLength,COURT.playerHalfLength);
      b.x=clamp(b.x-(a.x-b.x)*off,-COURT.playerHalfWidth,COURT.playerHalfWidth);
      b.z=clamp(b.z-(a.z-b.z)*off,-COURT.playerHalfLength,COURT.playerHalfLength);
    }
  }
}
function physics(s,dt){
  const b=s.ball;
  footControl(s,dt);
  if(b.owner){b.y=.46;b.vy=0;b.spin=0;}
  else if(b.y>.46||b.vy>0){
    b.vy-=19*dt;b.y+=b.vy*dt;
    if(b.y<.46){b.y=.46;b.vy=Math.abs(b.vy)>.9?-b.vy*.29:0;}
  }
  if(b.spin!==0 && !b.owner) {
    const ax=-b.vz*b.spin*.22,az=b.vx*b.spin*.22;
    b.vx+=ax*dt;b.vz+=az*dt;
    b.spin*=Math.exp(-.6*dt);
  }
  const lastX=b.x,lastZ=b.z;
  b.x+=b.vx*dt;b.z+=b.vz*dt;
  const friction=Math.exp(-(b.y>.47?.19:b.owner?.38:1.08)*dt);
  b.vx*=friction;b.vz*=friction;
  if(b.x>WORLD.halfWidth){b.x=WORLD.halfWidth;b.vx=-Math.abs(b.vx)*.70;b.owner=null;b.spin*=-.65;}
  if(b.x<-WORLD.halfWidth){b.x=-WORLD.halfWidth;b.vx=Math.abs(b.vx)*.70;b.owner=null;b.spin*=-.65;}
  const scoreAt=heading=>{
    const zGoal=heading*WORLD.halfLength,den=b.z-lastZ;
    if(Math.abs(den)<1e-10)return false;
    const t=(zGoal-lastZ)/den;
    if(t<0||t>1)return false;
    const crossingX=lastX+(b.x-lastX)*t;
    return Math.abs(crossingX)<WORLD.goalHalfWidth && b.y<WORLD.crossbar;
  };
  if(b.z<=-WORLD.halfLength && b.vz<0 && scoreAt(-1)){
    s.score.player++;s.goalPauseTicks=78;s.events.push({type:"goal",who:"player"});
  }else if(b.z>=WORLD.halfLength && b.vz>0 && scoreAt(1)){
    s.score.opponent++;s.goalPauseTicks=78;s.events.push({type:"goal",who:"opponent"});
  }else{
    if(b.z<-WORLD.halfLength){b.z=-WORLD.halfLength;b.vz=Math.abs(b.vz)*.71;b.owner=null;}
    if(b.z>WORLD.halfLength){b.z=WORLD.halfLength;b.vz=-Math.abs(b.vz)*.71;b.owner=null;}
  }
  if(b.releaseTicks>0)b.releaseTicks--;
}
export function stepGame(s,input={},dt=FIXED_DT){
  if(Math.abs(dt-FIXED_DT)>1e-8)throw Error("Simulation requires fixed 60 Hz steps.");
  s.events=[];
  if(s.phase!=="playing")return s;
  s.tick++;
  if(s.goalPauseTicks>0){s.goalPauseTicks--;if(!s.goalPauseTicks)resetKickoff(s);return s;}
  s.timeLeft=Math.max(0,s.timeLeft-dt);
  if(s.timeLeft===0){s.phase="ended";s.events.push({type:"end"});return s;}
  const b=s.ball,p=s.players[s.selected];
  for(const actor of Object.values(s.players)){
    actor.tackleCooldown=Math.max(0,actor.tackleCooldown-1);
    actor.feintCooldown=Math.max(0,actor.feintCooldown-1);
    actor.feintTicks=Math.max(0,actor.feintTicks-1);
  }
  const x=clamp(input.dx||0,-1,1),z=clamp(input.dz||0,-1,1),[dx,dz]=mag(x,z)>1?unit(x,z):[x,z];
  const rising=k=>!!input[k]&&!s.previousInput[k];
  const falling=k=>!input[k]&&!!s.previousInput[k];
  const hasBall=b.owner===p.id;
  const canKick=hasBall||(b.owner===null&&dist(p,b)<1.2&&b.y<.88&&!(b.releasedBy===p.id&&b.releaseTicks>0));
  // Shooting is a planting/aiming stance: arrows adjust target without moving.
  if(rising("d")&&canKick){
    s.shot.held=true;s.shot.charge=0;s.shot.aimX=0;
    s.shot.finesse=!!input.q;
  }
  if(s.shot.held&&input.d){
    s.shot.charge=clamp(s.shot.charge+dt,0,.78);
    s.shot.aimX=clamp(s.shot.aimX+dx*11.5*dt,-4.5,4.5);
    s.shot.finesse ||= !!input.q;
  }
  const planting=!!s.shot.held;
  const speed=input.w?9.05:input.q?4.6:6.7;
  move(p,dx,dz,speed,dt,planting);
  if(falling("d")&&s.shot.held){
    const c=clamp(s.shot.charge/.72,0,1);
    const smooth=c*c*(3-2*c);
    const targetX=s.shot.aimX;
    const goalZ=forTeam(p.team)*WORLD.halfLength;
    const finesse=s.shot.finesse;
    const raw=16.5+smooth*13;
    const spin=finesse ? (targetX-p.x>=0?1:-1)*.95 : 0;
    kick(s,p.id,targetX-b.x,goalZ-b.z,raw*(finesse?.84:1),finesse?"finesse_shot":"shot",{spin});
    s.shot.held=false;s.shot.charge=0;
  }
  const attacking=canKick||b.owner===p.id;
  if(rising("q")&&hasBall&&!s.shot.held)feint(s,p.id,dx,dz);
  if(rising("q")&&b.owner&&s.players[b.owner].team!==p.team&&!s.shot.held){
    s.selected=p.id==="player"?"ally":"player";
    s.events.push({type:"switch",who:s.selected});
  }
  if(!s.shot.held&&rising("a")){
    if(attacking)targetPass(s,p.id,"ground_through",dx,dz);
    else standingTackle(s,p.id,false);
  }
  if(!s.shot.held&&rising("e")){
    if(attacking)targetPass(s,p.id,"lob_through",dx,dz);
    else standingTackle(s,p.id,true);
  }
  if(!s.shot.held&&rising("s")&&attacking)targetPass(s,p.id,"directed_pass",dx,dz);
  for(const k of ["a","s","d","e","q"])s.previousInput[k]=!!input[k];
  updateAI(s,dt);
  separate(s);
  // Pickup after movement but before integrating physical ball.
  receive(s);
  physics(s,dt);
  return s;
}
