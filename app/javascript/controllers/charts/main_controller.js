import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--main"
export default class extends Controller {
    static targets = ["startDate", "endDate", "budgets", "transactionTypes", "periodButtons"]
    static outlets = ["charts--flow"] // Usar el nombre específico del controlador hijo

    connect() {
        // Inicializar filtros
        console.log("Charts Main Controller connected");
        console.log("budgetsTarget:", this.budgetsTarget);
        
    }

    // Funciones compartidas
    updateAllCharts() {
        console.log("Updating all charts with new filters");
        this.chartsFlowOutlets.forEach(childController => {
            if (childController.updateChart) {
                childController.updateChart();
            }
        });
    }
    
    filterData() {
        // Lógica de filtrado común
    }
    
    exportData() {
        // Función compartida
    }

    // Método para obtener filtros
    getFilters() {
        const filters = {
            start_date: this.startDateTarget.value,
            end_date: this.endDateTarget.value,
            budgets: this.budgetsTarget.value ? this.budgetsTarget.value.split(',') : [],
        };
        return filters;
    }

}