import { Controller } from "@hotwired/stimulus"

// Drives the recurring-invoice form as a 3-step wizard. The form still posts
// once at the end — this only shows/hides panels, gates advancing on
// per-step validation, and keeps the live total and final summary in sync.
export default class extends Controller {
  static targets = [ "panel", "indicator", "error", "summary", "total" ]
  static values = { step: { type: Number, default: 1 } }

  connect() {
    // Recompute the total on any input change, including line-item rows added
    // dynamically after connect (event delegation, so new rows are covered).
    this.element.addEventListener("input", () => this.recalc())
    // …and when rows are added or removed, which set values programmatically
    // and so fire no input event of their own.
    this.element.addEventListener("line-items:changed", () => this.recalc())
    // If the server bounced the form back with errors, land on the step that
    // owns the first invalid field rather than always step 1.
    this.showStep(this.element.dataset.wizardStartStep ? Number(this.element.dataset.wizardStartStep) : this.stepValue)
    this.recalc()
  }

  next(event) {
    event.preventDefault()
    if (!this.validate(this.stepValue)) return
    this.showStep(Math.min(this.stepValue + 1, this.panelTargets.length))
  }

  back(event) {
    event.preventDefault()
    this.showStep(Math.max(this.stepValue - 1, 1))
  }

  // Clicking a header step jumps straight there, but only backwards — you
  // can't skip ahead past a step that hasn't validated.
  goTo(event) {
    const target = Number(event.currentTarget.dataset.step)
    if (target < this.stepValue) this.showStep(target)
  }

