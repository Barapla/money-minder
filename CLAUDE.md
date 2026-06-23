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
| Instituciones financieras | `FinancialInstitution` | Completo |
| Pagos obligatorios | `ObligatoryPayment` | Completo |
| Reportes IA | `AiReport` | Completo |
| Historial crediticio | `CreditScoreEvent`, `Status` | Completo |
| Vistas de calendario | — | Completo |
| Insights financieros | `FinancialInsightsService`, `ClaudeService` | Completo |
| Jobs en background | `RecurringTransactionsJob`, `ProcessSingleRecurringTransactionJob`, `RecurringTransactionsCleanupJob` | Completo |
| Información laboral | `EmploymentInformation` | Completo |

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

## Engineering Standards

Standards live in the `.claude/` folder:

| File | Content |
|---|---|
| `ENGINEERING_STANDARDS.md` | Git, commits, PR, API communication, error format |
| `RAILS_STANDARDS.md` | Result pattern, service objects, serializers, DB, RuboCop, RSpec |
| `REACT_STANDARDS.md` | React-specific rules |
