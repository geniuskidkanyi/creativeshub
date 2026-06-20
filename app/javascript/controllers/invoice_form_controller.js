import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "items", "template" ]

  add(event) {
    event.preventDefault()
    const template = this.templateTarget.innerHTML
    const index = this.itemsTarget.children.length
    const newItem = template.replace(/NEW_RECORD/g, index)
    this.itemsTarget.insertAdjacentHTML("beforeend", newItem)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-invoice-item]")
    const destroyInput = item.querySelector("input[name*='_destroy']")
    if (destroyInput) {
      destroyInput.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }
  }
}
