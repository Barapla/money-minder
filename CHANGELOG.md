# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.0.0/) y este proyecto usa [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

### FEAT-018 — Sistema de beneficios para productos financieros
- Modelo `FinancialProductBenefit` con enums `benefit_type` (annual_yield, cashback, points, discount) y `unit` (percentage, points, fixed_amount)
- Migración `create_financial_product_benefits` con columnas: id, financial_product_id, benefit_type, base_value, reduced_value, amount_cap, unit, description, active, timestamps
- Asociación `has_many :benefits` en `FinancialProduct` con `dependent: :destroy`
- Controlador `Admin::FinancialProductBenefitsController` con CRUD completo anidado bajo productos
- Vistas Tailwind CSS para formulario y card de beneficio
- Helpers `benefit_display_value` y `benefit_type_badge_class` en `FinancialProductsHelper`
- Vista `show` de producto financiero con sección de beneficios
- I18n completo en español para enums, formularios y mensajes
- Seeds de ejemplo: Nu Cajita Turbo (rendimiento 13%/7%), BBVA Oro (cashback 2%, puntos), Klar Débito (rendimiento 15% hasta $25,000)
- Specs de modelo: 22 examples
- Specs de request: CRUD completo bajo admin

### FEAT-017 — Catálogo de productos financieros
- Modelo `FinancialProduct` con enums `product_type` (cash, debit, credit, savings_fund)
- CRUD administrativo de productos agrupados por institución
- Filtro por estado activo/inactivo

### FEAT-016 — Catálogo global de instituciones financieras
- Modelo `FinancialInstitution` con CRUD administrativo
- Namespace `admin` para gestión de catálogos globales
