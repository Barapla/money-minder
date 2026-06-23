import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "button"]

  connect() {
    this.closeTimer = null
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    clearTimeout(this.closeTimer)
  }

  open() {
    clearTimeout(this.closeTimer)
    this.dropdownTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.boundClickOutside)
  }

  startCloseTimer() {
    this.closeTimer = setTimeout(() => this.close(), 150)
  }

  cancelCloseTimer() {
    clearTimeout(this.closeTimer)
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    if (this.dropdownTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.buttonTarget.focus()
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
