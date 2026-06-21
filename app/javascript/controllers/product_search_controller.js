import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "results"]

  connect() {
    this.boundOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
  }

  search() {
    this.fetchProducts(this.inputTarget.value || "")
  }

  focus() {
    this.fetchProducts(this.inputTarget.value || "")
    this.dropdownTarget.classList.remove("hidden")
  }

  async fetchProducts(query) {
    const url = `/products/search?q=${encodeURIComponent(query)}`
    try {
      const response = await fetch(url, { headers: { "Accept": "application/json" } })
      const products = await response.json()
      this.render(products, query)
    } catch (e) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  render(products, query) {
    this.resultsTarget.innerHTML = ""
    if (products.length === 0) {
      if (query.trim().length > 0) {
        this.resultsTarget.innerHTML = `<p class="px-3 py-2 text-xs text-muted-foreground">No products found</p>`
      }
    } else {
      products.forEach(product => {
        const el = document.createElement("button")
        el.type = "button"
        el.className = "w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted/50 transition-colors"
        el.innerHTML = `<div class="font-medium">${product.name}</div><div class="text-xs text-muted-foreground">D${parseFloat(product.unit_price).toFixed(0)}</div>`
        el.addEventListener("click", () => {
          this.dispatch("add", { detail: product })
          this.dropdownTarget.classList.add("hidden")
          this.inputTarget.value = ""
        })
        this.resultsTarget.appendChild(el)
      })
    }
    this.dropdownTarget.classList.remove("hidden")
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }
}
