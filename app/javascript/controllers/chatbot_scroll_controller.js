import { Controller } from "@hotwired/stimulus"

// Mantiene el historial del chatbot con scroll al final, incluso cuando Turbo
// Streams agrega mensajes nuevos sin recargar la pagina.
export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
