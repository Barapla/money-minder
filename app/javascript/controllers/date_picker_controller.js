import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="date-picker"
export default class extends Controller {
    static targets = ["input", "hidden", "calendar", "monthYear", "daysGrid"]

    connect() {
        this.currentDate = new Date();
        this.selectedDate = null;
        this.updateDisplay();
        
        // Close calendar when clicking outside
        document.addEventListener('click', this.closeOnOutsideClick.bind(this));
    }

    disconnect() {
        document.removeEventListener('click', this.closeOnOutsideClick.bind(this));
    }

    toggle(event) {
        event.stopPropagation();
        this.calendarTarget.classList.toggle('hidden');
        
        if (!this.calendarTarget.classList.contains('hidden')) {
            this.updateCalendar();
        }
    }

    closeOnOutsideClick(event) {
        if (!this.element.contains(event.target)) {
            this.calendarTarget.classList.add('hidden');
        }
    }

    previousMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.updateCalendar();
    }

    nextMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.updateCalendar();
    }

    selectDate(event) {
        const dateStr = event.target.dataset.date;
        this.selectedDate = new Date(dateStr);
        
        // Update displays
        this.inputTarget.value = this.formatDisplayDate(this.selectedDate);
        this.hiddenTarget.value = this.formatInputDate(this.selectedDate);
        
        // Update visual selection
        this.updateSelectedDay();
        
        // Close calendar
        this.calendarTarget.classList.add('hidden');
    }

    today() {
        const today = new Date();
        this.currentDate = new Date(today);
        this.selectedDate = today;
        
        this.inputTarget.value = this.formatDisplayDate(today);
        this.hiddenTarget.value = this.formatInputDate(today);
        
        this.updateCalendar();
        this.calendarTarget.classList.add('hidden');
    }

    clear() {
        this.selectedDate = null;
        this.inputTarget.value = '';
        this.hiddenTarget.value = '';
        this.updateSelectedDay();
        this.calendarTarget.classList.add('hidden');
    }

    updateDisplay() {
        const monthNames = [
            'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        
        this.monthYearTarget.textContent = 
            `${monthNames[this.currentDate.getMonth()]} ${this.currentDate.getFullYear()}`;
    }

    updateCalendar() {
        this.updateDisplay();
        this.generateCalendarDays();
        this.updateSelectedDay();
    }

    generateCalendarDays() {
        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();
        
        // First day of the month and how many days in month
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const startDate = new Date(firstDay);
        startDate.setDate(startDate.getDate() - firstDay.getDay());
        
        this.daysGridTarget.innerHTML = '';
        
        // Generate 42 days (6 weeks)
        for (let i = 0; i < 42; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            
            const button = document.createElement('button');
            button.type = 'button';
            button.textContent = date.getDate();
            button.dataset.date = this.formatInputDate(date);
            button.dataset.action = 'click->date-picker#selectDate';
            
            // Styling
            button.className = 'text-sm p-2 hover:bg-bunker-800/50 rounded-lg transition-colors';
            
            if (date.getMonth() !== month) {
                button.className += ' text-bunker-500';
            } else {
                button.className += ' text-white';
            }
            
            // Highlight today
            const today = new Date();
            if (this.isSameDay(date, today)) {
                button.className += ' bg-purple-500 font-semibold';
            }
            
            this.daysGridTarget.appendChild(button);
        }
    }

    updateSelectedDay() {
        // Remove previous selection
        this.daysGridTarget.querySelectorAll('.bg-purple-600').forEach(btn => {
            btn.classList.remove('bg-purple-600');
            btn.classList.add('hover:bg-bunker-800/50');
        });
        
        // Add selection to current date
        if (this.selectedDate) {
            const selectedDateStr = this.formatInputDate(this.selectedDate);
            const selectedButton = this.daysGridTarget.querySelector(`[data-date="${selectedDateStr}"]`);
            if (selectedButton) {
                selectedButton.classList.add('bg-purple-600');
                selectedButton.classList.remove('hover:bg-bunker-800/50');
            }
        }
    }

    formatDisplayDate(date) {
        return date.toLocaleDateString('es-ES', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    formatInputDate(date) {
        return date.toISOString().split('T')[0];
    }

    isSameDay(date1, date2) {
        return date1.getFullYear() === date2.getFullYear() &&
                date1.getMonth() === date2.getMonth() &&
                date1.getDate() === date2.getDate();
    }
}
