import { createGameState, stepGame, FIXED_DT } from "./simulation.js";

export function attachGameplay({ renderer, camera, scene, athlete, opponent, sphere, ballShadow, ballRadius }) {
  const select = id => document.getElementById(id);
  const menu = select("menu"), start = select("start"), desc = select("menuDesc");
  const toast = select("toast");
  const scoreA = select("scoreA"), scoreB = select("scoreB"), clock = select("clock");
  const power = select("powerFill"), possession = select("possession");
  const keys = new Set();
  const valid = new Set(["arrowup","arrowdown","arrowleft","arrowright","a","s","d","w","q","e"]);
  let playing = false, state = createGameState(), accumulator = 0, previous = null;
  let lastFrame = performance.now(), toastFor = 0;

  function samplePose() {
    return { px: state.player.x, pz: state.player.z, ox: state.opponent.x, oz: state.opponent.z,
      bx: state.ball.x, bz: state.ball.z };
  }
  function flash(message) {
    toast.textContent = message; toast.classList.add("show"); toastFor = 1.1;
  }
  function begin() {
    state = createGameState();
    previous = samplePose();
    accumulator = 0;
    keys.clear();
    playing = true;
    menu.classList.add("hidden");
    flash("¡A JUGAR!");
  }
  function end() {
    playing = false;
    const { player, opponent } = state.score;
    desc.textContent = (player === opponent ? "¡EMPATE!" : player > opponent ? "¡GANASTE!" : "¡FIN DEL PARTIDO!") +
      " " + player + " - " + opponent + ". Alpha de jugabilidad local; el 2v2 online está pendiente.";
    start.textContent = "VOLVER A JUGAR →";
    menu.classList.remove("hidden");
  }
  start.addEventListener("click", begin);
  document.addEventListener("keydown", e => {
    const key = e.key.toLowerCase();
    if (valid.has(key)) { e.preventDefault(); keys.add(key); }
    if (key === "r" && !playing) begin();
  });
  document.addEventListener("keyup", e => keys.delete(e.key.toLowerCase()));
  window.addEventListener("blur", () => keys.clear());
  document.querySelectorAll("[data-key]").forEach(button => {
    const key = button.dataset.key;
    const release = e => { e.preventDefault(); keys.delete(key); button.classList.remove("pressed"); };
    button.addEventListener("pointerdown", e => {
      e.preventDefault(); button.setPointerCapture?.(e.pointerId);
      keys.add(key); button.classList.add("pressed");
    });
    button.addEventListener("pointerup", release);
    button.addEventListener("pointercancel", release);
    button.addEventListener("lostpointercapture", release);
  });
  function controls() {
    return {
      dx: Number(keys.has("arrowright")) - Number(keys.has("arrowleft")),
      dz: Number(keys.has("arrowdown")) - Number(keys.has("arrowup")),
      a: keys.has("a"), s: keys.has("s"), d: keys.has("d"),
      w: keys.has("w"), q: keys.has("q"), e: keys.has("e")
    };
  }
  function events() {
    for (const evt of state.events) {
      if (evt.type === "goal") flash(evt.who === "player" ? "¡GOOOL!" : "GOL DEL RIVAL");
      else if (evt.type === "shot" && evt.who === "player") flash("¡DISPARO!");
      else if (evt.type === "receive" && evt.who === "player" && evt.assisted) flash("¡CONTROL!");
      else if (evt.type === "feint") flash("¡REGATE!");
      else if (evt.type === "pass" || evt.type === "through_pass") flash("¡PASE!");
      else if (evt.type === "slide" && evt.success) flash("¡BARRIDA!");
      else if (evt.type === "end") end();
    }
  }
  function renderFrame(dt) {
    const cur = samplePose(), old = previous || cur;
    const t = Math.min(1, accumulator / FIXED_DT);
    const lerp = (a,b) => a + (b-a)*t;
    athlete.group.position.set(lerp(old.px,cur.px), 0, lerp(old.pz,cur.pz));
    opponent.group.position.set(lerp(old.ox,cur.ox), 0, lerp(old.oz,cur.oz));
    athlete.group.rotation.y = Math.atan2(-state.player.faceX,-state.player.faceZ);
    opponent.group.rotation.y = Math.atan2(-state.opponent.faceX,-state.opponent.faceZ);
    athlete.group.rotation.z = state.player.slideTicks > 0 ? -.47 : 0;
    athlete.halo.material.opacity = state.ball.owner === "player" ? .97 : .62;
    sphere.position.set(lerp(old.bx,cur.bx), ballRadius+.03, lerp(old.bz,cur.bz));
    ballShadow.position.set(sphere.position.x, .01, sphere.position.z);
    sphere.rotation.x += state.ball.vz * dt / ballRadius;
    sphere.rotation.z -= state.ball.vx * dt / ballRadius;
    scoreA.textContent = String(state.score.player);
    scoreB.textContent = String(state.score.opponent);
    const minutes = Math.floor(state.timeLeft/60), seconds = Math.floor(state.timeLeft%60);
    clock.textContent = String(minutes).padStart(2,"0")+":"+String(seconds).padStart(2,"0");
    power.style.width = Math.round(100*Math.min(1,state.shoot.charge/.68))+"%";
    possession.textContent = state.ball.owner === "player" ? "EN CONTROL" :
      state.ball.owner === "opponent" ? "DEFENDER" : "BALÓN LIBRE";
    if (toastFor > 0) { toastFor -= dt; if (toastFor <= 0) toast.classList.remove("show"); }
    const narrow = window.innerWidth/window.innerHeight < .78;
    const desired = new THREE.Vector3(athlete.group.position.x*.18, narrow?32:22, narrow?33:29);
    camera.position.lerp(desired, Math.min(1,dt*2.3));
    camera.lookAt(new THREE.Vector3(athlete.group.position.x*.13,0,narrow?-.4:-.9));
    renderer.render(scene,camera);
  }
  // Import Three.js via the same pinned CDN used by the renderer.
  const THREE = { Vector3: camera.position.constructor };
  function frame(time) {
    requestAnimationFrame(frame);
    const dt = Math.min(Math.max(0,(time-lastFrame)/1000),.12);
    lastFrame = time;
    if (playing) {
      accumulator = Math.min(accumulator+dt,.15);
      const input = controls();
      while (accumulator >= FIXED_DT && playing) {
        previous = samplePose();
        stepGame(state,input);
        accumulator -= FIXED_DT;
        events();
      }
    }
    renderFrame(dt);
  }
  window.addEventListener("resize", () => {
    camera.aspect = innerWidth/innerHeight;
    camera.fov = innerWidth/innerHeight < .78 ? 54 : 49;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth,innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,1.8));
  });
  requestAnimationFrame(frame);
}
