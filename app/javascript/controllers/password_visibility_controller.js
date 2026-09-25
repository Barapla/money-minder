import { Controller } from "@hotwired/stimulus"

// Alterna entre type="password" y type="text" en el campo, y cambia el texto del
// boton. Los rotulos vienen del servidor para que sigan traducidos.
export default class extends Controller {
  static targets = ["field", "button"]

  toggle() {
    const shown = this.fieldTarget.type === "text"
    this.fieldTarget.type = shown ? "password" : "text"
    this.buttonTarget.textContent = shown ? this.buttonTarget.dataset.show : this.buttonTarget.dataset.hide
    this.buttonTarget.setAttribute("aria-pressed", String(!shown))
  }
}
