// calendar_loader_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    show() {
        this.element.classList.add('opacity-60', 'pointer-events-none')
    }
    
    hide() {
        this.element.classList.remove('opacity-60', 'pointer-events-none')
    }
}