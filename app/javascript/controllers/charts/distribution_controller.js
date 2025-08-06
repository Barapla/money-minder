import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

// Connects to data-controller="charts--category-distribution"
export default class extends Controller {
    static targets = ["canvas"]
    static values = { 
        id: String,  // Unique ID for the chart instance
        datasets: Object // Data for the chart
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
}