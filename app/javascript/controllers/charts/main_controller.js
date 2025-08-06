import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--main"
export default class extends Controller {
    static targets = ["startDate", "endDate", "budgets", "transactionTypes", "periodButtons"]
    static outlets = ["charts--flow", "charts--distribution"] // Usar el nombre específico del controlador hijo
    static values = {
        url: String // URL for fetching data
    }

    connect() {
        // Inicializar filtros
        console.log("Charts Main Controller connected");
        console.log("Charts Flow Controller Outlet:", this.chartsFlowOutlet);
        console.log("Charts Distribution Controller Outlet:", this.chartsDistributionOutlet);
    }

    // Funciones compartidas
    updateAllCharts() {
        let filters = null;
        const flowChart = this.chartsFlowOutlet.flowChart;
        const distributionChart = this.chartsDistributionOutlet.distributionChart;
        
        filters = this.getFilters();
        filters.period = this.chartsFlowOutlet.currentFlowPeriod; // Usar el período actual

        // Remover el return que estaba cortando la ejecución
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            const url = this.urlValue + '?' + new URLSearchParams(filters).toString();
            console.log('Fetching data from URL:', url); // Debug

            fetch(url, {
                method: 'GET',
                headers: {
                    "Content-Type": "application/json",
                    'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
                    'Accept': 'application/json'
                }      
            })
            .then(response => response.json())
            .then(data => {
                console.log('Data fetched successfully:', data); // Debug
                flowChart.data.labels = data.flow_data.labels;
                flowChart.data.datasets[0].data = data.flow_data.incomeData;
                flowChart.data.datasets[1].data = data.flow_data.expenseData;
                flowChart.update();

                distributionChart.data.labels = data.distribution_data.labels;
                distributionChart.data.datasets[0].data = data.distribution_data.data;
                distributionChart.update();

            })
            .catch(error => {
                console.error('Error fetching cash flow data:', error);
            });
        }, 300);



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
            transaction_types: this.transactionTypesTarget.value ? this.transactionTypesTarget.value.split(',') : []
        };
        return filters;
    }

}