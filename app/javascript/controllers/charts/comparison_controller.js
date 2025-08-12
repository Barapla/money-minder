import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

// Connects to data-controller="charts--budget-comparison"
export default class extends Controller {
    static targets = ["canvas", "dropdown", "checkboxes"]
     static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Object, // Data for the chart
        url: String // URL for fetching data if needed
    }
    static outlets = ["charts--main"]
    comparisonChart = null

    connect() {
        this.initializeChart();
    }

    // Budget Comparison Chart
    initializeChart() {
        const ctx = this.canvasTarget.getContext('2d');
        this.comparisonChart = new Chart(ctx, {
            type: 'bar',
            data: this.datasetsValue,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#d1d5db'
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#9ca3af',
                            callback: function(value) {
                                return '' + value.toLocaleString();
                            }
                        }
                    },
                    x: {
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#9ca3af'
                        }
                    }
                }
            }
        });
    }

    updateChart() {
        let filters = this.chartsMainOutlet.getFilters();
        
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
                this.comparisonChart.data = data.comparisonData;
                this.comparisonChart.update();
            })
            .catch(error => {
                console.error('Error fetching cash flow data:', error);
            });
        }, 300);
    }

}