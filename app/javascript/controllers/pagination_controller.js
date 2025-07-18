import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  // Este controlador SOLO emite eventos
  changePage(event) {
    if (event.currentTarget.classList.contains("disabled")) {
      event.preventDefault()
      return  
    }

    const page = parseInt(event.currentTarget.dataset.page)

    this.element.dispatchEvent(new CustomEvent("pagination:change", {
      bubbles: true,
      detail: {
        page: page,
        perPage: 10
      }
    }))
  }

  changePerPage(event) {
    this.element.dispatchEvent(new CustomEvent("pagination:change", {
      bubbles: true,
      detail: {
        page: 1,
        perPage: event.currentTarget.value
      }
    }))
  }
}