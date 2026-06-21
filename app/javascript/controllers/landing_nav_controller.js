import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "mobileMenu"]

  connect() {
    this.handleScroll = () => {
      if (window.scrollY > 40) {
        this.navTarget.style.background = "rgba(6,8,12,0.92)"
        this.navTarget.style.backdropFilter = "blur(16px)"
        this.navTarget.style.borderBottom = "1px solid rgba(255,255,255,0.06)"
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
