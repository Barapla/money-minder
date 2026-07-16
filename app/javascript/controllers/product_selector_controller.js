import { Controller } from "@hotwired/stimulus"

// Maneja el flujo institucion -> producto del catalogo financiero (FEAT-026).
// Al elegir "Otro" se oculta el select de producto y se muestra el campo de
// nombre manual (si el formulario lo define); al elegir una institucion del
// catalogo se consulta /financial_products y se repuebla el select de producto.
export default class extends Controller {
  static targets = ["institution", "product", "productContainer", "manualNameContainer"]
  static values = { productType: String, selectedProduct: String }

  connect() {
    this.updateProducts()
  }

  async updateProducts() {
    const institution = this.institutionTarget.value

    if (!institution || institution === "other") {
      this.toggleContainers({ showProduct: false })
      return
    }

    this.toggleContainers({ showProduct: true })

    const response = await fetch(
      `/financial_products?type=${encodeURIComponent(this.productTypeValue)}&institution=${encodeURIComponent(institution)}`
    )
    const products = await response.json()

    this.productTarget.innerHTML = [`<option value="">Selecciona un producto</option>`]
      .concat(
        products.map((product) => {
          const isSelected = product.id === this.selectedProductValue ? " selected" : ""
          return `<option value="${product.id}"${isSelected}>${product.name}</option>`
        })
      )
      .join("")
  }

  toggleContainers({ showProduct }) {
    if (this.hasProductContainerTarget) {
      this.productContainerTarget.classList.toggle("hidden", !showProduct)
    }

    if (this.hasManualNameContainerTarget) {
      this.manualNameContainerTarget.classList.toggle("hidden", showProduct)
    }
  }
}
