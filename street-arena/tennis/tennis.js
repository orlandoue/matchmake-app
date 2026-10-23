import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.160.1/build/three.module.js";
import { DT,COURT,newMatch,tickMatch,projectLanding } from "./tennis-sim.js";
import { createTennisVisuals } from "./tennis-scene.js";

const $=id=>document.getElementById(id);
const renderer=new THREE.WebGLRenderer({canvas:$("game"),antialias:true,powerPreference:"high-performance"});
renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.55));
renderer.setSize(innerWidth,innerHeight);
renderer.outputColorSpace=THREE.SRGBColorSpace;
renderer.toneMapping=THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure=1.32;
const scene=new THREE.Scene();
const camera=new THREE.PerspectiveCamera(51,innerWidth/innerHeight,.1,190);
camera.position.set(0,17.2,25.5);
camera.lookAt(0,0,-2.0);
const visual=createTennisVisuals(THREE,scene);
let state=newMatch(),running=false,lag=0,last=performance.now();
let pausedForToast=0,previous=null,cameraMode="tv";
const keys=new Set([""]);
keys.clear();
const valid=new Set(["arrowup","arrowdown","arrowleft","arrowright","a","s","d","q","w","e"]);
document.addEventListener("keydown",e=>{
 const k=e.key.toLowerCase();
 if(valid.has(k)){e.preventDefault();keys.add(k);}
 if(k==="c"&&!e.repeat){
  cameraMode=cameraMode==="tv"?"player":"tv";
  notify(cameraMode==="tv"?"CÁMARA TV":"CÁMARA JUGADOR",.7);
 }
});
document.addEventListener("keyup",e=>keys.delete(e.key.toLowerCase()));
window.addEventListener("blur",()=>keys.clear());
document.querySelectorAll("[data-key]").forEach(button=>{
 const key=button.dataset.key;
 const release=e=>{e.preventDefault();keys.delete(key);button.classList.remove("active");};
 button.addEventListener("pointerdown",e=>{
  e.preventDefault();button.setPointerCapture?.(e.pointerId);
  keys.add(key);button.classList.add("active");
 });
 button.addEventListener("pointerup",release);
 button.addEventListener("pointercancel",release);
 button.addEventListener("lostpointercapture",release);
});
const toast=$("toast");
function notify(message,seconds=1){
 toast.textContent=message;toast.classList.add("show");pausedForToast=seconds;
}
function snapshot(){
 const p=state.players;
 return {sx:p.south.x,sz:p.south.z,nx:p.north.x,nz:p.north.z,
  bx:state.ball.x,by:state.ball.y,bz:state.ball.z};
}
function begin(){
 const difficulty=document.querySelector("input[name=difficulty]:checked")?.value||"normal";
 state=newMatch(20261023,difficulty);previous=snapshot();lag=0;keys.clear();
 running=true;$("menu").classList.add("hidden");notify("¡A JUGAR!");
}
$("start").addEventListener("click",begin);
function finish(){
 running=false;
 const {south,north}=state.score;
 $("description").textContent=(south>north?"¡GANASTE!":"¡FIN DEL PARTIDO!")+" "+south+" - "+north+
  ". Esta es una prueba de las sensaciones de movilidad, anticipación y golpeo; no hay multijugador online todavía.";
 $("start").textContent="JUGAR OTRA PARTIDA →";
 $("menu").classList.remove("hidden");
}
function input(){
 return {x:Number(keys.has("arrowright"))-Number(keys.has("arrowleft")),
  z:Number(keys.has("arrowdown"))-Number(keys.has("arrowup")),
  a:keys.has("a"),s:keys.has("s"),d:keys.has("d"),q:keys.has("q"),
  w:keys.has("w"),e:keys.has("e")};
}
function events(){
 for(const e of state.events){
  if(e.type==="point"){
   notify(e.winner==="south"?"¡PUNTO TUYO!":"¡PUNTO CPU!",.8);
  }else if(e.type==="hit" && e.side==="south"){
   notify(e.quality>.83?"¡GOLPE PERFECTO!":e.quality>.53?"¡BUEN GOLPE!":"¡GOLPE FORZADO!",.5);
  }else if(e.type==="toss"&&e.side==="south"){notify("PULSA OTRA VEZ PARA SACAR",.85);}
  else if(e.type==="serve"&&e.side==="south"){notify("¡SAQUE!",.5);}
  else if(e.type==="match"){notify(e.winner==="south"?"¡VICTORIA!":"FIN DEL PARTIDO",2);finish();}
  if(e.type==="prepare"&&e.side==="south")visual.south.motion.play("tennis_prepare",1);
  if(e.type==="toss"&&e.side==="south")visual.south.motion.play("tennis_prepare",1);
  if((e.type==="hit"||e.type==="serve")){
   const av=e.side==="south"?visual.south:visual.north;
   av.motion.play(e.type==="serve"?"tennis_serve":e.shotType==="slice"?"tennis_slice":
     e.shotType==="lob"?"tennis_lob":"tennis_forehand",1);
  }
 }
}
function render(dt){
 const p=state.players,cur=snapshot(),old=previous||cur,t=Math.min(1,lag/DT);
 const lerp=(a,b)=>a+(b-a)*t;
 const athletes=[["south",visual.south],["north",visual.north]];
 for(const [side,v]of athletes){
  const pos=p[side],newX=side==="south"?cur.sx:cur.nx,newZ=side==="south"?cur.sz:cur.nz;
  const oldX=side==="south"?old.sx:old.nx,oldZ=side==="south"?old.sz:old.nz;
  v.group.position.set(lerp(oldX,newX),0,lerp(oldZ,newZ));
  // Keep the torso generally facing the net while feet run omnidirectionally.
  const face=side==="south"?0:Math.PI;
  const heading=Math.atan2(-pos.faceX,-pos.faceZ);
  const turn=Math.atan2(Math.sin(heading-face),Math.cos(heading-face));
  // Shuffle while prepared; turn more into the run when sprinting or recovering.
  const turnWeight=pos.shot?.20:Math.hypot(pos.vx,pos.vz)>5?.68:.38;
  v.group.rotation.y=face+turn*turnWeight;
  v.motion.update(pos,dt,{aiming:!!pos.shot});
  v.racket.rotation.y=Math.sin(pos.strokeTimer*18)*.9;
  v.racket.rotation.z=pos.strokeTimer>0?.3:0;
  v.racket.rotation.x=(pos.strokeTimer>0?.45:0)+(pos.shot?.18:0);
 }
 visual.ball.position.set(lerp(old.bx,cur.bx),lerp(old.by,cur.by)+visual.ball.userData.groundOffset,lerp(old.bz,cur.bz));
 visual.ball.rotation.x+=state.ball.vz*dt*2;
 visual.shadow.position.set(visual.ball.position.x,.015,visual.ball.position.z);
 visual.shadow.material.opacity=Math.max(.07,.4-state.ball.y*.055);
 const predicted=projectLanding(state.ball,2.7);
 visual.landing.visible=running&&state.phase==="rally"&&predicted!==null;
 if(predicted){
  visual.landing.position.set(predicted.x,.071,predicted.z);
  visual.landing.material.color.setHex(predicted.z>0?0x94faff:0xffaaaf);
 }
 $("southScore").textContent=String(state.score.south);
 $("northScore").textContent=String(state.score.north);
 const phase=state.phase;
 $("status").textContent=phase==="ready"?(state.server==="south"?(state.serve.toss?"2ª PULSACIÓN PARA GOLPEAR":"TU SAQUE · PULSA GOLPE PARA LANZAR"):"SAQUE DE CPU · PREPÁRATE"):
  phase==="rally"?"PELOTEO · ANTICIPA LA TRAYECTORIA":phase==="point"?"SIGUIENTE PUNTO":"PARTIDO TERMINADO";
 $("charge").style.width=Math.round(100*Math.min(1,p.south.charge/.65))+"%";
 $("preparation").textContent=p.south.shot?
  "PREPARANDO "+p.south.shot.toUpperCase()+" · ← → DIRECCIÓN":"MANTÉN GOLPE ANTES DEL CONTACTO";
 if(pausedForToast>0){pausedForToast-=dt;if(pausedForToast<=0)toast.classList.remove("show");}
 const tall=innerWidth/innerHeight<.82;
 // Three-quarter arcade broadcast camera: lower, closer, subtly tracks the rally.
 const xFollow=Math.max(-2,Math.min(2,p.south.x*.16+state.ball.x*.08));
 const zFollow=state.phase==="rally"?Math.max(-2,Math.min(1,state.ball.z*.055)):0;
 const playerCam=cameraMode==="player";
 const target=playerCam?
  new THREE.Vector3(p.south.x*.62,tall?19.2:11.8,p.south.z+(tall?22:15)):
  new THREE.Vector3(xFollow,tall?28:17.2,tall?35.2:25.5+zFollow);
 camera.position.lerp(target,Math.min(1,dt*3.0));
 camera.lookAt(playerCam?
   new THREE.Vector3(p.south.x*.25,0,Math.max(-6,p.south.z-13)):
   new THREE.Vector3(xFollow*.25,0,-2.0+zFollow*.20));
 renderer.render(scene,camera);
}
function loop(now){
 requestAnimationFrame(loop);
 const dt=Math.min(Math.max(0,(now-last)/1000),.09);last=now;
 if(running){
  lag=Math.min(lag+dt,.12);
  const command=input();
  while(lag>=DT&&running){
   previous=snapshot();
   tickMatch(state,command,DT);
   lag-=DT;
   events();
  }
 }
 render(dt);
}
addEventListener("resize",()=>{
 camera.aspect=innerWidth/innerHeight;camera.fov=innerWidth/innerHeight<.82?59:51;
 camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);
 renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.55));
});
window.__matchmakeTennisDebug=()=>({
 state:state.phase,score:{...state.score},rallyHits:state.rallyHits,serve:{...state.serve},cameraMode,
 player:{x:state.players.south.x,z:state.players.south.z,charge:state.players.south.charge},
 ball:{x:state.ball.x,y:state.ball.y,z:state.ball.z},
 scene:visual.report(),avatarYaw:{south:visual.south.group.rotation.y,north:visual.north.group.rotation.y},simHz:Math.round(1/DT)
});
requestAnimationFrame(loop);
