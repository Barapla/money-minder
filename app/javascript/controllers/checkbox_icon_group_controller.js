import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-icon-group"
export default class extends Controller {
  static targets = [ "checkbox" ]

  connect() {
  }

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change'))
    })
  }

  deselectAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
      checkbox.dispatchEvent(new Event('change'))
    })
  }
}
