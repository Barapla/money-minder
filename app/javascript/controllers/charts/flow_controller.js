import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

// Connects to data-controller="charts--flow"
export default class extends Controller {
    static targets = ["canvas", "periodButtons"]
    static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Array, // Data for the chart
        url: String // URL for fetching data
    }
    static outlets = ["charts--main"]

    flowChart = null
    currentFlowPeriod = 'monthly';

  connect() {
    this.initializeChart();
  }

  initializeChart() {
    const ctx = this.canvasTarget.getContext('2d');
    this.flowChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['Ene', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
            datasets: this.datasetsValue
        },
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

  // Cash flow period buttons
  setFlowPeriod({ params: { period } }) {
    console.log(`Setting cash flow period to: ${period}`);
      this.currentFlowPeriod = period;
      
      // Update button styles
      this.periodButtonsTargets.forEach(btn => {
          btn.className = 'px-3 py-1 text-sm text-bunker-400 hover:text-white border border-bunker-700 rounded-lg hover:bg-bunker-700/50';
      });
      
      document.getElementById(period + 'Btn').className = 'px-3 py-1 text-sm bg-purple-500 text-white rounded-lg';
      
      this.updateChart();
  }

  updateChart() {
        console.log('updateChart called'); // Debug
        
        let filters = null;
        
        if (this.hasChartsMainOutlet) {
            filters = this.chartsMainOutlet.getFilters();
            filters.period = this.currentFlowPeriod; // Usar el período actual
        } else {
            // Fallback: usar valores por defecto o del período actual
            filters = {
                start_date: '',
                end_date: '',
                period: this.currentFlowPeriod
            };
        }

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
                console.log('Cash flow data fetched:', data);
                
                this.flowChart.data.labels = data.labels;
                this.flowChart.data.datasets[0].data = data.incomeData;
                this.flowChart.data.datasets[1].data = data.expenseData;
                this.flowChart.update();
            })
            .catch(error => {
                console.error('Error fetching cash flow data:', error);
            });
        }, 300);
    }
}