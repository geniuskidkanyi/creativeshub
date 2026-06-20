import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "hidden", "dropdown", "selectedName", "modal", "newForm", "searchResults" ]
  static values = { url: String, selectedId: String, selectedName: String }

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)

    if (this.selectedIdValue && this.selectedNameValue) {
      this.inputTarget.value = this.selectedNameValue
      this.hiddenTarget.value = this.selectedIdValue
    }

    this.form = this.element.querySelector("form")
    if (this.form) {
      this.boundValidate = this.validateSubmit.bind(this)
      this.form.addEventListener("submit", this.boundValidate)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    if (this.form) {
      this.form.removeEventListener("submit", this.boundValidate)
    }
  }

  search() {
    const query = this.inputTarget.value
    this.selectedIdValue = ""
    this.selectedNameValue = ""
    this.hiddenTarget.value = ""

    if (query.length === 0) {
      this.fetchClients("")
    } else {
      this.fetchClients(query)
    }
  }

  focus() {
    if (this.selectedIdValue) return
    this.fetchClients(this.inputTarget.value || "")
    this.dropdownTarget.classList.remove("hidden")
  }

  async fetchClients(query) {
    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
    try {
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      const clients = await response.json()
      this.renderResults(clients, query)
    } catch (e) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  renderResults(clients, query) {
    this.searchResultsTarget.innerHTML = ""

    if (clients.length === 0) {
      if (query.trim().length > 0) {
        this.searchResultsTarget.innerHTML = `
          <button type="button" data-action="client-search#openModal" class="w-full text-left px-3 py-2 text-sm text-primary hover:bg-muted/50 transition-colors flex items-center gap-2">
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Create "${this.escapeHtml(query)}"
          </button>
        `
      } else {
        this.searchResultsTarget.innerHTML = `
          <p class="px-3 py-2 text-xs text-muted-foreground">No clients found. Type to search or create new.</p>
        `
      }
    } else {
      clients.forEach(client => {
        const el = document.createElement("button")
        el.type = "button"
        el.className = "w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted/50 transition-colors"
        el.innerHTML = `
          <div class="font-medium">${this.escapeHtml(client.name)}</div>
          <div class="text-xs text-muted-foreground">${this.escapeHtml(client.email)} ${client.company ? "· " + this.escapeHtml(client.company) : ""}</div>
        `
        el.addEventListener("click", () => this.select(client))
        this.searchResultsTarget.appendChild(el)
      })
    }

    this.dropdownTarget.classList.remove("hidden")
  }

  select(client) {
    this.selectedIdValue = client.id
    this.selectedNameValue = client.name
    this.hiddenTarget.value = client.id
    this.inputTarget.value = client.name
    this.dropdownTarget.classList.add("hidden")
  }

  clearSelection() {
    this.selectedIdValue = ""
    this.selectedNameValue = ""
    this.hiddenTarget.value = ""
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  validateSubmit(event) {
    if (!this.hiddenTarget.value) {
      event.preventDefault()
      event.stopPropagation()
      this.inputTarget.focus()
      this.showToast("Please select or create a client before saving.", true)
    }
  }

  openModal() {
    const name = this.inputTarget.value.trim()
    if (name) {
      this.modalTarget.querySelector("input[name='client[name]']").value = name
    }
    this.dropdownTarget.classList.add("hidden")
    this.modalTarget.classList.remove("hidden")
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.newFormTarget.reset()
  }

  async submitNewClient(event) {
    event.preventDefault()
    const form = this.newFormTarget
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: formData
      })

      if (response.ok) {
        const client = await response.json()
        this.select(client)
        this.closeModal()
        this.showToast("Client created successfully")
      } else {
        const data = await response.json()
        this.showModalErrors(data.errors)
      }
    } catch (e) {
      this.showToast("Failed to create client", true)
    }
  }

  showModalErrors(errors) {
    const container = this.modalTarget.querySelector("[data-client-search-target='modalErrors']")
    if (container) {
      container.innerHTML = errors.map(e => `<li class="text-xs text-destructive">${e}</li>`).join("")
      container.classList.remove("hidden")
    }
  }

  showToast(message, isError = false) {
    const toast = document.createElement("div")
    toast.className = `fixed bottom-4 right-4 z-50 px-4 py-3 rounded-md text-sm shadow-lg ${isError ? 'bg-destructive text-destructive-foreground' : 'bg-accent text-accent-foreground'}`
    toast.textContent = message
    document.body.appendChild(toast)
    setTimeout(() => toast.remove(), 3000)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
