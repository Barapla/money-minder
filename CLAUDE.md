# CLAUDE.md — money-minder

> Project context and configuration for AI-assisted development.
> Read `.claude/ENGINEERING_STANDARDS.md` before writing any code.

---

## What is this project

MoneyMinder es un gestor de gastos personales, en el cual se podran visualizar de manera grafica cada una de las compras, ventas y transacciones realizadas a lo largo de un periodo determinado.

---

## Stack

| Tecnología | Version |
|---|---|
| Ruby | 3.2.2 |
| Rails | 7.0.8 |
| PostgreSQL | 16 |
| Redis | — |
| Sidekiq | 6.5 |
| RSpec | — |
| RuboCop | — |
| Node.js | — |

Gemas clave: `devise`, `httparty`, `sidekiq-cron`, `brakeman`, `bundler-audit`

---

## Features implementados

| Feature | Modelos principales | Estado |
|---|---|---|
| Autenticación | `User` (Devise) | Completo |
| Transacciones | `Transaction`, `TransactionHistory` | Completo |
| Transacciones recurrentes | `RecurringTransaction`, `Recurrence` | Completo |
| Presupuestos | `Budget` | Completo |
| Categorías | `Category` | Completo |
| Catálogos | `GroupCatalog`, `Catalog` | Completo |
| Tarjetas de crédito | `CreditCard`, `CreditCardCycle`, `CreditCardProduct`, `CreditCardTier`, `CreditCardCycleTransaction` | Completo |
| Fondos de ahorro | `SavingsFund` | Completo |
| Catálogo financiero (código) | `FinancialCatalogServices::Catalog`, `FinancialCatalogServices::BaseProduct` | Completo |
| Redes y niveles de tarjetas (código) | `FinancialNetworks::BaseNetwork`, `FinancialNetworks::BaseLevel` | Completo |
| Pagos obligatorios | `ObligatoryPayment` | Completo |
| Reportes IA | `AiReport` | Completo |
| Historial crediticio | `CreditScoreEvent`, `Status` | Completo |
| Vistas de calendario | — | Completo |
| Insights financieros | `FinancialInsightsService`, `ClaudeService` | Completo |
| Jobs en background | `RecurringTransactionsJob`, `ProcessSingleRecurringTransactionJob`, `RecurringTransactionsCleanupJob` | Completo |
| Información laboral | `EmploymentInformation` | Completo |
| Cálculos de nómina | `PayrollProfile`, `Payroll::AguinaldoCalculator`, `Payroll::SavingsFundCalculator`, `PayrollServices::Calculator` | Completo |
| Metas de ahorro | `SavingGoal`, `SavingGoalServices::ProgressCalculator` | Completo |

---

## Technical Decisions

- **Sidekiq** para background jobs (queues: `default`, `automation`)
- **RSpec** para testing con FactoryBot y Faker
- **Devise** para autenticación
- **ClaudeService / HTTParty** para integración con Anthropic API (modelo `claude-sonnet-4`)
- **Presenters** para lógica de presentación compleja (moneda, fechas, presupuestos)
- **Service objects** sin módulo namespace raíz, con sub-namespace por dominio (ej. `CreditCardServices::`)
- **Sidekiq-cron** para jobs programados (ej. procesamiento de transacciones recurrentes)

---

## PayrollProfile — estructura de campos (FEAT-005)

| Campo | Tipo | Descripción |
|---|---|---|
| `base_salary` | decimal(10,2) | Sueldo base gravado (campo principal) |
| `monthly_gross_salary` | decimal(12,2) | Legado — sincronizado desde EmploymentInformation |
| `non_taxable_bonuses` | jsonb | Hash de bonos no gravados: `{ "concepto" => monto }` |
| `savings_fund_rate` | decimal(5,2) | Tasa de fondo de ahorro (default: 4.0%) |
| `savings_fund_percentage` | decimal(5,2) | Legado — conservado por compatibilidad |
| `custom_isr_rate` | decimal(5,2) | Tasa ISR personalizada (nil = usa default 18.6%) |
| `custom_imss_rate` | decimal(5,2) | Tasa IMSS personalizada (nil = usa default 3.0%) |

### Metodo deprecado

`PayrollProfile#monthly_salary` — delegado a `base_salary` con warning. Remover en version futura.

### Formula de salario neto (PayrollServices::Calculator)

`base_salary + total_bonuses - savings_fund_employee - isr_estimado - imss_estimado`

### Constantes (PayrollConstants)

- `DEFAULT_ISR_RATE = 18.6` — porcentaje efectivo sobre salario gravado
- `DEFAULT_IMSS_RATE = 3.0` — porcentaje efectivo sobre SBC
- `DEFAULT_SAVINGS_FUND_RATE = 4.0` — porcentaje de fondo de ahorro

