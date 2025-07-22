import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recurring-transaction-form"
export default class extends Controller {
  static targets = [
        "description", "amount", "frequency", "startDate", "endDate", "maxExecutions",
        "previewDescription", "previewAmount", "previewFrequency", "previewAnnualTotal", "previewSchedule"]

    connect() {
        this.updatePreview();
    }

    updatePreview() {
        const description = this.descriptionTarget.value || 'Nueva transacción recurrente';
        const amount = parseFloat(this.amountTarget.value) || 0;
        const frequency = this.frequencyTarget.value;
        
        this.previewDescriptionTarget.textContent = description;
        this.previewAmountTarget.textContent = `$${amount.toFixed(2)}`;
        this.previewFrequencyTarget.textContent = this.getFrequencyLabel(frequency);
        
        const annualTotal = this.calculateAnnualTotal(amount, frequency);
        this.previewAnnualTotalTarget.textContent = `${annualTotal.toFixed(2)}`;
        
        this.updateSchedulePreview();
    }

    updateFrequency() {
        this.updatePreview();
    }

    calculateAnnualTotal(amount, frequency) {
        const multipliers = {
            'daily': 365,
            'weekly': 52,
            'bi_weekly': 26,
            'monthly': 12,
            'bi_monthly': 6,
            'quarterly': 4,
            'semi_annually': 2,
            'annually': 1
        };
        
        return amount * (multipliers[frequency] || 0);
    }

    getFrequencyLabel(frequency) {
        const labels = {
            'daily': 'Diario',
            'weekly': 'Semanal',
            'bi_weekly': 'Quincenal',
            'monthly': 'Mensual',
            'bi_monthly': 'Bimestral',
            'quarterly': 'Trimestral',
            'semi_annually': 'Semestral',
            'annually': 'Anual'
        };
        
        return labels[frequency] || '-';
    }

    updateSchedulePreview() {
        const startDate = this.startDateTarget.value;
        const frequency = this.frequencyTarget.value;
        let maxExecutions = parseInt(this.maxExecutionsTarget.value) || 5;

        if (maxExecutions > 5)
        {
            maxExecutions = 5;
        }

        if (!startDate || !frequency) {
            this.previewScheduleTarget.innerHTML = '<div class="text-bunker-400">Selecciona fecha de inicio y frecuencia</div>';
            return;
        }

        const dates = this.calculateNextDates(startDate, frequency, maxExecutions);
        const html = dates.map((date, index) => {
            const dateStr = new Date(date).toLocaleDateString('es-ES', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric' 
            });
            const isFirst = index === 0;
            const colorClass = isFirst ? 'text-purple-400' : 'text-bunker-300';
            const label = isFirst ? '(Primera ejecución)' : '';
            
            return `<div class="flex justify-between ${colorClass}">
                <span>${dateStr}</span>
                <span class="text-xs">${label}</span>
            </div>`;
        }).join('');
        
        this.previewScheduleTarget.innerHTML = html;
    }

    calculateNextDates(startDate, frequency, count) {
        const dates = [];
        let currentDate = this.createLocalDate(startDate); // Usa la función helper aquí también
    
        for (let i = 0; i < count; i++) {
            dates.push(new Date(currentDate));
            currentDate = this.addFrequency(currentDate, frequency);
        }
        
        return dates;
    }

    addFrequency(date, frequency) {
        const newDate = this.createLocalDate(date); // Usa la función helper
    
        switch (frequency) {
            case 'daily':
                newDate.setDate(newDate.getDate() + 1);
                break;
            case 'weekly':
                newDate.setDate(newDate.getDate() + 7);
                break;
            case 'bi_weekly':
                newDate.setDate(newDate.getDate() + 14);
                break;
            case 'monthly':
                newDate.setMonth(newDate.getMonth() + 1);
                break;
            case 'bi_monthly':
                newDate.setMonth(newDate.getMonth() + 2);
                break;
            case 'quarterly':
                newDate.setMonth(newDate.getMonth() + 3);
                break;
            case 'semi_annually':
                newDate.setMonth(newDate.getMonth() + 6);
                break;
            case 'annually':
                newDate.setFullYear(newDate.getFullYear() + 1);
                break;
        }
        
        return newDate;
    }

    // Agrega esta función helper
    createLocalDate(dateInput) {
        if (dateInput instanceof Date) {
            return new Date(dateInput);
        }
        
        if (typeof dateInput === 'string') {
            // Si es string tipo "2025-07-22", parsearlo como fecha local
            const [year, month, day] = dateInput.split('-').map(Number);
            return new Date(year, month - 1, day); // month - 1 porque es 0-indexado
        }
        
        return new Date(dateInput);
    }
}
