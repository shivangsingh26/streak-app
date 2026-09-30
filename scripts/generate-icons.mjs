// Rasterises public/icons/icon.svg into the PNG sizes the manifest and iOS need.
// Requires Playwright (`npx playwright` or a global install) with a Chromium build.
// The generated PNGs are committed, so this only needs re-running when the SVG changes.
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
let chromium;
try {
  ({ chromium } = require("playwright"));
} catch {
  ({ chromium } = require(process.env.PLAYWRIGHT_MODULE ?? "/opt/node22/lib/node_modules/playwright"));
}

const dir = fileURLToPath(new URL("../public/icons/", import.meta.url));
const svg = await readFile(`${dir}icon.svg`, "utf8");
const dataUri = `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;

// maskable: full-bleed background, artwork scaled into the 80% safe zone.
const targets = [
  { file: "icon-192.png", size: 192, maskable: false },
  { file: "icon-512.png", size: 512, maskable: false },
  { file: "apple-touch-icon.png", size: 180, maskable: true },
  { file: "icon-maskable-512.png", size: 512, maskable: true },
];

const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {},
);
const page = await browser.newPage();

for (const { file, size, maskable } of targets) {
  await page.setViewportSize({ width: size, height: size });
  const inner = maskable ? Math.round(size * 0.8) : size;
  await page.setContent(`
    <html><body style="margin:0;width:${size}px;height:${size}px;display:grid;place-items:center;
      background:${maskable ? "#09090B" : "transparent"}">
      <img src="${dataUri}" width="${inner}" height="${inner}" />
    </body></html>`);
  await page.waitForLoadState("load");
  const png = await page.screenshot({ omitBackground: !maskable, type: "png" });
  await writeFile(`${dir}${file}`, png);
  console.log(`wrote ${file}`);
}

await browser.close();
