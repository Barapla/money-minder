import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["goal"]
  static values = { url: String }

  connect() {
    this.handleReorder = this.recalculate.bind(this)
    document.addEventListener('saving-goals:reordered', this.handleReorder)
  }

  disconnect() {
    document.removeEventListener('saving-goals:reordered', this.handleReorder)
  }

  async recalculate() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) {
        this.#showError("No se pudo recalcular las metas. Intenta de nuevo.")
        return
      }

      const data = await response.json()
      data.goals.forEach(goal => {
        const element = this.goalTargets.find(el => el.dataset.goalId === goal.id.toString())
        if (!element) {
          console.warn(`Meta ${goal.id} no encontrada en el DOM`)
          return
        }

        const amountEl = element.querySelector('[data-allocated-amount]')
        const percentageEl = element.querySelector('[data-percentage]')
        const barEl = element.querySelector('[data-progress-bar]')

        if (amountEl) amountEl.textContent = goal.allocated_formatted
        if (percentageEl) percentageEl.textContent = `${goal.percentage}%`
        if (barEl) barEl.style.width = `${goal.percentage}%`
      })
    } catch (e) {
      console.error("Error al recalcular metas de ahorro:", e)
      this.#showError("Error de conexión al recalcular las metas.")
    }
  }

  #showError(message) {
    const el = document.createElement("div")
    el.className = "fixed top-4 right-4 bg-red-500/90 text-white px-4 py-2 rounded-xl text-sm z-50 shadow-lg"
    el.textContent = message
    document.body.appendChild(el)
    setTimeout(() => el.remove(), 3000)
  }
}
