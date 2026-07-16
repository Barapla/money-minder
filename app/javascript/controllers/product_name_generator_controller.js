import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "nameField", "namePreview", "preview"]
  static values = { userName: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const hasProduct = this.selectTarget.value !== ""

    this.nameFieldTarget.classList.toggle("hidden", hasProduct)
    this.namePreviewTarget.classList.toggle("hidden", !hasProduct)

    if (hasProduct) {
      const productName = this.selectTarget.selectedOptions[0].text
      this.previewTarget.textContent = `Cuenta ${productName} de ${this.userNameValue}`
    }
  }
}
