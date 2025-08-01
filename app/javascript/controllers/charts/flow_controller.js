import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--flow"
export default class extends Controller {
    static targets = ["canvas", "periodButtons"]
    static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Array, // Data for the chart
        url: String // URL for fetching data
    }
    flowChart = null
    currentFlowPeriod = 'monthly';

  connect() {
    this.initializeChart();
    this.element.addEventListener("dashboard:updateCharts", this.updateChart.bind(this))
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
      
      this.updateChart(period);
  }

  updateChart(period) {
    // Update cash flow chart based on current period
    let labels, incomeData, expenseData;
    
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      // Evita que el formulario se envíe de la manera tradicional      
        const url = this.urlValue + `?period=${period}`;

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
            // Assuming data contains the labels and datasets for income and expenses
            labels = data.labels;
            incomeData = data.incomeData;
            expenseData = data.expenseData;

            this.flowChart.data.labels = labels;
            this.flowChart.data.datasets[0].data = incomeData;
            this.flowChart.data.datasets[1].data = expenseData;
            this.flowChart.update();
        })
        .catch(error => {
            console.error('Error fetching cash flow data:', error);
        });
    }, 300)
  }
}