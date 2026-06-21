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

  addProduct(event) {
    const product = event.detail
    this.add({ preventDefault: () => {} })
    const items = this.itemsTarget.querySelectorAll("[data-invoice-item]")
    const last = items[items.length - 1]
    if (!last) return

    const desc = last.querySelector("input[name*='[description]']")
    const qty = last.querySelector("input[name*='[quantity]']")
    const price = last.querySelector("input[name*='[unit_price]']")
    if (desc) desc.value = product.name
    if (qty) qty.value = 1
    if (price) price.value = parseFloat(product.unit_price).toFixed(0)
  }
}
