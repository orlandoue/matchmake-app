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
  await page.locator("#start").click();
  await page.waitForTimeout(1500);
  assert.ok(await page.locator("#menu").evaluate(node=>node.classList.contains("hidden")),"menu must close");
  assert.equal(await page.locator("#scoreA").textContent(),"0");
  assert.match(await page.locator("#actionMode").textContent(),/ROBAR|PASE/);
  // Force a visible display loop and attempt the new shot input. The engine owns the state.
  await page.keyboard.down("ArrowUp");
  await page.waitForTimeout(300);
  await page.keyboard.up("ArrowUp");
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
