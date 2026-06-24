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
      if (!response.ok) return

      const data = await response.json()
      data.goals.forEach(goal => {
        const element = this.goalTargets.find(el => el.dataset.goalId === goal.id.toString())
        if (!element) return

        const amountEl = element.querySelector('[data-allocated-amount]')
        const percentageEl = element.querySelector('[data-percentage]')
        const barEl = element.querySelector('[data-progress-bar]')

        if (amountEl) amountEl.textContent = goal.allocated_formatted
        if (percentageEl) percentageEl.textContent = `${goal.percentage}%`
        if (barEl) barEl.style.width = `${goal.percentage}%`
      })
    } catch (e) {
      console.error("Error al recalcular metas de ahorro:", e)
    }
  }
}
