import {createMotionState,advanceMotion,playMotion} from "./character-motion.js";

// Original articulated low-poly footballers. All primitives constructed at runtime:
// shoulders/elbows, hips/knees/ankles, and a separate upper-body pivot.
export function createAnimatedAthlete(THREE, scene, {kit, skinColor, number, selected=false, labelTexture}) {
  const group=new THREE.Group(); group.name="Athlete "+number;scene.add(group);
  const mat=(color,rough=.74,metal=.05)=>new THREE.MeshStandardMaterial({color,roughness:rough,metalness:metal});
  const kitMat=mat(kit,.54,.13), trousers=mat(0x11223b), skin=mat(skinColor,.89),
    socks=mat(0xe8eef4), boots=mat(0xecf6fd,.48,.08), hairMat=mat(0x181521), trim=mat(0xefffff,.4,.2);
  const sphereGeo=(r,w=12,h=8)=>new THREE.SphereGeometry(r,w,h);
  const mesh=(parent,geometry,material,x=0,y=0,z=0)=>{
    const o=new THREE.Mesh(geometry,material);o.position.set(x,y,z);parent.add(o);return o;
  };
  const joint=(parent,x,y,z,name)=>{
    const pivot=new THREE.Group();pivot.name=name;pivot.position.set(x,y,z);parent.add(pivot);return pivot;
  };
  const cylinder=(parent,len,rTop,rBottom,material)=>{
    const m=mesh(parent,new THREE.CylinderGeometry(rTop,rBottom,len,9),material,0,-len/2,0);
    return m;
  };
  const body=joint(group,0,1.12,0,"torsoPivot");
  const pelvis=mesh(group,new THREE.CylinderGeometry(.41,.43,.35,9),trousers,0,1.08,0);
  // Jersey, sleeves, chest stripe and collar.
  mesh(body,new THREE.CylinderGeometry(.49,.38,.88,10),kitMat,0,.42,0);
  mesh(body,new THREE.BoxGeometry(.48,.075,.09),trim,0,.60,-.43);
  mesh(body,new THREE.CylinderGeometry(.195,.20,.12,10),skin,0,.94,0);
  const head=joint(body,0,1.08,-.005,"neckHead");
  mesh(head,sphereGeo(.36,14,11),skin,0,.12,0);
  mesh(head,new THREE.SphereGeometry(.37,14,8,0,Math.PI*2,0,Math.PI*.43),hairMat,0,.20,0);
  // Face's forward direction is -Z (matching movement animation).
  for(const side of [-1,1]){
    mesh(head,sphereGeo(.043,8,6),hairMat,side*.135,.16,-.321);
  }
  const joints={body,head,hips:{},knees:{},ankles:{},shoulders:{},elbows:{}};
  const arms=[], legs=[];
  for(const side of [-1,1]){
    const key=side<0?"left":"right";
    const shoulder=joint(body,side*.57,.73,0,key+"Shoulder");
    joints.shoulders[key]=shoulder;
    mesh(shoulder,new THREE.SphereGeometry(.245,12,8),kitMat,0,-.045,0);
    cylinder(shoulder,.41,.19,.155,kitMat);
    const elbow=joint(shoulder,0,-.42,0,key+"Elbow");
    joints.elbows[key]=elbow;
    mesh(elbow,sphereGeo(.158),skin);
    cylinder(elbow,.40,.13,.112,skin);
    mesh(elbow,sphereGeo(.135),skin,0,-.43,0);
    arms.push(shoulder);
    const hip=joint(group,side*.27,1.02,0,key+"Hip");
    joints.hips[key]=hip;
    cylinder(hip,.45,.20,.18,trousers);
    const knee=joint(hip,0,-.47,0,key+"Knee");
    joints.knees[key]=knee;
    mesh(knee,sphereGeo(.175),socks,0,.0,0);
    cylinder(knee,.45,.158,.127,socks);
    const ankle=joint(knee,0,-.47,0,key+"Ankle");
    joints.ankles[key]=ankle;
    mesh(ankle,new THREE.BoxGeometry(.42,.16,.67),boots,0,-.02,-.17);
    mesh(ankle,new THREE.BoxGeometry(.38,.038,.53),trousers,0,-.115,-.17);
    legs.push(hip);
  }
  // Number is attached to the upper body and moves with breathing/lean.
  const numberPlate=mesh(body,new THREE.PlaneGeometry(.50,.32),
    new THREE.MeshBasicMaterial({map:labelTexture(String(number),"#ffffff",selected?"#59eeff":"#ff527b"),side:THREE.DoubleSide,transparent:true,depthWrite:false}),0,.43,.443);
  numberPlate.name="kitNumber";
  // Hoops stay on the floor, even while the athlete jumps, kicks or slides.
  const halo=mesh(group,new THREE.TorusGeometry(.81,.045,6,30),
    new THREE.MeshBasicMaterial({color:kit,transparent:true,opacity:selected?.86:.51}),0,.045,0);
  halo.rotation.x=-Math.PI/2;
  const state=createMotionState();
  let lastPose=advanceMotion(state,{vx:0,vz:0,slideTicks:0,feintTicks:0},0);
  function apply(p) {
    joints.body.position.y=1.12+p.rootY;
    joints.body.rotation.set(p.torsoX,p.torsoY,p.torsoZ);
    joints.head.rotation.set(p.headX,0,-p.torsoZ*.25);
    for(const key of ["left","right"]){
      joints.hips[key].rotation.x=p[key+"HipX"];
      joints.knees[key].rotation.x=p[key+"KneeX"];
      joints.ankles[key].rotation.x=p[key+"AnkleX"];
      joints.shoulders[key].rotation.x=p[key+"ShoulderX"];
      joints.shoulders[key].rotation.z=p[key+"ShoulderZ"];
      joints.elbows[key].rotation.x=p[key+"ElbowX"];
    }
    pelvis.position.y=1.08+p.pelvisY;
  }
  apply(lastPose);
  const motion={
    update(player,dt,flags={}){
      lastPose=advanceMotion(state,player,dt,flags);
      apply(lastPose);
    },
    play(type,side){return playMotion(state,type,side);},
    debug(){
      return {
        phase:state.phase,speed:lastPose.speed,stride:lastPose.stride,action:lastPose.action,
        leftHipX:joints.hips.left.rotation.x,rightHipX:joints.hips.right.rotation.x,
        leftKneeX:joints.knees.left.rotation.x,rightKneeX:joints.knees.right.rotation.x,
        leftShoulderX:joints.shoulders.left.rotation.x,rightShoulderX:joints.shoulders.right.rotation.x,
        torsoX:joints.body.rotation.x
      };
    }
  };
  // Optional accessory mount, parented to the racket-hand forearm.
  const racketGrip=new THREE.Group();
  racketGrip.name="right-hand-equipment-grip";
  racketGrip.position.set(0,-.37,-.06);
  joints.elbows.right.add(racketGrip);
  return {group,halo,motion,racketGrip};
}
