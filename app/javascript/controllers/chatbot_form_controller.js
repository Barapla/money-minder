import { Controller } from "@hotwired/stimulus"

// Indicador de "escribiendo..." mientras espera la respuesta del chatbot y
// limpieza del input una vez que Turbo Stream inserta la respuesta.
export default class extends Controller {
  static targets = ["input", "submit"]

  submitting() {
    this.submitTarget.disabled = true
    this.submitTarget.value = "Pensando…"
  }

  reset() {
    this.inputTarget.value = ""
    this.submitTarget.disabled = false
    this.submitTarget.value = "Enviar"
    this.inputTarget.focus()
  }
}
