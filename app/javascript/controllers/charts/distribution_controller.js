import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

// Connects to data-controller="charts--category-distribution"
export default class extends Controller {
    static targets = ["canvas"]
    static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Object, // Data for the chart
        url: String, // URL for fetching data if needed
        extraFilters: Object // Additional filters for the chart
    }
    static outlets = ["charts--main"]
    distributionChart = null

    connect() {
        this.initializeChart();
    }

    initializeChart() {
        const ctx = this.canvasTarget.getContext('2d');
            this.distributionChart = new Chart(ctx, {
            type: 'doughnut',
            data: this.datasetsValue,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            color: '#d1d5db',
                            usePointStyle: true,
                            padding: 20
                        }
                    }
                }
            }
        });
    }

    updateChart() {
        let filters = this.chartsMainOutlet.getFilters();

        // Merge extra filters with the main filters
        if (this.extraFiltersValue) {
            filters = { ...filters, ...this.extraFiltersValue };
        }
        // Remover el return que estaba cortando la ejecución
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            const params = {
                filters: filters,
                id: this.idValue
            };

            fetch(this.urlValue, {
                method: 'POST',
                headers: {
                    "Content-Type": "application/json",
                    'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
                    'Accept': 'application/json'
                },
                body: JSON.stringify(params)
            })
            .then(response => response.json())
            .then(data => {

                this.distributionChart.data = data.distributionData;
                this.distributionChart.update();
            })
            .catch(error => {
                console.error('Error fetching cash flow data:', error);
            });
        }, 300);
    }

}