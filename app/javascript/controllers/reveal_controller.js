import { Controller } from "@hotwired/stimulus"

// Marca las filas o tarjetas plegadas como reveladas y avisa hacia arriba. No
// toca la visibilidad: de eso manda budget-filters, para que no se peleen.
export default class extends Controller {
  static targets = ["hidden", "button", "collapsed"]

  toggle() {
    this.shown = !this.shown
    this.hiddenTargets.forEach((el) => { el.dataset.revealed = this.shown })
    // El resumen plegado (la lista de nombres en ceros) sobra cuando ya se ven
    // las tarjetas completas.
    this.collapsedTargets.forEach((el) => el.classList.toggle("hidden", this.shown))
    if (this.hasButtonTarget) {
      const { show, hide } = this.buttonTarget.dataset
      this.buttonTarget.textContent = this.shown ? hide : show
    }
    this.element.dispatchEvent(new CustomEvent("reveal:toggled", { bubbles: true }))
  }
}
