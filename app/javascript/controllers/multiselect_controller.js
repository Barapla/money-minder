// app/javascript/controllers/multiselect_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dropdown", "trigger", "placeholder", "searchInput", "optionsList", "option", "hiddenInput", "chevron", "counter"]
    static values = { 
        name: String,
        placeholder: String,
        selected: Array,
        options: Array,
        searchable: Boolean
    }
    
    connect() {
        this.selectedValues = new Set(this.selectedValue)
        
        // Cerrar dropdown al hacer click fuera
        this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
        document.addEventListener('click', this.boundHandleOutsideClick)
        
        // Inicializar estado
        this.updatePlaceholder()
        this.updateCounter()
        this.updateHiddenInput()
    }
    
    disconnect() {
        document.removeEventListener('click', this.boundHandleOutsideClick)
    }
    
    toggle(event) {
        event.preventDefault()
        event.stopPropagation()
        
        const isHidden = this.dropdownTarget.classList.contains('hidden')
        
        if (isHidden) {
            this.openDropdown()
        } else {
            this.closeDropdown()
        }
    }
    
    openDropdown() {
        this.dropdownTarget.classList.remove('hidden')
        this.chevronTarget.style.transform = 'rotate(180deg)'
        
        if (this.searchableValue && this.hasSearchInputTarget) {
            setTimeout(() => {
                this.searchInputTarget.focus()
            }, 10)
        }
        
        this.dispatch("opened")
    }
    
    closeDropdown() {
        this.dropdownTarget.classList.add('hidden')
        this.chevronTarget.style.transform = 'rotate(0deg)'
        
        if (this.hasSearchInputTarget) {
            this.searchInputTarget.value = ''
            this.filterOptions({ target: { value: '' } })
        }
        
        this.dispatch("closed")
    }
    
    handleOutsideClick(event) {
        if (!this.element.contains(event.target)) {
            this.closeDropdown()
        }
    }
    
    selectOption(event) {
        const checkbox = event.target
        const value = checkbox.dataset.value
        const optionElement = checkbox.closest('[data-multiselect-target="option"]')
        const text = optionElement.dataset.text
        
        if (checkbox.checked) {
            this.selectedValues.add(value)
        } else {
            this.selectedValues.delete(value)
        }
        
        this.updateComponent()
        
        this.dispatch("selectionChanged", { 
            detail: { 
                selectedValues: Array.from(this.selectedValues),
                action: checkbox.checked ? 'add' : 'remove',
                value: value,
                text: text
            } 
        })
    }
    
    removeTag(event) {
        event.preventDefault()
        event.stopPropagation()
        
        const value = event.currentTarget.dataset.value
        
        // Desmarcar checkbox correspondiente
        const checkbox = this.element.querySelector(`input[data-value="${value}"]`)
        if (checkbox) checkbox.checked = false
        
        this.selectedValues.delete(value)
        this.updateComponent()
        
        this.dispatch("selectionChanged", { 
            detail: { 
                selectedValues: Array.from(this.selectedValues),
                action: 'remove',
                value: value
            } 
        })
    }
    
    clearAll(event) {
        event.preventDefault()
        event.stopPropagation()
        
        // Desmarcar todos los checkboxes
        this.element.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = false)
        
        this.selectedValues.clear()
        this.updateComponent()
        
        this.dispatch("cleared")
    }
    
    updateComponent() {
        this.updatePlaceholder()
        this.updateCounter()
        this.updateHiddenInput()
    }
    
    updatePlaceholder() {
        const count = this.selectedValues.size
        if (count === 0) {
            this.placeholderTarget.textContent = this.placeholderValue
            this.placeholderTarget.classList.add('text-bunker-400')
            this.placeholderTarget.classList.remove('text-bunker-300')
        } else {
            this.placeholderTarget.textContent = `${count} opción${count !== 1 ? 'es' : ''} seleccionada${count !== 1 ? 's' : ''}`
            this.placeholderTarget.classList.remove('text-bunker-400')
            this.placeholderTarget.classList.add('text-bunker-300')
        }
    }
    
    updateCounter() {
        if (this.hasCounterTarget) {
            const count = this.selectedValues.size
            this.counterTarget.textContent = `${count} seleccionado${count !== 1 ? 's' : ''}`
        }
    }
    
    updateHiddenInput() {
        this.hiddenInputTarget.value = Array.from(this.selectedValues).join(',')

        // Disparar evento change manualmente
        this.hiddenInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }
    
    filterOptions(event) {
        if (!this.searchableValue) return
        
        const searchTerm = event.target.value.toLowerCase()
        
        this.optionTargets.forEach(option => {
            const text = option.dataset.text.toLowerCase()
            const matches = text.includes(searchTerm)
            option.style.display = matches ? 'flex' : 'none'
        })
        
        // Mostrar mensaje si no hay resultados
        const visibleOptions = this.optionTargets.filter(option => option.style.display !== 'none')
        if (visibleOptions.length === 0 && searchTerm.length > 0) {
            this.showNoResultsMessage()
        } else {
            this.hideNoResultsMessage()
        }
    }
    
    showNoResultsMessage() {
        if (!this.element.querySelector('.no-results-message')) {
            const message = document.createElement('div')
            message.className = 'no-results-message px-4 py-3 text-center text-bunker-400 text-sm'
            message.textContent = 'No se encontraron opciones'
            this.optionsListTarget.appendChild(message)
        }
    }
    
    hideNoResultsMessage() {
        const message = this.element.querySelector('.no-results-message')
        if (message) {
            message.remove()
        }
    }
    
    // Métodos públicos
    setValues(values) {
        this.clearAll({ preventDefault: () => {}, stopPropagation: () => {} })
        
        values.forEach(value => {
            const checkbox = this.element.querySelector(`input[data-value="${value}"]`)
            if (checkbox) {
                checkbox.checked = true
                this.selectedValues.add(value)
            }
        })
        
        this.updateComponent()
    }
    
    getSelectedValues() {
        return Array.from(this.selectedValues)
    }
    
    getSelectedTexts() {
        return Array.from(this.selectedValues).map(value => {
            const option = this.optionsValue.find(opt => opt.value === value)
            return option ? option.text : value
        })
    }
}