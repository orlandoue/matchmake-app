import { chromium } from "playwright";
import assert from "node:assert/strict";

const errors = [];
const browser = await chromium.launch({
  headless: true,
  args: ["--no-sandbox", "--enable-webgl", "--use-gl=angle", "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader"]
});
try {
  const page = await browser.newPage({ viewport:{width:1440,height:900} });
  page.on("pageerror", error => errors.push(error.message));
  const response = await page.goto("http://127.0.0.1:4173/", { waitUntil:"domcontentloaded", timeout:30000 });
  assert.equal(response?.status(),200,"static HTML must be served");
  const court = await page.evaluate(() => window.__streetArenaCourtDebug?.());
  assert.ok(court, "enlarged court scene must be installed");
  assert.equal(court.floorWidth, 24);
  assert.equal(court.floorLength, 38);
  assert.equal(court.lineWidth, 22.7);
  assert.equal(court.lineLength, 36.4);
  assert.ok(court.props >= 20, "sideline props and original billboards must render");
  assert.ok(court.fencing >= 40, "perimeter fencing must follow new extent");
  assert.ok(court.buildings >= 80, "urban background buildings must render");
  assert.ok(court.spectators >= 60, "spectators must remain outside playfield");
  await page.locator("#start").click();
  await page.waitForTimeout(1500);
  assert.ok(await page.locator("#menu").evaluate(node=>node.classList.contains("hidden")),"menu must close");
  assert.equal(await page.locator("#scoreA").textContent(),"0");
  assert.match(await page.locator("#actionMode").textContent(),/ROBAR|PASE/);
  // Force a visible display loop and attempt the new shot input. The engine owns the state.
  // Check the actual visual skeleton, not just the simulation state.
  const diagnostic = await page.evaluate(() => window.__streetArenaMotionDebug?.());
  assert.ok(diagnostic && Object.keys(diagnostic).length === 4, "four articulated athletes must exist");
  const samples = [];
  await page.keyboard.down("ArrowUp");
  for (let i=0;i<26;i++) {
    await page.waitForTimeout(95);
    samples.push(await page.evaluate(() => window.__streetArenaMotionDebug().player));
  }
  await page.keyboard.up("ArrowUp");
  const maxSwing = Math.max(...samples.map(p=>Math.abs(p.leftHipX-p.rightHipX)));
  const maxArms = Math.max(...samples.map(p=>Math.abs(p.leftShoulderX-p.rightShoulderX)));
  assert.ok(maxSwing>.12,"legs must visibly alternate while moving; observed "+maxSwing);
  assert.ok(maxArms>.10,"arms must swing opposite while moving; observed "+maxArms);
  assert.ok(samples.some(p=>p.speed>.5),"player should have nonzero motion speed");
  await page.screenshot({path:"street-arena/animated-players-smoke.png"});

  await page.keyboard.down("KeyD");
  await page.keyboard.down("ArrowRight");
  await page.waitForTimeout(300);
  await page.keyboard.up("ArrowRight");
  await page.keyboard.up("KeyD");
  await page.waitForTimeout(150);
  assert.deepEqual(errors,[],"game page must not throw uncaught JavaScript errors");
  console.log("PASS: 2v2 browser loaded, game started, ArrowUp and D aiming attempted without page errors");
} finally {
  await browser.close();
}
