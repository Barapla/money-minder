// app/javascript/controllers/form_validator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "error"]
  static values = { 
    validateOnBlur: { type: Boolean, default: true },
    validateOnInput: { type: Boolean, default: false }
  }

  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Validar al enviar el formulario
    this.element.addEventListener('submit', this.validateForm.bind(this))
    
    // Validar campos individualmente
    this.fieldTargets.forEach(field => {
      if (this.validateOnBlurValue) {
        field.addEventListener('blur', () => this.validateField(field))
      }
      
      if (this.validateOnInputValue) {
        field.addEventListener('input', () => this.validateField(field))
      }
    })
  }

  validateForm(event) {
    let isValid = true
    
    this.fieldTargets.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      event.stopPropagation()
      
      // Hacer scroll al primer campo con error
      const firstErrorField = this.element.querySelector('.form-control-error')
      if (firstErrorField) {
        firstErrorField.scrollIntoView({ behavior: 'smooth', block: 'center' })
        firstErrorField.focus()
      }
    }
  }

  validateField(field) {
    const fieldId = field.id || field.name
    const value = field.value.trim()
    const isRequired = field.hasAttribute('required') || field.dataset.required === 'true'
    
    let isValid = true
    let errorMessage = ''

    // Validar campos requeridos
    if (isRequired && value === '') {
      isValid = false
      errorMessage = this.getRequiredMessage(field)
    }

    // Validaciones específicas por tipo de campo
    if (isValid && value !== '') {
      const validation = this.getFieldValidation(field, value)
      isValid = validation.isValid
      errorMessage = validation.message
    }

    // Validaciones personalizadas
    if (isValid && value !== '') {
      const customValidation = this.getCustomValidation(field, value)
      isValid = customValidation.isValid
      errorMessage = customValidation.message
    }

    this.updateFieldUI(field, isValid, errorMessage)
    return isValid
  }

  getFieldValidation(field, value) {
    switch (field.type) {
      case 'email':
        return this.validateEmail(value)
      case 'tel':
        return this.validatePhone(value)
      case 'number':
        return this.validateNumber(field, value)
      case 'url':
        return this.validateUrl(value)
      default:
        return { isValid: true, message: '' }
    }
  }

  getCustomValidation(field, value) {
    // Validar longitud mínima
    if (field.dataset.minLength) {
      const minLength = parseInt(field.dataset.minLength)
      if (value.length < minLength) {
        return {
          isValid: false,
          message: `Debe tener al menos ${minLength} caracteres`
        }
      }
    }

    // Validar longitud máxima
    if (field.dataset.maxLength) {
      const maxLength = parseInt(field.dataset.maxLength)
      if (value.length > maxLength) {
        return {
          isValid: false,
          message: `No debe exceder ${maxLength} caracteres`
        }
      }
    }

    // Validar patrón personalizado
    if (field.dataset.pattern) {
      const pattern = new RegExp(field.dataset.pattern)
      if (!pattern.test(value)) {
        return {
          isValid: false,
          message: field.dataset.patternMessage || 'Formato no válido'
        }
      }
    }

    return { isValid: true, message: '' }
  }

  validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return {
      isValid: emailRegex.test(email),
      message: 'Ingresa un email válido'
    }
  }

  validatePhone(phone) {
    const phoneRegex = /^[\+]?[\d\s\-\(\)]{10,}$/
    return {
      isValid: phoneRegex.test(phone),
      message: 'Ingresa un teléfono válido'
    }
  }

  validateNumber(field, value) {
    const num = parseFloat(value)
    
    if (isNaN(num)) {
      return { isValid: false, message: 'Ingresa un número válido' }
    }

    // Validar mínimo
    if (field.dataset.min && num < parseFloat(field.dataset.min)) {
      return {
        isValid: false,
        message: `El valor mínimo es ${field.dataset.min}`
      }
    }

    // Validar máximo
    if (field.dataset.max && num > parseFloat(field.dataset.max)) {
      return {
        isValid: false,
        message: `El valor máximo es ${field.dataset.max}`
      }
    }

    return { isValid: true, message: '' }
  }

  validateUrl(url) {
    try {
      new URL(url)
      return { isValid: true, message: '' }
    } catch {
      return { isValid: false, message: 'Ingresa una URL válida' }
    }
  }

  getRequiredMessage(field) {
    return field.dataset.requiredMessage || 'Este campo es requerido'
  }

  updateFieldUI(field, isValid, errorMessage) {
    const fieldGroup = field.closest('.form-group')
    const errorContainer = fieldGroup?.querySelector('[data-error-container]')
    const errorText = fieldGroup?.querySelector('[data-error-text]')
    const helpText = fieldGroup?.querySelector('[data-help-text]')
    const icon = fieldGroup?.querySelector('[data-field-icon]')
    const prefix = fieldGroup?.querySelector('[data-field-prefix]')
    const suffix = fieldGroup?.querySelector('[data-field-suffix]')

    if (isValid) {
      // Remover clase de error
      field.classList.remove('form-control-error')
      fieldGroup?.classList.remove('has-error')
      
      // Ocultar mensaje de error
      errorContainer?.classList.add('hidden')
      helpText?.classList.remove('hidden')
      
      // Restaurar colores originales
      this.updateElementColor(icon, false)
      this.updateElementColor(prefix, false)
      this.updateElementColor(suffix, false)
    } else {
      // Agregar clase de error
      field.classList.add('form-control-error')
      fieldGroup?.classList.add('has-error')
      
      // Mostrar mensaje de error
      if (errorText) errorText.textContent = errorMessage
      errorContainer?.classList.remove('hidden')
      helpText?.classList.add('hidden')
      
      // Cambiar colores a rojo
      this.updateElementColor(icon, true)
      this.updateElementColor(prefix, true)
      this.updateElementColor(suffix, true)
    }
  }

  updateElementColor(element, isError) {
    if (!element) return
    
    if (isError) {
      element.classList.remove('text-bunker-400')
      element.classList.add('text-red-400')
    } else {
      element.classList.remove('text-red-400')
      element.classList.add('text-bunker-400')
    }
  }

  // Métodos públicos que pueden ser llamados desde otros controllers
  validate() {
    return this.fieldTargets.every(field => this.validateField(field))
  }

  clearErrors() {
    this.fieldTargets.forEach(field => {
      this.updateFieldUI(field, true, '')
    })
  }
}