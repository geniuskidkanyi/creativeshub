import { Controller } from "@hotwired/stimulus"

const DAYS = [ "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" ]
const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
]

export default class extends Controller {
  static targets = [ "input", "hidden", "calendar" ]
  static values = { date: String }

  connect() {
    this.showing = false
    this.currentMonth = this.dateValue ? new Date(this.dateValue + "T00:00:00") : new Date()
    this.boundOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
  }

  toggle() {
    this.showing ? this.hide() : this.show()
  }

  show() {
    this.showing = true
    this.render()
    this.calendarTarget.classList.remove("hidden")
  }

  hide() {
    this.showing = false
    this.calendarTarget.classList.add("hidden")
  }

  prevMonth() {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1, 1)
    this.render()
  }

  nextMonth() {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1, 1)
    this.render()
  }

  selectDay(event) {
    const day = parseInt(event.currentTarget.dataset.day)
    const date = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth(), day)
    const formatted = this.formatDate(date)
    this.dateValue = formatted
    this.hiddenTarget.value = formatted
    this.inputTarget.value = this.formatDisplay(date)
    this.hide()
  }

  focusInput() {
    this.show()
  }

  render() {
    const year = this.currentMonth.getFullYear()
    const month = this.currentMonth.getMonth()
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const selected = this.dateValue ? new Date(this.dateValue + "T00:00:00") : null

    const firstDay = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()

    let html = `<div class="p-3">`

    html += `<div class="flex items-center justify-between mb-3">
      <button type="button" data-action="date-picker#prevMonth" class="p-1 text-muted-foreground hover:text-foreground transition-colors">
        <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
      </button>
      <span class="text-sm text-foreground font-medium">${MONTHS[month]} ${year}</span>
      <button type="button" data-action="date-picker#nextMonth" class="p-1 text-muted-foreground hover:text-foreground transition-colors">
        <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
      </button>
    </div>`

    html += `<div class="grid grid-cols-7 gap-0.5 mb-1">`
    DAYS.forEach(day => {
      html += `<div class="text-center text-xs text-muted-foreground py-1">${day}</div>`
    })
    html += `</div>`

    html += `<div class="grid grid-cols-7 gap-0.5">`
    for (let i = 0; i < firstDay; i++) {
      html += `<div></div>`
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, month, d)
      const isToday = date.getTime() === today.getTime()
      const isSelected = selected && date.getTime() === selected.getTime()
      let cls = "text-center text-sm py-1 rounded cursor-pointer transition-colors "
      if (isSelected) {
        cls += "bg-primary text-primary-foreground"
      } else if (isToday) {
        cls += "text-primary font-medium hover:bg-primary/20"
      } else {
        cls += "text-foreground hover:bg-muted"
      }
      html += `<button type="button" data-action="date-picker#selectDay" data-day="${d}" class="${cls}">${d}</button>`
    }
    html += `</div></div>`

    this.calendarTarget.innerHTML = html
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  formatDate(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  formatDisplay(date) {
    return date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
  }
}
