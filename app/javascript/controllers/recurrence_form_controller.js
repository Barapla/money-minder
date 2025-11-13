import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frequencySelect", "dayOfWeek", "dayOfMonth", "monthOfYear"]
  static values = {
    daily: Number,
    weekly: Number,
    monthly: Number,
    yearly: Number
  }

  connect() {
    console.log('Recurrence form controller connected')
    console.log('Values:', { daily: this.dailyValue, weekly: this.weeklyValue, monthly: this.monthlyValue, yearly: this.yearlyValue })
    this.updateFields()
  }

  updateFields(event) {
    console.log('updateFields called')
    const selectedId = parseInt(this.frequencySelectTarget.value)
    console.log('Selected frequency ID:', selectedId)

    // Hide all conditional fields first and clear their values
    this.hideField(this.dayOfWeekTarget)
    this.hideField(this.dayOfMonthTarget)
    if (this.hasMonthOfYearTarget) {
      this.hideField(this.monthOfYearTarget)
    }

    // Show appropriate fields based on frequency type
    if (selectedId === this.weeklyValue) {
      // Weekly: show day_of_week
      console.log('Showing day_of_week')
      this.showField(this.dayOfWeekTarget)
    } else if (selectedId === this.monthlyValue) {
      // Monthly: show day_of_month
      console.log('Showing day_of_month')
      this.showField(this.dayOfMonthTarget)
    } else if (selectedId === this.yearlyValue) {
      // Yearly: show day_of_month and month_of_year
      console.log('Showing day_of_month and month_of_year')
      this.showField(this.dayOfMonthTarget)
      if (this.hasMonthOfYearTarget) {
        this.showField(this.monthOfYearTarget)
      }
    }
    // Daily: no special fields needed
  }

  showField(element) {
    element.classList.remove('hidden')
    // Enable the input/select
    const input = element.querySelector('input, select')
    if (input) {
      input.disabled = false
      input.required = true
    }
  }

  hideField(element) {
    element.classList.add('hidden')
    // Clear and disable the input/select
    const input = element.querySelector('input, select')
    if (input) {
      input.value = ''
      input.disabled = true
      input.required = false
    }
  }
}