---

## Recordatorios de Nomina en Calendario (FEAT-007)

Los recordatorios de quincena se generan on-the-fly sin tabla persistente usando dos clases:

### PayrollReminder (PORO)

`app/models/payroll_reminder.rb` — representa un pago proyectado con atributos: `date`, `net_amount`, `calculation_breakdown`, `periodicity`.

### PayrollServices::ReminderGenerator

`app/services/payroll_services/reminder_generator.rb` — genera recordatorios para un rango de fechas:

```ruby
generator = PayrollServices::ReminderGenerator.new(user)
reminders = generator.generate(from_date: Date.today.beginning_of_month, to_date: Date.today.end_of_month)
```

- Requiere que el usuario tenga `EmploymentInformation` y `PayrollProfile` configurados.
- Soporta todas las periodicidades del enum: `daily`, `weekly`, `biweekly`, `monthly`, `yearly`.
- El ciclo de pagos se calcula desde `EmploymentInformation.start_date`.
- El monto neto se calcula usando `PayrollServices::Calculator` en cada llamada (siempre refleja cambios en PayrollProfile).

### Integracion en CalendarController

`CalendarController` usa `before_action :set_payroll_reminders_for_month` para los actions `index` y `set_month`, y llama a `payroll_reminders_for_date` en `day_details`. Los resultados se pasan al componente `Calendar::MainComponent` via `payroll_reminders:` y se visualizan con un indicador amber en el dia del calendario.

---

## Conventions

Service objects, RSpec, Presenters, FactoryBot

---

## Language

All ticket content and code comments: **Spanish (es)**

---



## PM Agent Integration

This project is managed by the Brainmachine PM Agent.

| Variable | Value |
|---|---|
| `PM_AGENT_URL` | `http://localhost:3000` |
| `PM_AGENT_API_KEY` | Set in `.env` |
| `PROJECT_NAME` | `money-minder` |

### Resolve ticket ID

```bash
curl -s "http://localhost:3000/api/v1/tickets?identifier=FEAT-001&project=money-minder" \
  -H "X-Api-Key: $PM_AGENT_API_KEY"
```

### Mark ticket complete

```bash
curl -X POST http://localhost:3000/api/v1/tickets/{id}/complete \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PM_AGENT_API_KEY" \
  -d '{
    "branch": "<current-branch>",
    "pr_url": "<pr-url>",
    "summary": "<summary>",
    "technical_decisions": "<decisions>",
    "how_to_test": "<steps>"
  }'
```

---

## Security Patterns (FEAT-009)

### UserScoped concern

`app/controllers/concerns/user_scoped.rb` — incluido en ApplicationController. Provee `authorize_resource(resource)` para verificar ownership cuando ya se tiene el recurso.

### Query scoping

Todas las queries en controladores deben ir a traves de la asociacion del usuario:

```ruby
# Correcto
current_user.transactions.find(params[:id])
current_user.budgets.where(...)
current_user.obligatory_payments.includes(...)

# Incorrecto
Transaction.find(params[:id])
Budget.all
```

### rescue_from en ApplicationController

`rescue_from ActiveRecord::RecordNotFound` esta configurado en ApplicationController. Cuando `current_user.transactions.find(id)` no encuentra el registro (porque no pertenece al usuario), lanza RecordNotFound que devuelve HTTP 404 automaticamente.

### ReportFilter con user

`ReportFilter` acepta `user:` en el constructor. Siempre pasar `current_user`:

```ruby
ReportFilter.new(report_filter_params.merge(user: current_user))
```

Sin `user:`, el filtro consulta todos los budgets/transacciones de la DB (comportamiento legacy para tests sin autenticacion).

### Factories de test

Para crear transacciones en specs, usar las factories:
- `:transaction` — requiere `:user`, `:budget`, `:category`, `:currency`, `:catalog` para color/icon/transaction_type
- `:budget` — requiere `:user` y catalogs para `:budget_type`, `:color`, `:icon`

---

## SavingGoal — Metas de ahorro (FEAT-010)

### Modelo

`app/models/saving_goal.rb` — `belongs_to :user`, enum `status` [:active, :paused, :achieved, :cancelled], validaciones de presencia y numericality.

### Service Object

`app/services/saving_goal_services/progress_calculator.rb` — calcula progreso on-demand:

- `available_money` = efectivo (personal budget) + debito (`debit_card` budgets) + fondos de ahorro (`SavingsFund.budget.current_amount`) - deuda de credito (`credit_card.current_debt`)
- `progress_percentage` = (available_money / target_amount) * 100
- Memoiza `total_available_money` para calcular N metas con 4 queries totales (no N*4)

### Decisiones de diseno

