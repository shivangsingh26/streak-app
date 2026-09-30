/* DSA Daily Matrix — offline service worker.
 *
 * - Precaches the app shell on install.
 * - Navigations: network-first (fresh deploys win), falling back to the cached shell offline.
 * - Same-origin static assets: stale-while-revalidate. Vite's hashed filenames make
 *   these effectively immutable, so the cache is always correct.
 */
const VERSION = "v1";
const CACHE = `dsa-matrix-${VERSION}`;
const SHELL = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icons/icon.svg",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/apple-touch-icon.png",
];

// Vite emits content-hashed bundles, so discover them from the built index.html
// instead of hard-coding names. Guarantees the first offline launch has JS + CSS.
async function precache() {
  const cache = await caches.open(CACHE);
  await cache.addAll(SHELL);
  const html = await (await cache.match("./index.html")).text();
  const assets = [...html.matchAll(/(?:src|href)="(\.\/assets\/[^"]+)"/g)].map((m) => m[1]);
  await cache.addAll([...new Set(assets)]);
}

self.addEventListener("install", (event) => {
  event.waitUntil(precache().then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith("dsa-matrix-") && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone();
            event.waitUntil(caches.open(CACHE).then((cache) => cache.put("./index.html", copy)));
          }
          return response;
        })
        .catch(async () => (await caches.match("./index.html")) || (await caches.match("./")) || Response.error()),
    );
    return;
  }

  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const cached = await cache.match(request);
      const network = fetch(request)
        .then((response) => {
          if (response.ok) cache.put(request, response.clone());
          return response;
        })
        .catch(() => cached || Response.error());
      if (cached) {
        event.waitUntil(network);
        return cached;
      }
      return network;
    }),
  );
});
