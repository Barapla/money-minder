import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--budget-comparison"
export default class extends Controller {
    static targets = ["canvas", "dropdown", "checkboxes"]
    
}