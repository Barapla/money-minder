import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--main"
export default class extends Controller {
    static targets = ["summaryCards"]
    static values = { 
        data: Object,
        dateRange: Object,
        selectedBudgets: Array 
    }

    // Funciones compartidas
    updateAllCharts() {
        this.dispatch("updateCharts") // Envía evento a todos los charts
    }
    
    filterData() {
        // Lógica de filtrado común
    }
    
    exportData() {
        // Función compartida
    }
}