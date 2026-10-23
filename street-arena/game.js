import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.160.1/build/three.module.js";
import { attachGameplayV03 } from "./gameplay-bridge-v03.js";

const canvas = document.querySelector("#game");
const menu = document.querySelector("#menu");
const startButton = document.querySelector("#start");
const menuDesc = document.querySelector("#menuDesc");
const scoreAEl = document.querySelector("#scoreA");
const scoreBEl = document.querySelector("#scoreB");
const clockEl = document.querySelector("#clock");
const toastEl = document.querySelector("#toast");

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.8));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.36;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x080e22);
scene.fog = new THREE.FogExp2(0x080e22, 0.013);
const camera = new THREE.PerspectiveCamera(49, innerWidth / innerHeight, 0.1, 145);
camera.position.set(0, 21, 30);
camera.lookAt(0, 0, 0);
const cyan = 0x44e8f6, coral = 0xff5683, violet = 0x8a74ff;
const HALF_W = 10, HALF_L = 16, GOAL_W = 3.25, BALL_RADIUS = 0.46;

scene.add(new THREE.HemisphereLight(0xaabaff, 0x142c39, 2.2));
const ambient = new THREE.AmbientLight(0xa7a9ef, 0.6);
scene.add(ambient);
function addLight(x, y, z, color, intensity, range) {
  const light = new THREE.PointLight(color, intensity, range, 2);
  light.position.set(x, y, z); scene.add(light); return light;
}
addLight(-11, 12, -12, cyan, 115, 45);
addLight(11, 11, 12, coral, 100, 45);
addLight(-12, 12, 13, violet, 80, 32);
addLight(12, 13, -13, 0xd4f6ff, 75, 32);

function material(color, roughness = .76, metalness = .06, emissive = 0x000000, intensity = 0) {
  return new THREE.MeshStandardMaterial({ color, roughness, metalness, emissive, emissiveIntensity: intensity });
}
function box(w, h, d, mat, x, y, z, parent = scene) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
  mesh.position.set(x, y, z); parent.add(mesh); return mesh;
}
function tube(a, b, radius, mat, parent = scene, radial = 7) {
  const dir = new THREE.Vector3().subVectors(b, a);
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, dir.length(), radial), mat);
  mesh.position.copy(a).addScaledVector(dir, .5);
  mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir.normalize());
  parent.add(mesh); return mesh;
}
function segment(x1, z1, x2, z2, thickness, mat, y = .035) {
  return box(Math.hypot(x2 - x1, z2 - z1), .035, thickness, mat, (x1 + x2) / 2, y, (z1 + z2) / 2).rotateY(-Math.atan2(z2 - z1, x2 - x1));
}
function labelTexture(text, color = "#edfbff", accent = "#59eeff") {
  const cvs = document.createElement("canvas"); cvs.width = 1024; cvs.height = 256;
  const c = cvs.getContext("2d");
  c.clearRect(0, 0, 1024, 256);
  c.fillStyle = "rgba(8, 13, 32, .88)"; c.fillRect(0, 0, 1024, 256);
  c.strokeStyle = accent; c.lineWidth = 10; c.strokeRect(12, 12, 1000, 232);
  c.fillStyle = color; c.textAlign = "center"; c.textBaseline = "middle";
  c.font = "900 113px Arial, sans-serif"; c.fillText(text, 512, 134);
  const map = new THREE.CanvasTexture(cvs); map.colorSpace = THREE.SRGBColorSpace; return map;
}

// Night-time urban court and skyline: all geometry authored specifically for MatchMake.
const floorMat = material(0x102c37, .96);
const outsideMat = material(0x0c1426);
box(85, .4, 105, outsideMat, 0, -.29, 0);
const asphalt = box(21.5, .08, 33.5, floorMat, 0, -.09, 0);
asphalt.material = material(0x16303c, .92);
for (let i = -9; i <= 9; i += 3) {
  box(3, .011, 32, material(i % 2 ? 0x14333e : 0x193944, .98), i, -.036, 0);
}
const lines = new THREE.MeshBasicMaterial({ color: 0xc4f8ff });
for (const sx of [-HALF_W, HALF_W]) box(.09, .04, HALF_L * 2, lines, sx, .04, 0);
for (const sz of [-HALF_L, HALF_L]) box(HALF_W * 2, .04, .09, lines, 0, .04, sz);
box(HALF_W * 2, .04, .075, lines, 0, .04, 0);
const ring = new THREE.Mesh(new THREE.RingGeometry(3.0, 3.08, 72), new THREE.MeshBasicMaterial({ color: 0xd8faff, side: THREE.DoubleSide }));
ring.rotation.x = -Math.PI / 2; ring.position.y = .05; scene.add(ring);
for (const z of [-12.7, 12.7]) {
  box(10, .04, .09, lines, 0, .046, z);
  box(.08, .04, 3.3, lines, -5, .046, z < 0 ? -14.35 : 14.35);
  box(.08, .04, 3.3, lines, 5, .046, z < 0 ? -14.35 : 14.35);
}
const dash = new THREE.MeshBasicMaterial({ color: 0x35dfec });
const neonPink = new THREE.MeshBasicMaterial({ color: 0xff6e9e });
for (const x of [-10.45, 10.45]) box(.11, .08, 32.8, x < 0 ? dash : neonPink, x, .1, 0);
for (const z of [-16.45, 16.45]) box(20.9, .08, .11, z < 0 ? dash : neonPink, 0, .1, z);

