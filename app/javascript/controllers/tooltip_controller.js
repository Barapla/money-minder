import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  connect() {
    this.tooltip = null
  }

  show() {
    if (this.tooltip) return

    this.tooltip = document.createElement("div")
    this.tooltip.className =
      "absolute z-50 max-w-xs bg-bunker-800 border border-bunker-700 text-bunker-200 text-xs rounded-xl px-3 py-2 shadow-lg pointer-events-none"
    this.tooltip.textContent = this.contentValue
    document.body.appendChild(this.tooltip)
    this.#position()
  }

  hide() {
    if (this.tooltip) {
      this.tooltip.remove()
      this.tooltip = null
    }
  }

  #position() {
    const rect = this.element.getBoundingClientRect()
    const scrollY = window.scrollY
    this.tooltip.style.left = `${rect.left}px`
    this.tooltip.style.top = `${rect.bottom + scrollY + 6}px`
  }
}
