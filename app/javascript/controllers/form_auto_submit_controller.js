import { Controller } from "@hotwired/stimulus"

// Envia el formulario cuando cambia un control, para filtros que se aplican
// solos. El buscador NO usa esto a proposito: al reenviar, Turbo reemplaza el
// DOM y el input perderia el foco y el cursor a media palabra. Ese se manda con
// Enter o con su boton de lupa, que es comportamiento nativo del formulario.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