const poleMat = material(0x60768b, .42, .8);
const netMat = new THREE.MeshBasicMaterial({ color: 0x9fc5e9, transparent: true, opacity: .21, depthWrite: false });
for (const x of [-11.0, 11.0]) {
  for (let z = -16.5; z <= 16.6; z += 2.6) tube(new THREE.Vector3(x, 0, z), new THREE.Vector3(x, 4.5, z), .043, poleMat);
  for (let y = .85; y < 4.6; y += .8) tube(new THREE.Vector3(x, y, -16.5), new THREE.Vector3(x, y, 16.5), .014, netMat);
  tube(new THREE.Vector3(x, 4.55, -16.5), new THREE.Vector3(x, 4.55, 16.5), .065, poleMat);
}
for (const z of [-16.5, 16.5]) {
  for (let x = -11; x < 11; x += 2.8) tube(new THREE.Vector3(x, 0, z), new THREE.Vector3(x, 4.5, z), .04, poleMat);
  for (let y = .8; y < 4.5; y += .8) tube(new THREE.Vector3(-11, y, z), new THREE.Vector3(11, y, z), .014, netMat);
}
function createGoal(z, sign) {
  const post = new THREE.MeshStandardMaterial({ color: 0xe8faff, emissive: 0x247a9b, emissiveIntensity: .34, metalness: .42 });
  tube(new THREE.Vector3(-GOAL_W, .05, z), new THREE.Vector3(-GOAL_W, 2.6, z), .11, post);
  tube(new THREE.Vector3(GOAL_W, .05, z), new THREE.Vector3(GOAL_W, 2.6, z), .11, post);
  tube(new THREE.Vector3(-GOAL_W, 2.6, z), new THREE.Vector3(GOAL_W, 2.6, z), .11, post);
  const back = z + 1.7 * sign;
  for (let x = -GOAL_W; x <= GOAL_W; x += .65) {
    tube(new THREE.Vector3(x, .1, back), new THREE.Vector3(x, 2.6, z), .009, netMat);
  }
  for (let y = .15; y <= 2.6; y += .48) tube(new THREE.Vector3(-GOAL_W, y, back), new THREE.Vector3(GOAL_W, y, back), .009, netMat);
}
createGoal(-16, -1); createGoal(16, 1);
for (const [x, z, color] of [[-13, -18, cyan], [13, -18, violet], [-13, 18, violet], [13, 18, coral]]) {
  tube(new THREE.Vector3(x, 0, z), new THREE.Vector3(x, 10.5, z), .15, poleMat);
  const lamp = box(1.55, .25, .85, material(0xecfaff, .12, .3, color, .75), x, 10.7, z);
  lamp.rotation.y = x < 0 ? -.25 : .25;
}
const billboard = new THREE.Mesh(new THREE.PlaneGeometry(12, 3), new THREE.MeshBasicMaterial({ map: labelTexture("MATCHMAKE"), side: THREE.DoubleSide }));
billboard.position.set(0, 5.1, -18.9); scene.add(billboard);
const slogan = new THREE.Mesh(new THREE.PlaneGeometry(10, 2.5), new THREE.MeshBasicMaterial({ map: labelTexture("STREET ARENA", "#ffffff", "#ff527b"), side: THREE.DoubleSide }));
slogan.position.set(0, 5.2, 19.4); slogan.rotation.y = Math.PI; scene.add(slogan);
// Procedural city: compact geometry instead of downloaded assets.
let seed = 221;
function rand() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }
for (let i = 0; i < 100; i++) {
  const side = i % 4, x = side < 2 ? (side === 0 ? -1 : 1) * (19 + rand() * 35) : (rand() - .5) * 105;
  const z = side >= 2 ? (side === 2 ? -1 : 1) * (25 + rand() * 25) : (rand() - .5) * 96;
  const w = 2.6 + rand() * 6, d = 2.5 + rand() * 6, h = 4 + rand() * 24;
  const building = box(w, h, d, material(new THREE.Color().setHSL(.61 + rand() * .06, .23, .08 + rand() * .09)), x, h / 2 - .14, z);
  if (i % 3 === 0) box(w * .8, .08, .04, new THREE.MeshBasicMaterial({ color: rand() > .5 ? cyan : coral }), x, h * .72, z + d / 2 + .035);
}
for (let i = 0; i < 55; i++) {
  const side = i % 2 ? -1 : 1, z = (rand() - .5) * 38, x = side * (12.2 + rand() * 3.5);
  const light = new THREE.Mesh(new THREE.SphereGeometry(.1 + rand() * .1, 8, 6), new THREE.MeshBasicMaterial({ color: rand() > .4 ? cyan : coral }));
  light.position.set(x, .4 + rand() * 2.5, z); scene.add(light);
}
const crowdMat = [material(0x475b80), material(0x28446f), material(0x664b70)];
for (let i = 0; i < 120; i++) {
  const x = (i % 2 ? -1 : 1) * (12 + rand() * 2.5), z = (rand() - .5) * 37;
  const mesh = new THREE.Mesh(new THREE.CapsuleGeometry(.18, .42, 3, 6), crowdMat[i % 3]);
  mesh.position.set(x, .53, z); scene.add(mesh);
}

