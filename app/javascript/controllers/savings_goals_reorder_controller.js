import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["item"]

  connect() {
    this.draggedItem = null
    this.savedOrder = null
  }

  dragstart(event) {
    this.draggedItem = event.currentTarget
    this.savedOrder = [...this.itemTargets]
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50")
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    const target = event.currentTarget
    if (target === this.draggedItem) return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2
    if (event.clientY < midY) {
      target.parentNode.insertBefore(this.draggedItem, target)
    } else {
      target.parentNode.insertBefore(this.draggedItem, target.nextSibling)
    }
  }

  dragend(event) {
    event.currentTarget.classList.remove("opacity-50")
    this.draggedItem = null
    this.#saveOrder()
  }

  async #saveOrder() {
    const ids = this.itemTargets.map(item => item.dataset.goalId)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ order: ids })
      })
      if (response.ok) {
        Turbo.visit(window.location.href, { action: "replace" })
      } else {
        this.#revertOrder()
        this.#showError("No se pudo guardar el orden. Intenta de nuevo.")
      }
    } catch (e) {
      console.error("Error al reordenar metas de ahorro:", e)
      this.#revertOrder()
      this.#showError("Error de conexión al guardar el orden.")
    }
  }

  #revertOrder() {
    const container = this.itemTargets[0]?.parentNode
    if (!container || !this.savedOrder) return
    this.savedOrder.forEach(item => container.appendChild(item))
  }

  #showError(message) {
    const el = document.createElement("div")
    el.className = "fixed top-4 right-4 bg-red-500/90 text-white px-4 py-2 rounded-xl text-sm z-50 shadow-lg"
    el.textContent = message
    document.body.appendChild(el)
    setTimeout(() => el.remove(), 3000)
  }
}
