const CACHE = "smartpay-v1"

const ASSETS = [
  "/",
  "/manifest.json",
  "/icon.png",
  "/icon.svg"
]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS))
  )
})

self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => response || fetch(event.request))
  )
})
