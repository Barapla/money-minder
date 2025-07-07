import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="select-to"
export default class extends Controller {
  static targets = [ "select" ]
  static values = { url: String, field: String, method: { type: String, default: "POST" }, model: String }

  connect() {
    this.selectTarget.addEventListener("change", this.handleChange.bind(this))
  }

  handleChange(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      // Evita que el formulario se envíe de la manera tradicional
      event.preventDefault();

      // Obtiene los valores de los filtros de selección
      const value = event.target.value

      // Obtiene los valores de los campos de entrada
      const params = { 
        [this.modelValue]: {
          [this.fieldValue]: value
        }
      };

      fetch(this.urlValue, {
        method: this.methodValue,
        headers: {
          "Content-Type": "application/json",
          'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
          Accept: "text/vnd.turbo-stream.html" // Importante para que Turbo pueda procesar la respuesta
        },
        body: JSON.stringify(params)
      })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html));
    }, 300)
  }
}
