import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--category-distribution"
export default class extends Controller {
    static targets = ["canvas", "typeSelector"]
}