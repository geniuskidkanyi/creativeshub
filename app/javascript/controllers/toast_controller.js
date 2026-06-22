import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.startTimer()
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-y-2")
    this.element.classList.remove("opacity-100", "translate-y-0")
    setTimeout(() => this.element.remove(), 300)
  }

  startTimer() {
    this.timer = setTimeout(() => this.dismiss(), 5000)
  }

  pauseTimer() {
    clearTimeout(this.timer)
  }

  resumeTimer() {
    this.startTimer()
  }
}
