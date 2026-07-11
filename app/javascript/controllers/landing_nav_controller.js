import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "mobileMenu"]

  connect() {
    this.handleScroll = () => {
      if (window.scrollY > 40) {
        // Theme-aware: --nav-bg/--nav-border flip with data-theme, so the
        // scrolled bar stays light in light mode and dark in dark mode.
        this.navTarget.style.background = "var(--nav-bg)"
        this.navTarget.style.backdropFilter = "blur(16px)"
        this.navTarget.style.borderBottom = "1px solid var(--nav-border)"
      } else {
        this.navTarget.style.background = "transparent"
        this.navTarget.style.backdropFilter = "none"
        this.navTarget.style.borderBottom = "none"
      }
    }
    window.addEventListener("scroll", this.handleScroll)
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  toggleMobile() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }

  closeMobile() {
    this.mobileMenuTarget.classList.add("hidden")
  }
}
