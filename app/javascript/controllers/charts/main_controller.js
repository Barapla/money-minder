import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts--main"
export default class extends Controller {
    static targets = ["startDate", "endDate", "budgets", "periodButtons", "incomeData", "expenseData", "balanceData", "noTransactions"]
    static outlets = ["charts--flow", "charts--distribution", "charts--comparison"] // Usar el nombre específico del controlador hijo
    static values = {
        url: String // URL for fetching data
    }

    updateAllCharts() {
        // Lógica para actualizar todos los gráficos
        this.chartsDistributionOutlets.forEach(outlet => {
            if (outlet.distributionChart) {
                outlet.updateChart();
            }
        });

        this.chartsFlowOutlets.forEach(outlet => {
            if (outlet.flowChart) {
                outlet.updateChart();
            }
        });

        this.chartsComparisonOutlets.forEach(outlet => {
            if (outlet.comparisonChart) {
                outlet.updateChart();
            }
        });

        this.updateMainData();
    }

    updateMainData() {
        let filters = this.getFilters();

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
                this.incomeDataTarget.textContent = this.formatCurrency(data.reportData.incomeData);
                this.expenseDataTarget.textContent = this.formatCurrency(data.reportData.expenseData);
                this.balanceDataTarget.textContent = this.formatCurrency(data.reportData.balanceData);
                this.noTransactionsTarget.textContent = data.reportData.noTransactions;
            })
            .catch(error => {
                console.error('Error fetching cash flow data:', error);
            });
        }, 300);
    }

    setFastPeriod({ params: { period } }) {
        if (period === '1M') {
            this.setLastMonth();
        }
        else if (period === '3M') {
            this.setLast3Months();
        }
        else if (period === '6M') {
            this.setLast6Months();
        }
        else if (period === '1Y') {
            this.setLastYear();
        }
        
        this.periodButtonsTargets.forEach(button => {
            button.classList.remove('bg-purple-500', 'text-white', 'border-purple-500');
            button.classList.add('bg-bunker-800/60', 'text-bunker-300', 'border-bunker-700/50');
        });
        const activeButton = this.periodButtonsTargets.find(button => button.dataset['charts-MainPeriodParam'] === period);
        if (activeButton) {
            activeButton.classList.add('bg-purple-500', 'text-white', 'border-purple-500');
            activeButton.classList.remove('bg-bunker-800/60', 'text-bunker-300', 'border-bunker-700/50');
        }

        this.updateAllCharts();
    }

    setLastMonth() {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1);
        this.startDateTarget.value = startDate.toISOString().split('T')[0];
        this.endDateTarget.value = endDate.toISOString().split('T')[0];
    }

    setLast3Months() {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 3);
        this.startDateTarget.value = startDate.toISOString().split('T')[0];
        this.endDateTarget.value = endDate.toISOString().split('T')[0];
    }

    setLast6Months() {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 6);
        this.startDateTarget.value = startDate.toISOString().split('T')[0];
        this.endDateTarget.value = endDate.toISOString().split('T')[0];
    }

    setLastYear() {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setFullYear(startDate.getFullYear() - 1);
        this.startDateTarget.value = startDate.toISOString().split('T')[0];
        this.endDateTarget.value = endDate.toISOString().split('T')[0];
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
            budgets: this.budgetsTarget.value ? this.budgetsTarget.value.split(',') : []
        };
        return filters;
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(amount);
    }

}