// Original low-poly athletes and selection rings.
function createAthlete(color, skinColor, accent, number, isPlayer) {
  const group = new THREE.Group(); scene.add(group);
  const body = material(color, .53, .14);
  const dark = material(0x10192b);
  const skin = material(skinColor, .95);
  const head = new THREE.Mesh(new THREE.SphereGeometry(.37, 14, 10), skin);
  head.position.y = 2.35; group.add(head);
  const hair = new THREE.Mesh(new THREE.SphereGeometry(.385, 14, 8, 0, Math.PI * 2, 0, Math.PI * .40), material(0x14121d));
  hair.position.y = 2.42; group.add(hair);
  const torso = new THREE.Mesh(new THREE.CylinderGeometry(.43, .57, 1.06, 8), body);
  torso.position.y = 1.47; group.add(torso);
  const stripe = box(.5, .065, .1, material(accent, .45), 0, 1.63, -.48, group);
  for (const side of [-1, 1]) {
    tube(new THREE.Vector3(side * .65, 1.82, 0), new THREE.Vector3(side * .75, 1.02, -.06), .17, skin, group);
    tube(new THREE.Vector3(side * .26, .96, 0), new THREE.Vector3(side * .27, .36, .04), .18, dark, group);
    box(.38, .17, .64, material(0xecf5fa), side * .27, .13, -.12, group);
  }
  const halo = new THREE.Mesh(new THREE.TorusGeometry(.85, .045, 6, 32), new THREE.MeshBasicMaterial({ color: accent, transparent: true, opacity: isPlayer ? .85 : .55 }));
  halo.rotation.x = -Math.PI / 2; halo.position.y = .045; group.add(halo);
  const numberTex = labelTexture(String(number), "#ffffff", isPlayer ? "#59eeff" : "#ff527b");
  const numberPlate = new THREE.Mesh(new THREE.PlaneGeometry(.5, .3), new THREE.MeshBasicMaterial({ map: numberTex, transparent: true, depthWrite: false, side: THREE.DoubleSide }));
  numberPlate.position.set(0, 1.51, .552); group.add(numberPlate);
  return { group, halo, facing: new THREE.Vector2(0, isPlayer ? -1 : 1), x: 0, z: 0 };
}
const athlete = createAthlete(cyan, 0xb9805f, 0xffffff, 7, true);
const ally = createAthlete(0x62c7e0, 0x9a6c47, 0xffffff, 11, false);
const opponent = createAthlete(coral, 0xd39e75, 0xffffff, 9, false);
const opponent2 = createAthlete(0xee769f, 0xba835f, 0xffffff, 10, false);
const sphere = new THREE.Group(); scene.add(sphere);
const ballShell = new THREE.Mesh(new THREE.SphereGeometry(BALL_RADIUS, 24, 16), material(0xf5f6fd, .45, .06));
sphere.add(ballShell);
const patchGeo = new THREE.CircleGeometry(.15, 5);
const patchMat = material(0x20263b, .72);
for (const [px, py, pz] of [[0,1,0],[1,0,0],[-1,0,0],[0,0,1],[0,0,-1],[0,-1,0]]) {
  const patch = new THREE.Mesh(patchGeo, patchMat);
  const normal = new THREE.Vector3(px, py, pz);
  patch.position.copy(normal).multiplyScalar(BALL_RADIUS + .007);
  patch.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1), normal);
  sphere.add(patch);
}
const ballShadow = new THREE.Mesh(new THREE.CircleGeometry(.65, 25), new THREE.MeshBasicMaterial({ color: 0x010509, transparent: true, opacity: .43, depthWrite:false }));
ballShadow.rotation.x = -Math.PI/2; ballShadow.position.y = .013; scene.add(ballShadow);

attachGameplayV03({ THREE, renderer, camera, scene,
  athletes: { player: athlete, ally, opponent, opponent2 },
  sphere, ballShadow, ballRadius: BALL_RADIUS
});
