const CACHE = "smartpay-v2"

// Small static shell only. Pages are always fetched from the network so
// logged-in users never see a stale cached page; "/" doubles as the offline
// fallback for navigations.
const ASSETS = [
  "/",
  "/manifest.json",
  "/icon-192.png",
  "/icon-512.png",
  "/icon-maskable-512.png"
]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS)).then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET") return

  // Navigations: network first — the app is dynamic and per-user. Fall back
  // to the cached shell only when truly offline.
  if (request.mode === "navigate") {
    event.respondWith(fetch(request).catch(() => caches.match("/")))
    return
  }

  // Static assets: cache first, then network, caching same-origin responses
  // for next time (icons, compiled css/js under /assets).
  const url = new URL(request.url)
  const cacheable = url.origin === self.location.origin &&
    (ASSETS.includes(url.pathname) || url.pathname.startsWith("/assets/"))
  if (!cacheable) return

  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached
      return fetch(request).then((response) => {
        if (response.ok) {
          const copy = response.clone()
          caches.open(CACHE).then((cache) => cache.put(request, copy))
        }
        return response
      })
    })
  )
})