- Progreso calculado on-demand, no persistido en BD para evitar inconsistencias
- `status` como enum con default `:active`; la transicion a `:achieved` es manual por el usuario
- `deadline` es opcional; si no se establece, la meta no tiene fecha limite
- Validacion de `deadline` solo en `on: :create` para permitir editar metas con fechas pasadas

---

## Financial Products Catalog (FEAT-020)

El catalogo de instituciones financieras y sus productos/beneficios **ya no vive en base de datos**. Antes existian `FinancialInstitution`, `FinancialProduct` y `FinancialProductBenefit` como modelos ActiveRecord con panel de administracion en `/admin/financial_institutions` y `/admin/financial_products`; esas tablas, modelos, controllers y vistas fueron eliminados.

Las reglas de cada institucion (tramos, beneficios, requisitos) son mas formulas que datos planos, asi que el catalogo ahora sigue el mismo patron que `PayrollConstants`: **clases Ruby versionadas en codigo**, no registros editables en runtime.

### Estructura

`app/services/financial_catalog_services/` — una subcarpeta por institucion (`nu/`, `klar/`, `bbva/`, etc):

- **`BaseProduct`** — clase base con atributos `name`, `institution`, `product_type` (`:cash`, `:debit`, `:credit`, `:savings_fund`), `active` y `benefits` (array de hashes `{ type:, unit:, value:, description: }`).
- Cada producto concreto (ej. `FinancialCatalogServices::Nu::NuCreditCard`) hereda de `BaseProduct` y define sus atributos en el constructor.
- **`Catalog.all_products`** — registry central; retorna instancias de todos los productos activos definidos en codigo.

```ruby
FinancialCatalogServices::Catalog.all_products
# => [#<Nu::NuCreditCard ...>, #<Klar::KlarDebitCard ...>, #<Bbva::BbvaSavingsFund ...>]
```

### Decisiones de diseno

- Sin BD: agregar una institucion o producto nuevo es agregar una clase nueva, no un registro
- Sin FK a datos de usuario: si una feature futura necesita referenciar un producto (ej. `CreditCard`), debe usar un `product_identifier` (string) que matchee con la clase, no una FK
- `credit_card_products.financial_institution_id` (tabla sin controller/vista/ruta, scaffolding sin usar) perdio su FK a `financial_institutions` al eliminarse la tabla; la columna permanece pero sin referencia

---

## Financial Networks — Redes y niveles de tarjetas (FEAT-023)

Las redes de tarjetas de credito (Visa, Mastercard, Amex) y sus niveles (Classic, Gold, Platinum, etc.) son componentes independientes de la institucion emisora: comparten beneficios entre bancos sin duplicar codigo. Mismo patron que el catalogo financiero (FEAT-020): clases Ruby en `app/services/financial_networks/`, sin BD.

- **`FinancialNetworks::BaseNetwork`** — clase base con metodos de clase `id`, `name`, `all_levels`.
- **`FinancialNetworks::BaseLevel`** — clase base con metodos de clase `id`, `network_id`, `name`, `benefits`. `id`/`network_id` se derivan del nombre real de la clase (`to_s`), no de `name` (que las subclases sobreescriben con un texto de despliegue), para mantener IDs estables (`visa_gold`, `mastercard_world_elite`).
- Redes concretas: `Visa` (Classic, Gold, Platinum, Signature, Infinite), `Mastercard` (Standard, Gold, Platinum, World, WorldElite), `Amex` (Green, Gold, Platinum, Centurion) — jerarquia independiente con beneficios propios.
- **`FinancialNetworks.all_networks`** / **`FinancialNetworks.find_level(id)`** — utilidades a nivel de modulo.

```ruby
FinancialNetworks::Visa::Gold.benefits
# => ["Proteccion de compras hasta 90 dias", "Seguro de viaje internacional", "Asistencia en carretera 24/7"]

FinancialNetworks.find_level('mastercard_world_elite')
# => FinancialNetworks::Mastercard::WorldElite
```

`FinancialCatalogServices::BaseProduct#network_level` (instance method, default `nil`) conecta un producto con su red/nivel. Productos sin tarjeta (cash, savings_fund) no lo sobreescriben:

```ruby
class NuCreditCard < FinancialCatalogServices::BaseProduct
  def network_level
    FinancialNetworks::Visa::Gold
  end
end
```

---

## Engineering Standards

Standards live in the `.claude/` folder:

| File | Content |
|---|---|
| `ENGINEERING_STANDARDS.md` | Git, commits, PR, API communication, error format |
| `RAILS_STANDARDS.md` | Result pattern, service objects, serializers, DB, RuboCop, RSpec |
| `REACT_STANDARDS.md` | React-specific rules |
