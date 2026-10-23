import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.160.1/build/three.module.js";
import { attachGameplayV03 } from "./gameplay-bridge-v03.js";
import { createAnimatedAthlete } from "./character-rig.js";
import { buildStreetCourt } from "./court-scene.js";

const canvas = document.querySelector("#game");
const menu = document.querySelector("#menu");
const startButton = document.querySelector("#start");
const menuDesc = document.querySelector("#menuDesc");
const scoreAEl = document.querySelector("#scoreA");
const scoreBEl = document.querySelector("#scoreB");
const clockEl = document.querySelector("#clock");
const toastEl = document.querySelector("#toast");

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.55));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.36;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x080e22);
scene.fog = new THREE.FogExp2(0x080e22, 0.013);
const camera = new THREE.PerspectiveCamera(53, innerWidth / innerHeight, 0.1, 160);
camera.position.set(0, 26.5, 36.2);
camera.lookAt(0, 0, 0);
const cyan = 0x44e8f6, coral = 0xff5683, violet = 0x8a74ff;
const BALL_RADIUS = 0.46;

scene.add(new THREE.HemisphereLight(0xaabaff, 0x142c39, 2.2));
const ambient = new THREE.AmbientLight(0xa7a9ef, 0.6);
scene.add(ambient);
function addLight(x, y, z, color, intensity, range) {
  const light = new THREE.PointLight(color, intensity, range, 2);
  light.position.set(x, y, z); scene.add(light); return light;
}
// Four arena floodlights are provided by court-scene.js (no duplicated lights).

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

// The pitch, lights, environmental art and scoring geometry now share one layout.
const courtScene = buildStreetCourt(THREE, scene, {labelTexture});
window.__streetArenaCourtDebug = () => courtScene.inspect();

// All four 3D footballers now have articulated shoulders, elbows, hips, knees,
// ankles, spine and head. Geometry is original and generated in the browser.
const athlete = createAnimatedAthlete(THREE, scene, {kit: cyan, skinColor:0xb9805f, number:7, selected:true, labelTexture});
const ally = createAnimatedAthlete(THREE, scene, {kit:0x62c7e0, skinColor:0x9a6c47, number:11, labelTexture});
const opponent = createAnimatedAthlete(THREE, scene, {kit:coral, skinColor:0xd39e75, number:9, labelTexture});
const opponent2 = createAnimatedAthlete(THREE, scene, {kit:0xee769f, skinColor:0xba835f, number:10, labelTexture});
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
