import { COURT as C } from "./tennis-sim.js";
import { createAnimatedAthlete } from "../character-rig.js";

export function createTennisVisuals(T,scene) {
  let seed=95477;
  const rand=()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);
  const group=new T.Group();scene.add(group);
  const mat=(c,r=.76,m=.06,e=0,i=0)=>new T.MeshStandardMaterial({color:c,roughness:r,metalness:m,emissive:e,emissiveIntensity:i});
  const unlit=(c)=>new T.MeshBasicMaterial({color:c});
  const blue=0x60f0fc,pink=0xff6caa,white=unlit(0xe9fbff);
  const stats={fence:0,props:0,buildings:0};
  const box=(w,h,d,color,x,y,z,name="decor")=>{
    const o=new T.Mesh(new T.BoxGeometry(w,h,d),color);
    o.name=name;o.position.set(x,y,z);group.add(o);stats.props++;return o;
  };
  const tube=(x1,y1,z1,x2,y2,z2,r,material)=>{
    const a=new T.Vector3(x1,y1,z1),b=new T.Vector3(x2,y2,z2),dir=b.clone().sub(a);
    const m=new T.Mesh(new T.CylinderGeometry(r,r,dir.length(),6),material);
    m.position.copy(a).addScaledVector(dir,.5);
    m.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),dir.normalize());
    group.add(m);return m;
  };
  const stripe=(x1,z1,x2,z2,thick=.055)=>{
    const len=Math.hypot(x2-x1,z2-z1);
    const l=box(len,.021,thick,white,(x1+x2)/2,.058,(z1+z2)/2,"line");
    l.rotation.y=-Math.atan2(z2-z1,x2-x1);
  };
  // Original night rooftop shell and procedural granular acrylic paint.
  scene.background=new T.Color(0x070d20);
  scene.fog=new T.FogExp2(0x090e21,.016);
  scene.add(new T.HemisphereLight(0x9bbfff,0x14283b,2.1));
  scene.add(new T.AmbientLight(0x8d91bf,.7));
  const cv=document.createElement("canvas");cv.width=512;cv.height=1024;
  const ctx=cv.getContext("2d");ctx.fillStyle="#144356";ctx.fillRect(0,0,512,1024);
  for(let i=0;i<15000;i++){
    ctx.fillStyle=rand()>.4?"rgba(185,248,238,.035)":"rgba(7,13,35,.09)";
    ctx.fillRect(rand()*512,rand()*1024,1+rand()*2,1+rand()*2);
  }
  const tex=new T.CanvasTexture(cv);tex.colorSpace=T.SRGBColorSpace;tex.anisotropy=4;
  box(85,.4,100,mat(0x0b1627),0,-.35,0,"night-rooftop");
  box(33,.12,48.3,mat(0x1c2a44,.9),0,-.14,0,"court-platform");
  box(32,.018,47.8,new T.MeshStandardMaterial({map:tex,roughness:.96}),0,-.04,0,"blue-hardcourt");
  box(12.8,.012,C.halfLength*2+.32,mat(0x194e5b,.97),0,-.019,0,"tennis-color-zone");
  const baseline=C.halfLength, singles=C.singlesHalf, doubles=C.doublesHalf;
  for(const side of [-1,1]){
    stripe(-singles,side*baseline,singles,side*baseline,.076);
    stripe(side*singles,-baseline,side*singles,baseline,.08);
    stripe(side*doubles,-baseline,side*doubles,baseline,.06);
    stripe(-singles,side*C.serviceLine,singles,side*C.serviceLine,.067);
  }
  stripe(0,-C.serviceLine,0,C.serviceLine,.052);
  stripe(-doubles,-baseline,-doubles,baseline,.06);
  stripe(doubles,-baseline,doubles,baseline,.06);
  stripe(-.11,baseline, .11,baseline,.065);
  stripe(-.11,-baseline,.11,-baseline,.065);
  // Net slopes from 1.07 m at posts to .914 m at centre.
  const net=new T.MeshBasicMaterial({color:0xd3e5ec,transparent:true,opacity:.34,depthWrite:false});
  const netTrim=unlit(0xebfaff);
  for(const sx of [-1,1])tube(sx*6.02,0,0,sx*6.02,1.07,0,.066,mat(0xc7d6e8,.39,.65));
  for(let x=-6;x<6.1;x+=.28){
    const y=.914+(.156*Math.abs(x)/6);
    tube(x,.05,0,x,y,0,.007,net);
  }
  for(let y=.2;y<1.0;y+=.18)tube(-6,y,0,6,y,0,.006,net);
  for(let x=-6;x<6;x+=.25) {
    const x2=x+.25;
    const y1=.914+.156*Math.abs(x)/6,y2=.914+.156*Math.abs(x2)/6;
    tube(x,y1,0,x2,y2,0,.015,netTrim);
  }
  box(32.6,.09,.12,unlit(0x54d9ed),0,.04,-24,"edge-lights");
  box(32.6,.09,.12,unlit(0xee6b9f),0,.04,24,"edge-lights");
  for(const x of [-16.0,16.0])box(.12,.08,47.3,unlit(x<0?blue:pink),x,.04,0,"sideline-led");
  // Rooftop perimeter barrier / chain fence outside playable rectangle.
  const fenceMat=mat(0x708299,.53,.65),wire=new T.MeshBasicMaterial({color:0x9dc5d5,transparent:true,opacity:.16,depthWrite:false});
  for(const sx of [-17.05,17.05]){
    for(let z=-25;z<=25.1;z+=3.2){tube(sx,0,z,sx,4.2,z,.045,fenceMat);stats.fence++;}
    for(let y=.7;y<4.2;y+=.7){tube(sx,y,-25,sx,y,25,.01,wire);stats.fence++;}
    tube(sx,4.2,-20,sx,4.2,20,.05,fenceMat);
  }
  for(const sz of [-25,25]){
    for(let x=-17.05;x<=17.06;x+=3.2){tube(x,0,sz,x,4.2,sz,.045,fenceMat);stats.fence++;}
    for(let y=.7;y<4.2;y+=.7){tube(-17.05,y,sz,17.05,y,sz,.009,wire);stats.fence++;}
  }
  function label(text,accent,x,y,z,rotation=0){
    const canv=document.createElement("canvas");canv.width=1024;canv.height=256;
    const c=canv.getContext("2d");
    c.fillStyle="#0b1830";c.fillRect(0,0,1024,256);
    c.strokeStyle=accent;c.lineWidth=10;c.strokeRect(8,8,1008,240);
    c.fillStyle="#f2faff";c.font="bold 95px Arial";c.textAlign="center";c.textBaseline="middle";
    c.fillText(text,512,138);
    const tx=new T.CanvasTexture(canv);tx.colorSpace=T.SRGBColorSpace;
    const p=new T.Mesh(new T.PlaneGeometry(11,2.75),new T.MeshBasicMaterial({map:tx,side:T.DoubleSide}));
    p.position.set(x,y,z);p.rotation.y=rotation;group.add(p);
  }
  label("MATCHMAKE TENNIS","#54eaff",0,5.05,-27.2);
  label("NIGHT COURTS","#ff619d",0,5.05,27.2,Math.PI);
  for(const [x,z,color] of [[-19,-26,blue],[19,-26,0xa89aff],[-19,26,0xa89aff],[19,26,pink]]){
    tube(x,0,z,x,11.7,z,.16,fenceMat);
    box(2.0,.28,.95,mat(0xe5faff,.25,.4,color,.8),x,12,z,"floodlight");
    const light=new T.PointLight(color,155,57,2);light.position.set(x,12,z);scene.add(light);
  }
  const bench=mat(0x6d819b,.58,.35),dark=mat(0x0c1930,.91);
  for(const side of [-1,1]){
    const x=side*20.5;
    for(const z of [-6,7]){
      box(3,.15,.94,bench,x,.6,z,"sideline-bench");
      box(3,.72,.16,dark,x,.98,z,"bench-back");
      box(.65,.55,.7,mat(0x384a65,.65),x+1.5,.32,z+1,"equipment-bag");
    }
  }
  // City context behind the fence.
  const buildings=Array.from({length:8},(_,i)=>mat(new T.Color().setHSL(.60+i*.008,.23,.09+i*.01)));
  for(let i=0;i<90;i++){
    const side=i%4,x=side<2?(side===0?-1:1)*(30+rand()*35):(rand()-.5)*135;
    const z=side>=2?(side===2?-1:1)*(36+rand()*25):(rand()-.5)*125;
    const w=3+rand()*8,d=3+rand()*8,h=5+rand()*24;
    box(w,h,d,buildings[i%8],x,h/2-.2,z,"city");
    stats.buildings++;
    if(i%3===0)box(w*.8,.04,.05,unlit(i%2?0x52758e:0xa65783),x,h*.7,z+d/2+.04,"windows");
  }
  // Reuse our original articulated athlete renderer while adding an original racket.
  function athlete(side,kit,skin,number){
    const labelTexture=(text,color="#fff",accent="#6df4ff")=>{
      const cvs=document.createElement("canvas");cvs.width=256;cvs.height=128;
      const c=cvs.getContext("2d");c.fillStyle=accent;c.fillRect(0,0,256,128);
      c.fillStyle="#101a2a";c.font="bold 65px Arial";c.textAlign="center";c.textBaseline="middle";
      c.fillText(text,128,65);const t=new T.CanvasTexture(cvs);t.colorSpace=T.SRGBColorSpace;return t;
    };
    const a=createAnimatedAthlete(T,scene,{kit,skinColor:skin,number,selected:side==="south",labelTexture});
    const racket=new T.Group();racket.name="tennis-racket";
    racket.position.set(0,-.29,-.28);racket.rotation.x=-.68;
    a.racketGrip.add(racket);
    tubeRacket(racket);
    return {...a,racket};
  }
  function tubeRacket(root){
    const handle=new T.Mesh(new T.CylinderGeometry(.05,.062,.68,10),mat(0x22242c,.56,.6));
    handle.rotation.x=Math.PI/2;handle.position.set(0,0,.35);root.add(handle);
    const rim=new T.Mesh(new T.TorusGeometry(.39,.047,9,28),mat(0xd7e3ed,.35,.6));
    rim.scale.y=1.25;rim.position.set(0,0,-.19);root.add(rim);
    const stringMat=new T.LineBasicMaterial({color:0xb5dbed,transparent:true,opacity:.68});
    for(let i=-3;i<=3;i++){
      const pos=i*.098;
      const half=.44*Math.sqrt(Math.max(0,1-pos*pos/(.39*.39)));
      const verts=[new T.Vector3(pos,-half,-.19),new T.Vector3(pos,half,-.19)];
      root.add(new T.Line(new T.BufferGeometry().setFromPoints(verts),stringMat));
      const halfX=.39*Math.sqrt(Math.max(0,1-pos*pos/(.49*.49)));
      root.add(new T.Line(new T.BufferGeometry().setFromPoints([
        new T.Vector3(-halfX,pos,-.19),new T.Vector3(halfX,pos,-.19)
      ]),stringMat));
    }
  }
  const south=athlete("south",0x4de9f7,0xb88462,7),north=athlete("north",0xf65991,0xd29a7c,9);
  // Slightly oversized purely visual ball improves ball reading in a fast arcade match.
  const ball=new T.Mesh(new T.SphereGeometry(C.ballR*1.38,18,12),mat(0xeaff58,.48,.05,0xa6b600,.18));
  ball.name="tennis-ball";scene.add(ball);
  const shadow=new T.Mesh(new T.CircleGeometry(.33,22),new T.MeshBasicMaterial({color:0x020713,transparent:true,opacity:.35,depthWrite:false}));
  shadow.rotation.x=-Math.PI/2;shadow.position.y=.018;scene.add(shadow);
  // Soft projected landing marker is a helpful training aid for arcade feel.
  const landing=new T.Mesh(new T.RingGeometry(.20,.28,30),
    new T.MeshBasicMaterial({color:0xf8e7b8,side:T.DoubleSide,transparent:true,opacity:.7,depthWrite:false}));
  landing.rotation.x=-Math.PI/2;landing.position.y=.075;scene.add(landing);
  return {south,north,ball,shadow,landing,stats,group,
    report:()=>({...stats,courtLength:C.halfLength*2,courtWidth:C.singlesHalf*2,
      totalAreaWidth:32,totalAreaLength:48,netHeight:C.netCenter})};
}
