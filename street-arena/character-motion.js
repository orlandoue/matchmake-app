// Original procedural character animation poses.
// Pure maths; independent of Three.js and physical gameplay.
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
const smooth = (current, target, speed, dt) => current + (target-current)*(1-Math.exp(-speed*dt));
export function createMotionState() {
  return { time:0, phase:0, drive:0, speed:0, action:null, actionAge:0, actionDuration:0, actionSide:1 };
}
const DURATIONS = Object.freeze({
  shot:.43, ai_shot:.43, finesse_shot:.52, directed_pass:.34,
  ground_through:.34, lob_through:.46, receive:.24, feint:.41,
  tackle:.34, slide:.50
});
export function playMotion(motion, type, side = 1) {
  if (!(type in DURATIONS)) return false;
  const duration = DURATIONS[type];
  // Never interrupt an active slide with a short low-priority receive.
  if (motion.action === "slide" && motion.actionAge < motion.actionDuration*.70 && type === "receive") return false;
  motion.action = type;
  motion.actionAge = 0;
  motion.actionDuration = duration;
  motion.actionSide = side >= 0 ? 1 : -1;
  return true;
}
function smoothPulse(t) {
  if (t<=0 || t>=1) return 0;
  return Math.sin(Math.PI*t)**2;
}
export function advanceMotion(m, actor, dt, flags={}) {
  dt=clamp(Number.isFinite(dt)?dt:0,0,.075);
  m.time+=dt;
  const speed=Math.hypot(actor.vx||0,actor.vz||0);
  m.speed=smooth(m.speed,speed,10,dt);
  const drive=clamp(m.speed/8.9,0,1);
  m.drive=smooth(m.drive,drive,9,dt);
  // Footfall phase tracks distance covered, not wall clock time.
  if(m.speed>.08)m.phase+=m.speed*1.57*dt;
  const move=m.drive;
  const wave=Math.sin(m.phase),opposite=-wave;
  const amplitude=(.36+.45*drive)*move;
  const steps=wave*amplitude;
  const bounce=.035*move*(1-Math.cos(m.phase*2))-.005*move;
  const idleBreath=Math.sin(m.time*2.6)*.014*(1-move);
  const defaultPose={
    // Local -Z is forward. Positive hip-x brings its foot toward local -Z.
    leftHipX: steps, rightHipX:-steps,
    leftKneeX: -.16- .70*Math.max(0,-wave)*move,
    rightKneeX: -.16-.70*Math.max(0,wave)*move,
    leftAnkleX: .06, rightAnkleX: .06,
    leftShoulderX:-steps*.84+.10,
    rightShoulderX:steps*.84+.10,
    leftShoulderZ:-.10-move*.12,
    rightShoulderZ:.10+move*.12,
    leftElbowX:-.20-.25*Math.max(0,wave)*move,
    rightElbowX:-.20-.25*Math.max(0,opposite)*move,
    torsoX:-.035-move*.15,
    torsoY: Math.sin(m.phase)*.065*move,
    torsoZ: clamp((actor.vx||0)*.008,-.08,.08)*move,
    rootY: bounce+idleBreath,
    headX: .026+move*.07,
    pelvisY: bounce*.5
  };
  let action=m.action;
  if(action){
    m.actionAge+=dt;
    if(m.actionAge>=m.actionDuration){action=null;m.action=null;}
  }
  const t=action?clamp(m.actionAge/m.actionDuration,0,1):0;
  const pulse=smoothPulse(t);
  const kicking=["shot","ai_shot","finesse_shot","directed_pass","ground_through","lob_through"].includes(action);
  const slide=!!(actor.slideTicks>0 || action==="slide");
  const feint=!!(actor.feintTicks>0 || action==="feint");
  if(kicking){
    const leg=action==="finesse_shot"?"left":"right";
    const height=action==="lob_through"?1.15:action==="finesse_shot"?.92:action==="shot"||action==="ai_shot"?1.12:.68;
    const front=(Math.sin(Math.PI*clamp(t*1.12,0,1))**2);
    defaultPose[leg+"HipX"]+=height*front;
    defaultPose[leg+"KneeX"]=-.32+.30*front;
    defaultPose[leg+"AnkleX"]=-.18*front;
    defaultPose.torsoX-=.20*pulse;
    defaultPose.torsoY+=.25*(leg==="left"?1:-1)*pulse;
    defaultPose.leftShoulderX-=.33*pulse;
    defaultPose.rightShoulderX+=.33*pulse;
    defaultPose.rootY+=.03*pulse;
  }
  if(action==="receive"){
    defaultPose.rightHipX+=.32*pulse;
    defaultPose.rightKneeX-=.45*pulse;
    defaultPose.torsoX+=.13*pulse;
  }
  if(action==="tackle"){
    defaultPose.rightHipX+=.37*pulse;
    defaultPose.leftShoulderX+=.24*pulse;
    defaultPose.torsoX-=.17*pulse;
  }
  if(feint&&!slide){
    const effort=Math.max(pulse, actor.feintTicks>0?.53:0);
    defaultPose.torsoY+=.39*m.actionSide*effort;
    defaultPose.torsoZ+=.15*m.actionSide*effort;
    defaultPose.leftHipX+=.45*effort;
    defaultPose.rightHipX-=.45*effort;
    defaultPose.leftShoulderX-=.34*effort;
    defaultPose.rightShoulderX+=.32*effort;
  }
  if(slide){
    const strength=clamp(actor.slideTicks>0?Math.max(.75,pulse):pulse,0,1);
    defaultPose.torsoX-=.66*strength;
    defaultPose.rootY-=.24*strength;
    defaultPose.leftHipX+=1.0*strength;
    defaultPose.leftKneeX=-.06;
    defaultPose.rightHipX-=.58*strength;
    defaultPose.rightKneeX=-.78;
    defaultPose.leftShoulderX-=.75*strength;
    defaultPose.rightShoulderX+=.5*strength;
    defaultPose.torsoZ+=.12*m.actionSide*strength;
  }
  if(flags.aiming&&!slide){
    defaultPose.leftHipX*=.15;
    defaultPose.rightHipX*=.15;
    defaultPose.leftShoulderX=-.20;
    defaultPose.rightShoulderX=.24;
    defaultPose.torsoX=-.12;
  }
  defaultPose.action=action||"locomotion";
  defaultPose.stride=amplitude;
  defaultPose.speed=m.speed;
  return defaultPose;
}
