import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

// Connects to data-controller="charts--flow"
export default class extends Controller {
    static targets = ["canvas", "periodButtons"]
    static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Array // Data for the chart
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
        
        this.chartsMainOutlet.updateAllCharts();
    }
}