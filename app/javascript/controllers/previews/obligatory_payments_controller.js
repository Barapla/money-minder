import PreviewBaseController from "./base_controller"

// Connects to data-controller="previews--obligatory-payments"
export default class extends PreviewBaseController {
  static targets = [
    ...PreviewBaseController.targets,
    "amount", "previewAmount",
    "frequency", "previewFrequency",
    "frequencyValue", "startDate", "previewNextDate",
    "oneTime", "recurrenceFields", "dueDateWrapper"
  ]

  connect() {
    this.toggleRecurrence()
  }

  toggleRecurrence() {
    const isOneTime = this.oneTimeTarget.checked
    this.recurrenceFieldsTarget.classList.toggle("hidden", isOneTime)
    this.dueDateWrapperTarget.classList.toggle("hidden", !isOneTime)
  }

  updateAmount(event) {
    this.previewAmountTarget.textContent = `-$${this.amountTarget.value ? parseFloat(this.amountTarget.value).toFixed(2) : "0.00"}`;
  }

  updateFrequency(event) {
    this.previewFrequencyTarget.textContent = this.frequencyTarget.selectedOptions[0].textContent || "Diaria";
    this.updateNextDate();
  }

  updateNextDate(event) {
    const frequencyType = this.frequencyTarget.selectedOptions[0].textContent.toLowerCase();
    const frequencyValue = parseInt(this.frequencyValueTarget.value) || 1;
    const startDate = new Date(this.startDateTarget.value);
    
    // Ajustar timezone
    startDate.setMinutes(startDate.getMinutes() + startDate.getTimezoneOffset());
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let nextDate = new Date(startDate == "Invalid Date" ? today : startDate);

    if (frequencyType === "diaria" || frequencyType === "daily") {
      while (nextDate <= today) {
        nextDate.setDate(nextDate.getDate() + frequencyValue);
      }
    } else if (frequencyType === "semanal" || frequencyType === "weekly") {
      while (nextDate <= today) {
        nextDate.setDate(nextDate.getDate() + (7 * frequencyValue));
      }
    } else if (frequencyType === "mensual" || frequencyType === "monthly") {
      while (nextDate <= today) {
        nextDate.setMonth(nextDate.getMonth() + frequencyValue);
      }
    } else if (frequencyType === "anual" || frequencyType === "yearly") {
      while (nextDate <= today) {
        nextDate.setFullYear(nextDate.getFullYear() + frequencyValue);
      }
    }

    this.previewNextDateTarget.textContent = nextDate.toLocaleDateString('en-US');
  }

}