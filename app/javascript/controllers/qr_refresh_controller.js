import { Controller } from "@hotwired/stimulus"

// Keeps the merchant's payment QR fresh: counts down the current code's
// lifetime and swaps in the next code from the server when it expires.
export default class extends Controller {
  static targets = ["svg", "countdown"]
  static values = { url: String, secondsRemaining: Number }

  connect() {
    this.remaining = this.secondsRemainingValue
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    this.remaining -= 1
    if (this.remaining <= 0) {
      this.refresh()
    } else {
      this.renderCountdown()
    }
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error("refresh failed")
      const data = await response.json()
      this.svgTarget.innerHTML = data.svg
      this.remaining = data.seconds_remaining
      this.renderCountdown()
    } catch (e) {
      // Try again shortly rather than leaving a stale code on screen.
      this.remaining = 5
    }
  }

  renderCountdown() {
    if (!this.hasCountdownTarget) return
    this.countdownTarget.textContent = `${this.remaining}s`
    this.countdownTarget.classList.toggle("text-red-500", this.remaining <= 10)
  }
}
