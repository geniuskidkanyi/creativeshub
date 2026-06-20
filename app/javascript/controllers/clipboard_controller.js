import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "icon", "label" ]
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)

      const originalIcon = this.iconTarget.innerHTML
      const originalLabel = this.labelTarget.textContent

      this.iconTarget.innerHTML = `<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`
      this.labelTarget.textContent = "Copied!"

      setTimeout(() => {
        this.iconTarget.innerHTML = originalIcon
        this.labelTarget.textContent = originalLabel
      }, 2000)
    } catch (e) {
      this.labelTarget.textContent = "Failed"
    }
  }
}