  showStep(step) {
    this.stepValue = step
    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", Number(panel.dataset.step) !== step)
    })
    this.indicatorTargets.forEach((indicator) => {
      const s = Number(indicator.dataset.step)
      indicator.dataset.state = s < step ? "done" : s === step ? "active" : "todo"
    })
    if (step === this.panelTargets.length) this.updateSummary()
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  // Toggles the two "and end…" inputs so only the relevant one is shown, and
  // clears the hidden one so a stale value never reaches the server.
  endMode(event) {
    const mode = event.target.value
    const onDate = this.field("end_date")
    const after = this.field("max_occurrences")
    this.wrapperFor(onDate).classList.toggle("hidden", mode !== "on")
    this.wrapperFor(after).classList.toggle("hidden", mode !== "after")
    if (mode !== "on" && onDate) onDate.value = ""
    if (mode !== "after" && after) after.value = ""
  }

  validate(step) {
    this.clearError(step)

    if (step === 1) {
      if (!this.field("client_id")?.value) return this.fail(1, "Choose a customer for this invoice.")
      const priced = this.lineItems().some((row) => row.description && row.price > 0)
      if (!priced) return this.fail(1, "Add at least one line item with a price above zero.")
    }

    if (step === 2) {
      const startValue = this.field("start_date")?.value
      if (!startValue) return this.fail(2, "Pick the date of the first invoice.")
      if (this.isPast(startValue)) return this.fail(2, "The first invoice can't be dated in the past.")
      if (Number(this.field("interval")?.value) < 1) return this.fail(2, "Repeat interval must be at least 1.")
      const mode = this.element.querySelector("[data-wizard-end-mode]")?.value
      if (mode === "on" && !this.field("end_date")?.value) return this.fail(2, "Choose the date the schedule ends.")
      if (mode === "after" && !(Number(this.field("max_occurrences")?.value) > 0)) return this.fail(2, "Enter how many invoices to send.")
    }

    return true
  }

  // ---- helpers ----

  field(name) {
    return this.element.querySelector(`[name='recurring_invoice[${name}]']`)
  }

  wrapperFor(input) {
    return input?.closest("[data-end-field]") || input
  }

  lineItems() {
    return Array.from(this.element.querySelectorAll("[data-invoice-item]"))
      .filter((row) => !row.classList.contains("hidden"))
      .map((row) => ({
        description: row.querySelector("[name*='[description]']")?.value.trim(),
        qty: parseFloat(row.querySelector("[name*='[quantity]']")?.value) || 0,
        price: parseFloat(row.querySelector("[name*='[unit_price]']")?.value) || 0
      }))
  }

  recalc() {
    const subtotal = this.lineItems().reduce((sum, row) => sum + row.qty * row.price, 0)
    const taxRate = parseFloat(this.field("tax_rate")?.value) || 0
    const discount = parseFloat(this.field("discount")?.value) || 0
    const taxable = Math.max(subtotal - discount, 0)
    const total = taxable * (1 + taxRate / 100)
    this.totalTargets.forEach((el) => (el.textContent = this.money(total)))
    this.updateCurrencyHint(total)
  }

  // Toggles the FX-rate field for non-GMD schedules and refreshes the total,
  // which now renders in the chosen currency's symbol.
  currencyChanged() {
    const isBase = this.currencyCode() === "GMD"
    const rateField = this.element.querySelector("[data-rate-field]")
    if (rateField) rateField.classList.toggle("hidden", isBase)
    if (isBase && this.field("fx_rate")) this.field("fx_rate").value = 1
    this.recalc()
  }

  updateCurrencyHint(total) {
    const hint = this.element.querySelector("[data-currency-hint]")
    if (!hint) return
    const isBase = this.currencyCode() === "GMD"
    const rate = parseFloat(this.field("fx_rate")?.value) || 0
    const gmd = total * rate
    hint.classList.toggle("hidden", isBase || !(gmd > 0))
    const amount = this.element.querySelector("[data-currency-hint-amount]")
    if (amount) amount.textContent = "D" + gmd.toLocaleString("en-US", { maximumFractionDigits: 2 })
  }

  updateSummary() {
    if (!this.hasSummaryTarget) return
    // The client picker is the shared client-search field (a hidden id + a
    // visible name input), so read the display name off the input.
    const clientInput = this.element.querySelector("[data-client-search-target='input']")
    const client = this.field("client_id")
    const clientName = clientInput?.value || (client?.selectedOptions ? client.selectedOptions[0]?.text : client?.dataset.label)
    const total = this.currentTotal()
    const rows = [
      [ "Customer", clientName || "—" ],
      [ "Schedule", this.scheduleText() ],
      [ "First invoice", this.formatDate(this.field("start_date")?.value) ],
      [ "Each invoice", this.money(total) ]
    ]
    if (this.currencyCode() !== "GMD") {
      const gmd = total * (parseFloat(this.field("fx_rate")?.value) || 0)
      rows.push([ "Customer pays (GMD)", "D" + gmd.toLocaleString("en-US", { maximumFractionDigits: 2 }) ])
    }
    this.summaryTarget.innerHTML = rows.map(([label, value]) => `
      <div class="flex items-center justify-between py-2 border-b border-border last:border-0">
        <span class="text-xs text-muted-foreground">${label}</span>
        <span class="text-sm text-foreground font-medium text-right">${value}</span>
      </div>`).join("")
  }

  scheduleText() {
    const freq = this.field("frequency")?.value || "monthly"
    const interval = Number(this.field("interval")?.value) || 1
    const base = interval === 1 ? freq.charAt(0).toUpperCase() + freq.slice(1)
                                : `Every ${interval} ${freq.replace(/ly$/, "")}s`
    const mode = this.element.querySelector("[data-wizard-end-mode]")?.value
    if (mode === "on") return `${base} until ${this.formatDate(this.field("end_date")?.value)}`
    if (mode === "after") return `${base} · ${this.field("max_occurrences")?.value} invoices`
    return base
  }

  currentTotal() {
    const subtotal = this.lineItems().reduce((sum, row) => sum + row.qty * row.price, 0)
    const taxable = Math.max(subtotal - (parseFloat(this.field("discount")?.value) || 0), 0)
    return taxable * (1 + (parseFloat(this.field("tax_rate")?.value) || 0) / 100)
  }

  fail(step, message) {
    const banner = this.errorFor(step)
    if (banner) {
      banner.textContent = message
      banner.classList.remove("hidden")
    }
    return false
  }

  clearError(step) {
    const banner = this.errorFor(step)
    if (banner) banner.classList.add("hidden")
  }

  errorFor(step) {
    return this.errorTargets.find((el) => Number(el.dataset.step) === step)
  }

  currencyCode() {
    return this.field("currency")?.value || "GMD"
  }

  currencySymbol() {
    return { GMD: "D", USD: "$", EUR: "€", GBP: "£", CAD: "C$", XOF: "CFA", NGN: "₦", GHS: "₵", AED: "د.إ", CNY: "¥" }[this.currencyCode()] || this.currencyCode()
  }

  money(value) {
    return this.currencySymbol() + (value || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  // Compares calendar dates, not timestamps — a start date of "today" is
  // allowed, only genuinely earlier days are rejected.
  isPast(value) {
    const picked = new Date(value + "T00:00:00")
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return picked < today
  }

  formatDate(value) {
    if (!value) return "—"
    const date = new Date(value)
    return isNaN(date) ? value : date.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })
  }
}
