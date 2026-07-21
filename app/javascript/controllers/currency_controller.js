import { Controller } from "@hotwired/stimulus"

// Shows the FX-rate field only for non-GMD invoices and keeps a running
// "customer pays ~D…" hint. GMD is the base currency, so its rate is fixed at
// 1 and the field stays hidden.
export default class extends Controller {
  static targets = [ "select", "rateField", "rate", "symbol", "hint", "hintAmount", "total" ]
  static values = { base: { type: String, default: "GMD" } }

  connect() {
    // Keep the "customer pays ~D…" hint current as line items are typed or
    // added/removed, not only when the currency itself changes.
    this.boundUpdate = () => this.update()
    this.element.addEventListener("input", this.boundUpdate)
    this.element.addEventListener("line-items:changed", this.boundUpdate)
    this.update()
  }

  disconnect() {
    this.element.removeEventListener("input", this.boundUpdate)
    this.element.removeEventListener("line-items:changed", this.boundUpdate)
  }

  update() {
    const currency = this.selectTarget.value
    const isBase = currency === this.baseValue

    if (this.hasRateFieldTarget) this.rateFieldTarget.classList.toggle("hidden", isBase)
    if (isBase && this.hasRateTarget) this.rateTarget.value = 1
    if (this.hasSymbolTarget) this.symbolTargets.forEach((el) => (el.textContent = this.symbolFor(currency)))

    this.updateHint(isBase)
  }

  updateHint(isBase) {
    if (!this.hasHintTarget) return
    if (isBase) {
      this.hintTarget.classList.add("hidden")
      return
    }
    const total = parseFloat(this.totalTarget?.dataset.amount) || this.readTotal()
    const rate = parseFloat(this.rateTarget?.value) || 0
    const gmd = total * rate
    this.hintAmountTarget.textContent = "D" + gmd.toLocaleString("en-US", { maximumFractionDigits: 2 })
    this.hintTarget.classList.toggle("hidden", !(gmd > 0))
  }

  // Sums visible line items so the hint reflects the current invoice total
  // without depending on another controller.
  readTotal() {
    return Array.from(this.element.querySelectorAll("[data-invoice-item]"))
      .filter((row) => !row.classList.contains("hidden"))
      .reduce((sum, row) => {
        const qty = parseFloat(row.querySelector("[name*='[quantity]']")?.value) || 0
        const price = parseFloat(row.querySelector("[name*='[unit_price]']")?.value) || 0
        return sum + qty * price
      }, 0)
  }

  symbolFor(code) {
    return { GMD: "D", USD: "$", EUR: "€", GBP: "£", CAD: "C$", XOF: "CFA", NGN: "₦", GHS: "₵", AED: "د.إ", CNY: "¥" }[code] || code
  }
}
