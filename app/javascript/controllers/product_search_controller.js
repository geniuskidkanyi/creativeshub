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
    const q = query.trim()

    if (products.length === 0 && q.length > 0) {
      this.resultsTarget.innerHTML = `<p class="px-3 py-2 text-xs text-muted-foreground">No products found</p>`
    }

    products.forEach(product => {
      const el = document.createElement("button")
      el.type = "button"
      el.className = "w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted/50 transition-colors"
      el.innerHTML = `<div class="font-medium">${this.escape(product.name)}</div><div class="text-xs text-muted-foreground">D${parseFloat(product.unit_price).toFixed(0)}</div>`
      el.addEventListener("click", () => this.select(product))
      this.resultsTarget.appendChild(el)
    })

    // Find-or-create: offer to create the typed product inline when it doesn't exist yet.
    if (q.length > 0 && !products.some(p => p.name.toLowerCase() === q.toLowerCase())) {
      const create = document.createElement("button")
      create.type = "button"
      create.className = "w-full text-left px-3 py-2 text-sm text-primary font-semibold hover:bg-muted/50 transition-colors border-t border-border"
      create.innerHTML = `＋ Create "${this.escape(q)}" as a new product`
      create.addEventListener("click", (e) => {
        e.stopPropagation()
        this.showCreateForm(q)
      })
      this.resultsTarget.appendChild(create)
    }

    this.dropdownTarget.classList.remove("hidden")
  }

  showCreateForm(name) {
    this.resultsTarget.innerHTML = `
      <div class="p-3">
        <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">New product</p>
        <div class="space-y-2">
          <input type="text" data-create-name value="${this.escape(name)}" placeholder="Product name"
                 class="w-full rounded-md border border-border bg-input-background text-foreground placeholder:text-muted-foreground px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-primary">
          <input type="number" data-create-price step="0.01" min="0" placeholder="Unit price (D)"
                 class="w-full rounded-md border border-border bg-input-background text-foreground placeholder:text-muted-foreground px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-primary">
          <p data-create-error class="hidden text-xs text-red-500"></p>
          <div class="flex gap-2 pt-1">
            <button type="button" data-create-save class="flex-1 px-3 py-2 rounded-md bg-primary text-primary-foreground text-xs font-semibold hover:brightness-110 transition-all">Save &amp; add to invoice</button>
            <button type="button" data-create-cancel class="px-3 py-2 rounded-md border border-border text-xs text-muted-foreground hover:text-foreground transition-colors">Cancel</button>
          </div>
        </div>
      </div>`

    const priceInput = this.resultsTarget.querySelector("[data-create-price]")
    this.resultsTarget.querySelector("[data-create-save]").addEventListener("click", (e) => {
      e.stopPropagation()
      this.createProduct()
    })
    this.resultsTarget.querySelector("[data-create-cancel]").addEventListener("click", (e) => {
      e.stopPropagation()
      this.search()
    })
    this.resultsTarget.querySelectorAll("input").forEach(input => {
      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault()
          this.createProduct()
        }
      })
    })
    priceInput.focus()
  }

  async createProduct() {
    const name = this.resultsTarget.querySelector("[data-create-name]")?.value?.trim()
    const price = this.resultsTarget.querySelector("[data-create-price]")?.value
    const errorEl = this.resultsTarget.querySelector("[data-create-error]")

    if (!name || price === "") {
      this.showCreateError(errorEl, "Name and unit price are required.")
      return
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch("/products", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ product: { name: name, unit_price: price } })
      })

      if (response.ok) {
        const product = await response.json()
        this.select(product)
      } else {
        const data = await response.json().catch(() => ({}))
        this.showCreateError(errorEl, (data.errors || ["Could not create the product."]).join(", "))
      }
    } catch (e) {
      this.showCreateError(errorEl, "Network error — please try again.")
    }
  }

  showCreateError(errorEl, message) {
    if (!errorEl) return
    errorEl.textContent = message
    errorEl.classList.remove("hidden")
  }

  select(product) {
    this.dispatch("add", { detail: product })
    this.dropdownTarget.classList.add("hidden")
    this.inputTarget.value = ""
  }

  escape(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }
}
