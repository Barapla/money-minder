// Corre con: node --test spec/javascript/
// Sin framework ni dependencias: en este entorno no hay navegador para un system
// spec con JS, y estas reglas ya se rompieron tres veces.
import { test } from "node:test"
import assert from "node:assert/strict"

import { accountVisible, zerosSummaryVisible } from "../../app/javascript/lib/account_visibility.js"

const conSaldo = { name: "klar", type: "savings_fund", zero: false, revealed: false }
const enCeros = { name: "stori", type: "savings_fund", zero: true, revealed: false }
const otroTipo = { name: "nu", type: "credit_card", zero: false, revealed: false }

const sinFiltros = { term: "", onlyFunded: false, selectedType: "all" }

test("la vista sin filtros pliega las cuentas en ceros", () => {
  assert.equal(accountVisible(conSaldo, sinFiltros), true)
  assert.equal(accountVisible(enCeros, sinFiltros), false)
  assert.equal(zerosSummaryVisible(sinFiltros), true)
})

test("el boton de desplegar saca las que estan en ceros", () => {
  assert.equal(accountVisible({ ...enCeros, revealed: true }, sinFiltros), true)
})

test("elegir un tipo muestra TODAS las de ese tipo, en ceros incluidas", () => {
  // La regresion reportada: el chip de tipo escondia la tarjeta-resumen, que
  // tiene el unico boton para desplegar, asi que las en ceros no salian nunca.
  const porTipo = { ...sinFiltros, selectedType: "savings_fund" }

  assert.equal(accountVisible(conSaldo, porTipo), true)
  assert.equal(accountVisible(enCeros, porTipo), true)
  assert.equal(accountVisible(otroTipo, porTipo), false)
  assert.equal(zerosSummaryVisible(porTipo), false)
})

test("buscar encuentra una cuenta aunque este en ceros", () => {
  const buscando = { ...sinFiltros, term: "stor" }

  assert.equal(accountVisible(enCeros, buscando), true)
  assert.equal(accountVisible(conSaldo, buscando), false)
  assert.equal(zerosSummaryVisible(buscando), false)
})

test("solo con saldo manda sobre el tipo y sobre la busqueda", () => {
  const porTipo = { term: "", onlyFunded: true, selectedType: "savings_fund" }
  const buscando = { term: "stor", onlyFunded: true, selectedType: "all" }

  assert.equal(accountVisible(enCeros, porTipo), false)
  assert.equal(accountVisible(conSaldo, porTipo), true)
  assert.equal(accountVisible(enCeros, buscando), false)
  assert.equal(accountVisible({ ...enCeros, revealed: true }, buscando), false)
  assert.equal(zerosSummaryVisible(porTipo), false)
})
