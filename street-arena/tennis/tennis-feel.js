// Original arcade tennis locomotion + interception model (VT3-inspired principles).
// Pure functions, no rendering, no proprietary gameplay formulas.
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const mag=(x,z)=>Math.hypot(x,z);
export const FEEL=Object.freeze({
  walk:6.9,sprint:8.15,prepared:5.4,
  accelerate:56,brake:84,cut:92,splitBurst:1.14,
  comfortableReach:1.35,lungeReach:2.20
});
export function driveFootwork(p,dx,dz,dt,{sprint=false,prepared=false,split=false,halfX=15,halfZ=22}={}){
  const l=mag(dx,dz);
  if(l>1){dx/=l;dz/=l;}
  let top=sprint?FEEL.sprint:prepared?FEEL.prepared:FEEL.walk;
  if(split && l>.1)top*=FEEL.splitBurst;
  const speedBefore=mag(p.vx,p.vz);
  const tx=dx*top,tz=dz*top;
  const deltaX=tx-p.vx,deltaZ=tz-p.vz;
  const dot=tx*p.vx+tz*p.vz;
  const acceleration=l<.01?FEEL.brake:dot<-.05?FEEL.cut:FEEL.accelerate;
  const maxDelta=acceleration*dt,change=mag(deltaX,deltaZ);
  const factor=change>maxDelta?maxDelta/change:1;
  p.vx+=deltaX*factor;p.vz+=deltaZ*factor;
  const oldX=p.x,oldZ=p.z;
  p.x=clamp(oldX+p.vx*dt,-halfX,halfX);
  p.z=clamp(oldZ+p.vz*dt,p.side==="south"?.6:-halfZ,p.side==="south"?halfZ:-.6);
  if(p.x!==oldX+p.vx*dt)p.vx=0;
  if(p.z!==oldZ+p.vz*dt)p.vz=0;
  if(l>.08){p.faceX=dx;p.faceZ=dz;}
  const actual=mag(p.vx,p.vz);
  const hardBrake=speedBefore>2 && speedBefore-actual>18*dt;
  p.plantTimer=hardBrake?.14:Math.max(0,(p.plantTimer||0)-dt);
  p.lateralBlend=actual>.1?clamp(p.vx/actual, -1,1)*clamp(actual/3,0,1):0;
  p.setQuality=clamp((p.setQuality||0)+(actual<1.8?1.2:-.9)*dt,0,1);
  p.footworkPhase=(p.footworkPhase||0)+actual*dt*1.45;
}
export function strikeQuality(p,ball,{serve=false}={}){
  const preparation=clamp((p.charge||0)/.66,0,1);
  const speed=mag(p.vx||0,p.vz||0);
  const relative=mag((ball.x||0)-p.x,(ball.z||0)-p.z);
  const reach=clamp(1-Math.max(0,relative-.65)/1.65,0,1);
  const height=serve?1:clamp(1-Math.abs((ball.y||1)-1.18)/1.8,0,1);
  const stability=clamp(1-speed/11,0,1);
  // Enough chance to survive emergency contacts while anticipation still dominates.
  return clamp(.20+.35*preparation+.18*stability+.14*reach+.08*height+
    .05*clamp(p.setQuality||0,0,1),.18,1);
}
export function forecastIntercept(ball,player,dt,integrate,{radius=.105,ownSide="north",maxSeconds=3.2}={}){
  if(!ball?.lastHit)return null;
  const b={...ball};
  const ownSign=ownSide==="south"?1:-1;
  const n=Math.ceil(maxSeconds/dt);
  let bounceCount=b.bounces||0,best=null;
  for(let i=1;i<=n;i++){
    integrate(b,dt);
    if(b.y<=radius&&b.vy<0){
      if(bounceCount>=1)break;
      b.y=radius;b.vy=-b.vy*.73;b.vx*=.79;b.vz*=.79;
      bounceCount++;
    }
    if(b.z*ownSign<=.01 || b.y<.45 || b.y>2.85)continue;
    const t=i*dt;
    const away=mag(b.x-player.x,b.z-player.z);
    const reach=FEEL.walk*t+FEEL.comfortableReach;
    const error=Math.max(0,away-reach);
    // Prioritise playable late-bounce contacts that reduce sprinting into the net.
    const weight=error*6+t*.20+(bounceCount===0?.24:0)+Math.max(0,3.5-Math.abs(b.z))*.04;
    if(!best||weight<best.weight){
      best={x:b.x,z:b.z,y:b.y,t,reachable:error<.25,weight,bounced:bounceCount>0};
    }
  }
  return best;
}
