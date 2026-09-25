// Reglas de visibilidad del index de presupuestos, aparte del controlador para
// poder probarlas sin navegador (spec/javascript/account_visibility.test.mjs).
//
// La sutileza: las cuentas en ceros viven plegadas detras del boton de la
// tarjeta-resumen, pero ese plegado solo tiene sentido en la vista sin filtros.
// Si el usuario elige un tipo o escribe una busqueda esta pidiendo algo
// concreto, y las que casen deben salir aunque esten en ceros.

export function isFiltering({ term, selectedType }) {
  return Boolean(term) || selectedType !== "all"
}

export function accountVisible(account, state) {
  const { term, onlyFunded, selectedType } = state

  if (term && !account.name.includes(term)) return false
  if (onlyFunded && account.zero) return false
  if (selectedType !== "all" && account.type !== selectedType) return false
  if (account.zero && !isFiltering(state) && !account.revealed) return false

  return true
}

// El resumen sobra cuando las cuentas en ceros ya se listan una por una, y
// cuando "solo con saldo" las excluye del todo.
export function zerosSummaryVisible(state) {
  return !isFiltering(state) && !state.onlyFunded
}
