import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "row"]

  addRow() {
    const newRow = this.buildEmptyRow()
    this.containerTarget.appendChild(newRow)
  }

  removeRow(event) {
    const row = event.target.closest('[data-bonus-manager-target="row"]')
    if (this.rowTargets.length > 1) {
      row?.remove()
    } else {
      row?.querySelectorAll('input').forEach(input => { input.value = '' })
    }
  }

  buildEmptyRow() {
    const div = document.createElement('div')
    div.setAttribute('data-bonus-manager-target', 'row')
    div.className = 'grid items-center gap-3'
    div.style.gridTemplateColumns = '1fr 9rem 2.25rem'
    div.innerHTML = `
      <input type="text" name="payroll_profile[bonus_names][]"
             placeholder="Ej: Transporte"
             class="w-full bg-bunker-800/60 border border-bunker-700/50 rounded-lg px-4 py-2.5 text-white text-sm placeholder-bunker-500 focus:outline-none focus:border-purple-500/50 focus:ring-1 focus:ring-purple-500/20">
      <input type="number" name="payroll_profile[bonus_amounts][]"
             step="0.01" min="0" placeholder="0.00"
             class="w-full bg-bunker-800/60 border border-bunker-700/50 rounded-lg px-4 py-2.5 text-white text-sm placeholder-bunker-500 focus:outline-none focus:border-purple-500/50 focus:ring-1 focus:ring-purple-500/20">
      <button type="button" data-action="bonus-manager#removeRow"
              class="w-9 h-9 flex items-center justify-center text-bunker-400 hover:text-red-400 border border-bunker-700/50 hover:border-red-500/40 rounded-lg transition-colors">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    `
    return div
  }
}
