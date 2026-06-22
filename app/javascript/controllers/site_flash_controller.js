import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { notice: String, alert: String }

  connect() {
    if (this.noticeValue) {
      this.show(this.noticeValue, "notice")
    }
    if (this.alertValue) {
      this.show(this.alertValue, "alert")
    }
  }

  show(message, type) {
    const bg = type === "notice"
      ? "background:#c9a84c;color:#0d0f14"
      : "background:#c0392b;color:#fff"

    const toast = document.createElement("div")
    toast.className = "toast-item"
    toast.style.cssText = `position:fixed;top:20px;right:20px;z-index:9999;max-width:380px;${bg};padding:14px 20px;border-radius:10px;font-size:14px;font-weight:500;cursor:pointer;box-shadow:0 8px 32px rgba(0,0,0,0.25);opacity:0;transform:translateY(-10px);transition:opacity 0.3s,transform 0.3s;line-height:1.5`
    toast.textContent = message
    document.body.appendChild(toast)

    requestAnimationFrame(() => {
      toast.style.opacity = "1"
      toast.style.transform = "translateY(0)"
    })

    const timer = setTimeout(() => this.dismiss(toast), 4000)

    toast.addEventListener("toast-dismiss", () => {
      clearTimeout(timer)
      this.dismiss(toast)
    })

    const dismissClick = () => {
      clearTimeout(timer)
      this.dismiss(toast)
    }
    toast.addEventListener("click", dismissClick, { once: true })
  }

  dismiss(element) {
    element.style.opacity = "0"
    element.style.transform = "translateY(-10px)"
    setTimeout(() => element.remove(), 300)
  }
}
