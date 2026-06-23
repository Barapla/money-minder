import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "hamburger", "close"]

  toggle() {
    const isHidden = this.menuTarget.classList.contains("hidden")
    this.menuTarget.classList.toggle("hidden")
    this.hamburgerTarget.classList.toggle("hidden", !isHidden)
    this.closeTarget.classList.toggle("hidden", isHidden)
  }
}
