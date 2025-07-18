import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="datatable-filters"
export default class extends Controller {
  static targets = ["input_search", "select_filters", "select_dropdowns", "checkbox_filters"]
  static values = { url: String, method: { type: String, default: "POST" }, id: String }

  connect() {
    // Escucha los eventos del controlador de paginación
    this.element.addEventListener("pagination:change", this.handlePaginationChange.bind(this))
  }

  // Este controlador es el ÚNICO que hace peticiones al servidor
  handlePaginationChange(event) {
    const { page, perPage } = event.detail
    this.fetchData({ page, perPage })
  }

  submit(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      event.preventDefault()
      this.fetchData({ page: 1, perPage: 10 }) // Reset a primera página cuando se aplican filtros
    }, 300)
  }

  fetchData(paginationParams = {}) {
    // Obtiene los valores de los filtros de selección
    // const select_filters = this.select_filtersTargets.map(filter => ({
    //   field: filter.attributes['data-field'].value,
    //   value: filter.value
    // }))

    // Obtiene los valores de los filtros de casilla de verificación
    // const checkbox_filters = this.getCheckboxFilters()

    // Construye el objeto de parámetros completo
    const params = {
      id: this.idValue,
      ...paginationParams // Incluye parámetros de paginación
    }

    fetch(this.urlValue, {
      method: this.methodValue,
      headers: {
        "Content-Type": "application/json",
        'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
        Accept: "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify(params)
    })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))
  }

  getCheckboxFilters() {
    const checkbox_filters = {}

    this.checkbox_filtersTargets.forEach(filter => {
      const field = filter.attributes['data-field'].value
      const checkedBoxes = filter.querySelectorAll('input[type=checkbox]:checked')

      if (checkedBoxes.length > 0) {
        checkbox_filters[field] = Array.from(checkedBoxes).map(checkbox => checkbox.value)
      }
    })

    return checkbox_filters
  }

  reset() {
    this.input_searchTarget.value = "";
    this.select_filtersTargets.forEach((filter, index) => {
      const dropdown = this.select_dropdownsTargets[index];
      const firstTabIndexZero = dropdown.querySelector('div[tabindex="0"]');
      if (firstTabIndexZero) {
        firstTabIndexZero.click();
      }
    });
    this.checkbox_filtersTargets.forEach(filter => {
      filter.querySelectorAll('input[type=checkbox]:checked').forEach(checkbox => checkbox.checked = false);
    });

    this.submit(event);
  }
}
