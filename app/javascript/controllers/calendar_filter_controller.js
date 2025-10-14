import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calendar-filter"
export default class extends Controller {
  static targets = [ "special_radio", "budget_checkbox", "icon_checkbox", "min_amount", "max_amount" ]
  static values = { url: String, method: { type: String, default: "POST" } }

  connect() {
    this.special_radioTargets.forEach(radio => {
      radio.addEventListener("change", this.handleChange.bind(this))
    })

    this.budget_checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener("change", this.handleChange.bind(this))
    })

    this.icon_checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener("change", this.handleChange.bind(this))
    })

    this.min_amountTarget.addEventListener("input", this.handleChange.bind(this))
    this.max_amountTarget.addEventListener("input", this.handleChange.bind(this))
  }

  changeAmount({ params: { min, max } }) {
    this.min_amountTarget.value = min
    this.max_amountTarget.value = max
    this.handleChange(new Event('change'))
  }

  handleChange(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      // Evita que el formulario se envíe de la manera tradicional
      event.preventDefault();

      // Obtiene los valores de los como array
      // quiero un array con los valores de los checkbox que están checked
      const special = this.special_radioTargets.filter(r => r.checked).map(r => r.value)
      const budgets = this.budget_checkboxTargets.filter(c => c.checked).map(c => c.value)
      const icon_checkboxes = this.icon_checkboxTargets.filter(c => c.checked).map(c => c.value)
      const min_amount = this.min_amountTarget.value
      const max_amount = this.max_amountTarget.value

      // Obtiene los valores de los campos de entrada
      const params = {
        filter: {
          special: special,
          budgets: budgets,
          icons: icon_checkboxes,
          min_amount: min_amount,
          max_amount: max_amount
        }
      }

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
