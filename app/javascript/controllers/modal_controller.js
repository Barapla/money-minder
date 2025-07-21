import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  close() {
    // Animación de salida más eficiente
    this.element.style.opacity = '0';
    this.containerTarget.style.transform = 'scale(0.95)';
    
    setTimeout(() => {
      document.body.classList.remove('overflow-hidden');
      const frame = document.getElementById('modal_frame');
      if (frame) {
        frame.innerHTML = '';
      }
    }, 150);
  }

  connect() {
    document.body.classList.add('overflow-hidden');
    
    // Animación de entrada
    this.element.style.opacity = '0';
    this.containerTarget.style.transform = 'scale(0.95)';
    
    requestAnimationFrame(() => {
      this.element.style.transition = 'opacity 150ms ease-out';
      this.containerTarget.style.transition = 'transform 150ms ease-out';
      this.element.style.opacity = '1';
      this.containerTarget.style.transform = 'scale(1)';
    });

    // Event listener optimizado
    this.boundClickOutside = this.clickOutside.bind(this);
    this.element.addEventListener('click', this.boundClickOutside);
  }

  disconnect() {
    document.body.classList.remove('overflow-hidden');
    if (this.boundClickOutside) {
      this.element.removeEventListener('click', this.boundClickOutside);
    }
  }

  clickOutside(e) {
    if (e.target === this.element) {
      this.close();
    }
  }
}