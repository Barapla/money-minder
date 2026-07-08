import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "typeSelect",
    "transactionsCountField",
    "transactionsCountInput",
    "amountPerTransactionField",
    "amountPerTransactionInput",
    "accumulatedAmountField",
    "accumulatedAmountInput",
    "monthlyFeeField",
    "monthlyFeeInput"
  ]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const type = this.typeSelectTarget.value

    const showTransactionsCount = type === "min_transactions" || type === "min_transactions_with_amount"
    const showAmountPerTransaction = type === "min_transactions_with_amount"
    const showAccumulatedAmount = type === "accumulated_amount"
    const showMonthlyFee = type === "monthly_fee"

    this.#toggleField(this.transactionsCountFieldTarget, this.transactionsCountInputTarget, showTransactionsCount)
    this.#toggleField(this.amountPerTransactionFieldTarget, this.amountPerTransactionInputTarget, showAmountPerTransaction)
    this.#toggleField(this.accumulatedAmountFieldTarget, this.accumulatedAmountInputTarget, showAccumulatedAmount)
    this.#toggleField(this.monthlyFeeFieldTarget, this.monthlyFeeInputTarget, showMonthlyFee)
  }

  #toggleField(fieldEl, inputEl, show) {
    if (show) {
      fieldEl.classList.remove("hidden")
      inputEl.required = true
    } else {
      fieldEl.classList.add("hidden")
      inputEl.required = false
      inputEl.value = ""
    }
  }
}
