import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="budget-tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const { type } = event.currentTarget.dataset

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.type === type
      tab.classList.toggle("bg-purple-500", active)
      tab.classList.toggle("text-white", active)
      tab.classList.toggle("bg-bunker-900/50", !active)
      tab.classList.toggle("text-bunker-300", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.type !== type)
    })
  }
}
