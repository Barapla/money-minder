import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["item"]

  connect() {
    this.draggedItem = null
  }

  dragstart(event) {
    this.draggedItem = event.currentTarget
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
        window.location.reload()
      }
    } catch (e) {
      console.error("Error al reordenar metas de ahorro:", e)
    }
  }
}
