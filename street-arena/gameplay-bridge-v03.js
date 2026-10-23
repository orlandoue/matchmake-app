import { createGameState, stepGame, FIXED_DT, WORLD } from "./simulation-v03.js";

export function attachGameplayV03({THREE,renderer,camera,scene,athletes,sphere,ballShadow,ballRadius}){
  const el=id=>document.getElementById(id);
  const menu=el("menu"),start=el("start"),desc=el("menuDesc"),toast=el("toast");
  const scoreA=el("scoreA"),scoreB=el("scoreB"),clock=el("clock");
  const power=el("powerFill"),possession=el("possession");
  const aimText=el("aimHelp"),modeText=el("actionMode");
  const keys=new Set();
  const valid=new Set(["arrowup","arrowdown","arrowleft","arrowright","a","s","d","w","q","e"]);
  let playing=false,state=createGameState(),accumulator=0,previous=null;
  let lastFrame=performance.now(),toastFor=0;
  const aimGeometry=new THREE.BufferGeometry();
  const positions=new Float32Array(6);
  aimGeometry.setAttribute("position",new THREE.BufferAttribute(positions,3));
  const aimLine=new THREE.Line(aimGeometry,new THREE.LineBasicMaterial({color:0xffe4a0,transparent:true,opacity:.85}));
  aimLine.visible=false;scene.add(aimLine);
  const spot=new THREE.Mesh(new THREE.TorusGeometry(.48,.055,5,24),new THREE.MeshBasicMaterial({color:0xffdfa2}));
  spot.rotation.x=-Math.PI/2;spot.visible=false;scene.add(spot);
  function snapshot(){
    const actors={};
    for(const [id,p] of Object.entries(state.players))actors[id]={x:p.x,z:p.z};
    return {actors,bx:state.ball.x,bz:state.ball.z,by:state.ball.y};
  }
  function flash(message){toast.textContent=message;toast.classList.add("show");toastFor=1.05;}
  function begin(){
    state=createGameState();previous=snapshot();accumulator=0;keys.clear();playing=true;
    menu.classList.add("hidden");flash("¡2 VS 2!");
  }
  function end(){
    playing=false;
    const a=state.score.player,b=state.score.opponent;
    const result=a===b?"¡EMPATE!":a>b?"¡GANASTE!":"¡FIN DEL PARTIDO!";
    desc.textContent=result+" "+a+" - "+b+". 2v2 contra bots locales; el online todavía no está implementado.";
    start.textContent="VOLVER A JUGAR →";menu.classList.remove("hidden");
  }
  start.addEventListener("click",begin);
  document.addEventListener("keydown",e=>{
    const k=e.key.toLowerCase();
    if(valid.has(k)){e.preventDefault();keys.add(k);}
    if(k==="r"&&!playing)begin();
  });
  document.addEventListener("keyup",e=>keys.delete(e.key.toLowerCase()));
  window.addEventListener("blur",()=>keys.clear());
  document.querySelectorAll("[data-key]").forEach(button=>{
    const k=button.dataset.key;
    const release=e=>{e.preventDefault();keys.delete(k);button.classList.remove("pressed");};
    button.addEventListener("pointerdown",e=>{
      e.preventDefault();button.setPointerCapture?.(e.pointerId);keys.add(k);
      button.classList.add("pressed");
    });
    button.addEventListener("pointerup",release);
    button.addEventListener("pointercancel",release);
    button.addEventListener("lostpointercapture",release);
  });
  function controls(){
    return {
      dx:Number(keys.has("arrowright"))-Number(keys.has("arrowleft")),
      dz:Number(keys.has("arrowdown"))-Number(keys.has("arrowup")),
      a:keys.has("a"),s:keys.has("s"),d:keys.has("d"),
      w:keys.has("w"),q:keys.has("q"),e:keys.has("e")
    };
  }
  function dispatchEvents(){
    for(const e of state.events){
      // Animate authored visual poses for all on-ball/off-ball actions.
      const actorVisual=athletes[e.who];
      if(actorVisual?.motion)actorVisual.motion.play(e.type,1);

      if(e.type==="goal")flash(e.who==="player"?"¡GOOOL!":"GOL DEL RIVAL");
      else if(e.type==="shot"&&state.players[e.who]?.team==="cyan")flash("¡DISPARO!");
      else if(e.type==="finesse_shot")flash("¡TIRO CON EFECTO!");
      else if(e.type==="ground_through"||e.type==="lob_through"||e.type==="directed_pass"){
        if(state.players[e.who]?.team==="cyan")flash("¡PASE!");
      }else if(e.type==="slide"&&e.who===state.selected)flash(e.success?"¡BARRIDA!":"BARRIDA FALLIDA");
      else if(e.type==="tackle"&&e.who===state.selected&&e.success)flash("¡RECUPERACIÓN!");
      else if(e.type==="switch")flash("¡CAMBIO DE JUGADOR!");
      else if(e.type==="end")end();
    }
  }
  const mix=(a,b,t)=>a+(b-a)*t;
  function renderFrame(dt){
    const cur=snapshot(),prev=previous||cur,t=Math.min(1,accumulator/FIXED_DT);
    for(const [id,visual] of Object.entries(athletes)){
      const p=state.players[id],old=prev.actors[id]||cur.actors[id];
      visual.group.position.set(mix(old.x,p.x,t),0,mix(old.z,p.z,t));
      visual.group.rotation.y=Math.atan2(-p.faceX,-p.faceZ);
      visual.motion.update(p,dt,{aiming:playing && id===state.selected && state.shot.held, controlled:state.ball.owner===id});
      visual.halo.material.opacity=id===state.selected?.98:(state.ball.owner===id?.84:.39);
      visual.halo.scale.setScalar(id===state.selected?1.12:.83);
    }
    sphere.position.set(mix(prev.bx,cur.bx,t),mix(prev.by,cur.by,t)+.03,mix(prev.bz,cur.bz,t));
    ballShadow.position.set(sphere.position.x,.01,sphere.position.z);
    ballShadow.material.opacity=Math.max(.12,.43-(sphere.position.y-ballRadius)*.05);
    sphere.rotation.x+=state.ball.vz*dt/ballRadius;
    sphere.rotation.z-=state.ball.vx*dt/ballRadius;
    scoreA.textContent=String(state.score.player);scoreB.textContent=String(state.score.opponent);
    const min=Math.floor(state.timeLeft/60),sec=Math.floor(state.timeLeft%60);
    clock.textContent=String(min).padStart(2,"0")+":"+String(sec).padStart(2,"0");
    power.style.width=Math.round(Math.min(1,state.shot.charge/.72)*100)+"%";
    const owner=state.ball.owner,our=owner&&state.players[owner].team==="cyan";
    possession.textContent=our?"EN CONTROL · "+owner.toUpperCase():owner?"DEFENDIENDO":"BALÓN LIBRE";
    modeText.textContent=our?"A: HUECO · S: PASE · D: TIRO · E: GLOBO · Q: REGATE":"A: ROBAR · E: BARRIDA · Q: CAMBIAR · W: CORRER";
    const aiming=state.shot.held&&playing;
    aimText.textContent=aiming?(state.shot.finesse?"TIRO CON EFECTO · ← → APUNTAR":"← → APUNTAR A PORTERÍA"):"MANTÉN D PARA CARGAR Y APUNTAR · Q+D CON EFECTO";
    aimLine.visible=aiming;spot.visible=aiming;
    if(aiming){
      const g=state.players[state.selected],z=state.players[state.selected].team==="cyan"?-WORLD.halfLength:WORLD.halfLength;
      const aimX=state.shot.aimX;
      const v=aimGeometry.attributes.position.array;
      v[0]=sphere.position.x;v[1]=.19;v[2]=sphere.position.z;
      v[3]=aimX;v[4]=.19;v[5]=z;
      aimGeometry.attributes.position.needsUpdate=true;
      spot.position.set(aimX,.20,z);
    }
    if(toastFor>0){toastFor-=dt;if(toastFor<=0)toast.classList.remove("show");}
    const controlled=athletes[state.selected].group.position;
    const narrow=window.innerWidth/window.innerHeight<.78;
    camera.position.lerp(new THREE.Vector3(controlled.x*.18,narrow?32:22,narrow?33:29),Math.min(1,dt*2.3));
    camera.lookAt(new THREE.Vector3(controlled.x*.13,0,narrow?-.4:-.9));
    renderer.render(scene,camera);
  }
  function frame(now){
    requestAnimationFrame(frame);
    const dt=Math.min(Math.max(0,(now-lastFrame)/1000),.12);lastFrame=now;
    if(playing){
      accumulator=Math.min(accumulator+dt,.15);
      const input=controls();
      while(accumulator>=FIXED_DT&&playing){
        previous=snapshot();
        stepGame(state,input);
        accumulator-=FIXED_DT;
        dispatchEvents();
      }
    }
    renderFrame(dt);
  }
  window.addEventListener("resize",()=>{
    camera.aspect=innerWidth/innerHeight;
    camera.fov=innerWidth/innerHeight<.78?54:49;
    camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,1.8));
  });
  // Read-only diagnostics for cloud browser animation regression testing.
  window.__streetArenaMotionDebug=()=>Object.fromEntries(
    Object.entries(athletes).map(([id,visual])=>[id,visual.motion.debug()])
  );
  requestAnimationFrame(frame);
}
