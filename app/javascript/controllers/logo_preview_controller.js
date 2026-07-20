import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "image", "placeholder" ]

  disconnect() {
    this.revokeUrl()
  }

  preview() {
    const file = this.inputTarget.files[0]
    if (!file || !file.type.startsWith("image/")) return

    this.revokeUrl()
    this.url = URL.createObjectURL(file)

    this.imageTarget.src = this.url
    this.imageTarget.classList.remove("hidden")
    this.placeholderTarget.classList.add("hidden")
  }

  revokeUrl() {
    if (this.url) {
      URL.revokeObjectURL(this.url)
      this.url = null
    }
  }
}
