import { Controller } from "@hotwired/stimulus"
import { accountVisible, zerosSummaryVisible } from "../lib/account_visibility"

// Único dueño de qué cuenta se ve: búsqueda por nombre, chips por tipo, toggle
// de "solo con saldo" y orden. Las cuentas en ceros solo aparecen cuando el
// grupo las reveló (data-revealed) y el filtro no las descarta.
export default class extends Controller {
  static targets = ["account", "group", "search", "onlyFunded", "empty", "chip", "sort", "zerosCard"]

  connect() {
    this.type = "all"
    this.onReveal = () => this.apply()
    this.element.addEventListener("reveal:toggled", this.onReveal)
    this.apply()
  }

  disconnect() {
    this.element.removeEventListener("reveal:toggled", this.onReveal)
  }

  selectType(event) {
    this.type = event.currentTarget.dataset.type
    this.chipTargets.forEach((chip) => {
      const active = chip.dataset.type === this.type
      chip.classList.toggle("bg-purple-500", active)
      chip.classList.toggle("text-white", active)
      chip.classList.toggle("bg-bunker-900/50", !active)
      chip.classList.toggle("text-bunker-300", !active)
    })
    this.apply()
  }

  apply() {
    const term = (this.hasSearchTarget ? this.searchTarget.value : "").trim().toLowerCase()
    const state = {
      term,
      onlyFunded: this.hasOnlyFundedTarget && this.onlyFundedTarget.checked,
      selectedType: this.type
    }
    let visible = 0

    this.accountTargets.forEach((el) => {
      const show = accountVisible(
        {
          name: el.dataset.name || "",
          type: el.dataset.type,
          zero: el.dataset.zero === "true",
          revealed: el.dataset.revealed === "true"
        },
        state
      )
      el.classList.toggle("hidden", !show)
      if (show) visible += 1
    })

    this.#sortAccounts()

    this.zerosCardTargets.forEach((el) => el.classList.toggle("hidden", !zerosSummaryVisible(state)))

    // Un grupo donde todo esta en ceros solo muestra su tarjeta-resumen: si se
    // ocultara la seccion entera, el boton para desplegarlas quedaria inalcanzable.
    this.groupTargets.forEach((group) => {
      const any = group.querySelectorAll(
        '[data-budget-filters-target="account"]:not(.hidden), [data-budget-filters-target="zerosCard"]:not(.hidden)'
      ).length > 0
      group.classList.toggle("hidden", !any)
    })

    if (this.hasEmptyTarget) this.emptyTarget.classList.toggle("hidden", visible > 0)
  }

  // Reordena dentro de cada contenedor: por saldo descendente o por nombre. Las
  // cuentas ocupan un bloque contiguo con vecinos que NO se reordenan (el
  // encabezado de la tabla antes, la fila-resumen y el pie despues), asi que se
  // reinsertan contra el vecino de la derecha en vez de appendChild, que las
  // mandaria al final del contenedor y dejaria el resumen y el pie hasta arriba.
  #sortAccounts() {
    const by = this.hasSortTarget ? this.sortTarget.value : "balance"
    const containers = new Set(this.accountTargets.map((el) => el.parentElement))
    containers.forEach((container) => {
      const rows = Array.from(container.children).filter((el) => el.dataset.name !== undefined)
      if (rows.length < 2) return

      const anchor = rows[rows.length - 1].nextSibling
      rows
        .sort((a, b) =>
          by === "name"
            ? a.dataset.name.localeCompare(b.dataset.name)
            : Number(b.dataset.balance || 0) - Number(a.dataset.balance || 0)
        )
        .forEach((el) => container.insertBefore(el, anchor))
    })
  }
}
