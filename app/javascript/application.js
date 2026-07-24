// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// `html { scroll-behavior: smooth }` breaks Turbo's scroll reset: the jump to
// the top (or to a #anchor) after a cross-page visit becomes an animated
// scroll that often never lands. Force an instant scroll on forward
// cross-page visits only, so back/forward restoration and same-page #anchor
// scrolling keep their native (smooth) behavior.
let turboVisitAction = null
let turboPathBeforeVisit = null
document.addEventListener("turbo:before-visit", () => {
  turboPathBeforeVisit = window.location.pathname
})
document.addEventListener("turbo:visit", (event) => {
  turboVisitAction = event.detail.action
})
document.addEventListener("turbo:load", () => {
  if (turboVisitAction === "advance") {
    const crossPage = window.location.pathname !== turboPathBeforeVisit
    const anchor = window.location.hash && document.getElementById(window.location.hash.slice(1))
    if (anchor) {
      // Cross-page: jump straight to the section. Same-page (landing nav):
      // restart the smooth scroll that Turbo's re-render cancelled.
      anchor.scrollIntoView({ behavior: crossPage ? "instant" : "smooth", block: "start" })
    } else if (crossPage) {
      window.scrollTo({ top: 0, behavior: "instant" })
    }
  }
  turboVisitAction = null
  turboPathBeforeVisit = window.location.pathname
})

// PWA: without a registered service worker, browsers won't offer "install app".
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").catch((error) => {
      console.warn("Service worker registration failed:", error)
    })
  })
}
