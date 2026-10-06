import { Controller } from "@hotwired/stimulus"

// Burbuja flotante del asesor financiero, visible en cualquier pantalla. Carga
// el contenido del turbo-frame solo la primera vez que se abre (evita pedir la
// conversacion en cada carga de pagina).
export default class extends Controller {
  static targets = ["panel", "frame"]
  static values = { url: String }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    if (!this.panelTarget.classList.contains("hidden") && !this.frameTarget.src) {
      this.frameTarget.src = this.urlValue
    }
  }
}
