import { Controller } from "@hotwired/stimulus"

// Minimal open/close for an overlay panel. `open`/`close` toggle the `hidden`
// class on the panel target; Escape and backdrop clicks also close it.
export default class extends Controller {
  static targets = [ "panel" ]

  open(event) {
    event?.preventDefault()
    this.panelTarget.classList.remove("hidden")
    this.boundKeydown = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  close(event) {
    event?.preventDefault()
    this.panelTarget.classList.add("hidden")
    if (this.boundKeydown) document.removeEventListener("keydown", this.boundKeydown)
  }

  // Close only when the backdrop itself (not the dialog) is clicked.
  closeBackground(event) {
    if (event.target === event.currentTarget) this.close(event)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  disconnect() {
    if (this.boundKeydown) document.removeEventListener("keydown", this.boundKeydown)
  }
}
