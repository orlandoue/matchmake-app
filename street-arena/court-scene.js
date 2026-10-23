import { COURT as C } from "./court-config.js";

// Procedural MatchMake night arena: no external textures, brands or model downloads.
export function buildStreetCourt(THREE, scene, { labelTexture }) {
  const root = new THREE.Group();
  root.name = "MatchMake enlarged urban arena";
  scene.add(root);
  const stats = {ground:0, lines:0, props:0, lights:0, fencing:0, spectators:0, buildings:0};
  let seed = 13629;
  const random = () => ((seed = (Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);
  const material = (color, roughness=.82, metalness=.03, emissive=0, emissiveIntensity=0) =>
    new THREE.MeshStandardMaterial({color,roughness,metalness,emissive,emissiveIntensity});
  const basic = color => new THREE.MeshBasicMaterial({color});
  const lineWhite=basic(0xc3f5fa), electric=basic(0x48dff6), magenta=basic(0xfc5a91);
  const charcoal=material(0x111a2b,.83), steel=material(0x617487,.42,.72);
  const stone=material(0x202a40,.85);
  const makeBox = (w,h,d,mat,x,y,z,name="",kind="props") => {
    const mesh=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),mat);
    mesh.position.set(x,y,z);
    mesh.name=name;
    root.add(mesh);
    stats[kind]++;
    return mesh;
  };
  const pipe=(x1,y1,z1,x2,y2,z2,r,mat,name="",kind="props")=>{
    const a=new THREE.Vector3(x1,y1,z1),b=new THREE.Vector3(x2,y2,z2);
    const dir=b.clone().sub(a);
    const mesh=new THREE.Mesh(new THREE.CylinderGeometry(r,r,dir.length(),7),mat);
    mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),dir.clone().normalize());
    mesh.position.copy(a).addScaledVector(dir,.5);mesh.name=name;root.add(mesh);stats[kind]++;
    return mesh;
  };
  const stripe=(x1,z1,x2,z2,width,mat,height=.054)=>{
    const dx=x2-x1,dz=z2-z1;
    const m=makeBox(Math.hypot(dx,dz),.018,width,mat,(x1+x2)/2,height,(z1+z2)/2,"court-line","lines");
    m.rotation.y=-Math.atan2(dz,dx);
    return m;
  };
  const addRing=(radius,width,x,z,mat)=>{
    const ring=new THREE.Mesh(new THREE.RingGeometry(radius-width/2,radius+width/2,72),mat);
    ring.rotation.x=-Math.PI/2;ring.position.set(x,.075,z);
    ring.name="court-circle";root.add(ring);stats.lines++;
  };
  // Canvas-based asphalt; deterministic wear, hairline scratches and soft colored patches.
  const canvas=document.createElement("canvas");
  canvas.width=512;canvas.height=1024;
  const ctx=canvas.getContext("2d");
  ctx.fillStyle="#203c47";ctx.fillRect(0,0,512,1024);
  for(let i=0;i<18500;i++){
    const n=random();
    ctx.fillStyle=n>.53 ? "rgba(143,185,192,.080)" : "rgba(1,9,19,.12)";
    ctx.fillRect(random()*512,random()*1024, .5+random()*2.6,.5+random()*2.1);
  }
  for(let i=0;i<65;i++){
    ctx.strokeStyle=random()>.5?"rgba(7,16,26,.15)":"rgba(173,219,218,.05)";
    ctx.lineWidth=.5+random()*1.5;ctx.beginPath();
    const x=random()*512,y=random()*1024;
    ctx.moveTo(x,y);ctx.lineTo(x+random()*50-25,y+random()*150-75);ctx.stroke();
  }
  for(const x of [75,437]) {
    const glow=ctx.createLinearGradient(x-55,0,x+55,0);
    glow.addColorStop(0,"rgba(55,230,239,0)");
    glow.addColorStop(.5,x<256?"rgba(65,197,224,.10)":"rgba(236,75,137,.08)");
    glow.addColorStop(1,"rgba(55,230,239,0)");
    ctx.fillStyle=glow;ctx.fillRect(x-55,0,110,1024);
  }
  const map=new THREE.CanvasTexture(canvas);
  map.colorSpace=THREE.SRGBColorSpace;
  map.anisotropy=4;
  makeBox(96,.4,118,charcoal,0,-.33,0,"city-pavement","ground");
  makeBox(C.floorHalfWidth*2+1.1,.13,C.floorHalfLength*2+1.3,stone,0,-.16,0,"court-base","ground");
  makeBox(C.floorHalfWidth*2,.025,C.floorHalfLength*2,
    new THREE.MeshStandardMaterial({map,roughness:.94,metalness:.02}),
    0,-.077,0,"court-pitch","ground");
  const panel=material(0x26434b,.97);
  for(let i=-10;i<=10;i+=4)makeBox(4,.008,C.floorHalfLength*2-.5,panel,i,-.058,0,"worn-asphalt-panel","ground");
  // Bounds align to the physical collision/scoring surface, not the outside fence.
  for(const x of [-C.playHalfWidth,C.playHalfWidth])stripe(x,-C.playHalfLength,x,C.playHalfLength,.095,lineWhite);
  for(const z of [-C.playHalfLength,C.playHalfLength])stripe(-C.playHalfWidth,z,C.playHalfWidth,z,.095,lineWhite);
  stripe(-C.playHalfWidth,0,C.playHalfWidth,0,.08,lineWhite);
  addRing(C.centerCircleRadius,.085,0,0,lineWhite);
  // Center spot, penalty marks, end zones and short penalty arcs.
  addRing(.14,.1,0,0,lineWhite);
  for(const dir of [-1,1]) {
    const end=dir*C.playHalfLength;
    const inner=end-dir*4.1;
    stripe(-5.4,inner,5.4,inner,.09,lineWhite);
    stripe(-5.4,inner,-5.4,end,.09,lineWhite);
    stripe(5.4,inner,5.4,end,.09,lineWhite);
    addRing(.15,.06,0,end-dir*3,lineWhite);
    stripe(-3.9,end-dir*.8,3.9,end-dir*.8,.045,dir<0?electric:magenta);
    // Corners: short L marks in a legal playable field.
    for(const sx of [-1,1]){
      stripe(sx*(C.playHalfWidth-.75),end,sx*C.playHalfWidth,end,.065,lineWhite);
      stripe(sx*C.playHalfWidth,end-dir*.75,sx*C.playHalfWidth,end,.065,lineWhite);
    }
  }
  for(const sx of [-1,1]) {
    makeBox(.21,.11,C.playHalfLength*2+.4,sx<0?electric:magenta,sx*(C.floorHalfWidth+.05),.055,0,"edge-neon", "ground");
    // Inlaid luminous court trim contrasts the asphalt without confusing ball bounds.
    makeBox(.07,.018,C.playHalfLength*2+.1,sx<0?magenta:electric,sx*(C.playHalfWidth+.28),.036,0,"lane-light", "ground");
  }
  for(const sz of [-1,1])makeBox(C.floorHalfWidth*2,.12,.18,sz<0?electric:magenta,0,.05,sz*(C.floorHalfLength+.08),"end-neon","ground");

  // Goals: physical scoring plane at ±18.2; deep frames stay well inside the fence.
  const goalPost=material(0xe7faff,.24,.57,0x235674,.45);
  const net=new THREE.MeshBasicMaterial({color:0xb9dfec,transparent:true,opacity:.27,depthWrite:false});
  for(const dir of [-1,1]){
    const front=dir*C.playHalfLength;
    const back=front+dir*1.35;
    for(const sx of [-1,1]){
      pipe(sx*C.goalHalfWidth,0,front,sx*C.goalHalfWidth,C.goalHeight,front,.107,goalPost,"court-goal-post");
      pipe(sx*C.goalHalfWidth,C.goalHeight,front,sx*C.goalHalfWidth,C.goalHeight,back,.04,steel);
      pipe(sx*C.goalHalfWidth,0,front,sx*C.goalHalfWidth,0,back,.035,steel);
    }
    pipe(-C.goalHalfWidth,C.goalHeight,front,C.goalHalfWidth,C.goalHeight,front,.12,goalPost,"court-goal-crossbar");
    pipe(-C.goalHalfWidth,C.goalHeight,back,C.goalHalfWidth,C.goalHeight,back,.034,steel);
    for(let x=-C.goalHalfWidth;x<=C.goalHalfWidth+.01;x+=.48){
      pipe(x,.1,back,x,C.goalHeight,back,.009,net);
      pipe(x,C.goalHeight,front,x,C.goalHeight,back,.008,net);
    }
    for(let y=.1;y<=C.goalHeight+.01;y+=.37){
      pipe(-C.goalHalfWidth,y,back,C.goalHalfWidth,y,back,.009,net);
    }
  }

  // Four mesh-panel fence sides, but no additional collision walls inside pitch.
  const wires=new THREE.MeshBasicMaterial({color:0x9badbe,transparent:true,opacity:.20,depthWrite:false});
  for(const x of [-C.fenceHalfWidth,C.fenceHalfWidth]) {
    for(let z=-C.fenceHalfLength;z<=C.fenceHalfLength+.01;z+=3.1)
      pipe(x,.05,z,x,5.25,z,.055,steel,"fence-post","fencing");
    for(let y=.75;y<=5.25;y+=.75)
      pipe(x,y,-C.fenceHalfLength,x,y,C.fenceHalfLength,.012,wires,"fence-wire","fencing");
    pipe(x,5.25,-C.fenceHalfLength,x,5.25,C.fenceHalfLength,.065,steel,"fence-top","fencing");
  }
  for(const z of [-C.fenceHalfLength,C.fenceHalfLength]){
    for(let x=-C.fenceHalfWidth;x<=C.fenceHalfWidth+.01;x+=3.2)
      pipe(x,.05,z,x,5.25,z,.053,steel,"fence-post","fencing");
    for(let y=.75;y<=5.25;y+=.75)
      pipe(-C.fenceHalfWidth,y,z,C.fenceHalfWidth,y,z,.011,wires,"fence-wire","fencing");
    pipe(-C.fenceHalfWidth,5.25,z,C.fenceHalfWidth,5.25,z,.065,steel,"fence-top","fencing");
  }
  // Sideboards, original sponsor visuals and match identity.
  function board(text,z,direction,color,width=11) {
    const mesh=new THREE.Mesh(new THREE.PlaneGeometry(width,2.8),
      new THREE.MeshBasicMaterial({map:labelTexture(text,"#e8fbff",color),side:THREE.DoubleSide}));
    mesh.position.set(0,5.55,z);if(direction>0)mesh.rotation.y=Math.PI;
    mesh.name="matchmake-sponsor";root.add(mesh);stats.props++;
  }
  board("MATCHMAKE",-C.fenceHalfLength-1.2,-1,"#59eeff",12.3);
  board("STREET ARENA",C.fenceHalfLength+1.2,1,"#ff5a96",13.5);
  for(const side of [-1,1]) {
    for(const z of [-10,0,10]){
      makeBox(.26,1.0,6.6,charcoal,side*(C.fenceHalfWidth+.36),.50,z,"sideline-barrier");
      makeBox(.22,.13,6.6,side<0?electric:magenta,side*(C.fenceHalfWidth+.35),1.03,z,"sideline-led");
    }
  }
  // Urban sports props deliberately OUTSIDE the fenced perimeter.
  const bench=material(0x788496,.55,.45),shoeBag=material(0x5a6991);
  for(const sx of [-1,1]) {
    const bx=sx*(C.fenceHalfWidth+3.0);
    for(const z of [-8,7.5]) {
      makeBox(2.7,.16,.85,bench,bx,.55,z,"team-bench");
      makeBox(2.7,.65,.16,charcoal,bx+sx*.37,.91,z,"bench-back");
      for(const oz of [-.28,.28]) {
        pipe(bx-.9,.06,z+oz,bx-.9,.55,z+oz,.055,steel);
        pipe(bx+.9,.06,z+oz,bx+.9,.55,z+oz,.055,steel);
      }
      makeBox(.92,.63,.53,shoeBag,bx+sx*1.25,.33,z+1.35,"sports-kit-bag");
      for(let i=0;i<3;i++){
        const cone=new THREE.Mesh(new THREE.ConeGeometry(.18,.45,8),basic(0xf4a546));
        cone.position.set(bx+(i-1)*.47,.25,z-1.55);cone.name="training-cone";
        root.add(cone);stats.props++;
      }
    }
  }
  for(const z of [-11,12]){
    const b=new THREE.Mesh(new THREE.SphereGeometry(.32,12,10),material(0xe9f2f6,.42));
    b.position.set(C.fenceHalfWidth+2.45,.34,z);b.name="spare-football";
    root.add(b);stats.props++;
  }
  // City floodlights with emissive heads; limit actual shadowless point lights to four.
  const lampMat=material(0xddf9ff,.25,.55,0x78eaff,.65);
  for(const [x,z,col] of [
    [-C.fenceHalfWidth-1.55,-C.fenceHalfLength-1.5,0x62f0ff],
    [ C.fenceHalfWidth+1.55,-C.fenceHalfLength-1.5,0xa689ff],
    [-C.fenceHalfWidth-1.55, C.fenceHalfLength+1.5,0x939aff],
    [ C.fenceHalfWidth+1.55, C.fenceHalfLength+1.5,0xff6993]]) {
    pipe(x,0,z,x,C.lightHeight,z,.14,steel,"floodlight-pole","lights");
    makeBox(2.1,.28,.9,lampMat,x,C.lightHeight+.20,z,"arena-floodlight","lights");
    const point=new THREE.PointLight(col,125,55,2);
    point.position.set(x,C.lightHeight,z);root.add(point);stats.lights++;
  }
  // Procedural skyline further back; leave the play area and safety margins open.
  const buildingMaterials=Array.from({length:8},(_,i)=>material(new THREE.Color().setHSL(.595+i*.012,.22,.08+i*.014)));
  for(let i=0;i<88;i++){
    const side=i%4;
    const x=side<2?(side===0?-1:1)*(25+random()*31):(random()-.5)*108;
    const z=side>=2?(side===2?-1:1)*(29+random()*25):(random()-.5)*105;
    const w=2.5+random()*6,d=3+random()*6,h=5+random()*23;
    makeBox(w,h,d,buildingMaterials[i%8],x,h/2-.2,z,"city-building","buildings");
    if(i%3===0){
      const windows=basic(random()>.48?0x5190a7:0xaa6389);
      makeBox(w*.77,.065,.06,windows,x,h*.72,z+d/2+.05,"lit-apartment-window","buildings");
    }
  }
  // Carefully restrained crowd silhouettes behind wire fencing, never inside court.
  const crowd=[material(0x4b627d),material(0x414a70),material(0x655371)];
  for(let i=0;i<90;i++){
    const sx=i%2?-1:1,x=sx*(C.fenceHalfWidth+.9+random()*.7),
      z=(random()-.5)*C.fenceHalfLength*1.85;
    const human=new THREE.Mesh(new THREE.CapsuleGeometry(.17,.43,3,5),crowd[i%3]);
    human.position.set(x,.54,z);human.name="spectator";root.add(human);
    stats.spectators++;
  }
  return {
    root,stats,
    inspect:()=>({
      ...stats,
      floorWidth:C.floorHalfWidth*2,floorLength:C.floorHalfLength*2,
      lineWidth:C.playHalfWidth*2,lineLength:C.playHalfLength*2,
      scoringGoalWidth:C.goalScoreHalfWidth*2,
      visualGoalWidth:C.goalHalfWidth*2,
      fenceHalfWidth:C.fenceHalfWidth,fenceHalfLength:C.fenceHalfLength
    })
  };
}
