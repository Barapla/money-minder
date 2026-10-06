# API_ENDPOINTS.md — Money Minder

> LIVE CONTRACT: This file documents the API endpoints exposed by this project.
> It MUST be updated whenever an endpoint is created, modified, or removed.
> Read `.claude/ENGINEERING_STANDARDS.md` for the mandatory update rule.

---


## Authentication

Describe the authentication mechanism used by this API.

| Method | Header | Description |
|---|---|---|
| API Key | `X-Api-Key` | For external integrations |
| JWT Bearer | `Authorization: Bearer <token>` | For mobile app endpoints (obtained via POST /api/v1/auth/login) |

---


## Endpoints

| Method | Path | Auth | Request Body | Response Body | Notes |
|---|---|---|---|---|---|
| GET | /api/v1/users | API Key | — | `{ records: [...] }` | List users |
| GET | /api/v1/users/:id | API Key | — | `{ record: {...} }` | Get user |
| POST | /api/v1/users | API Key | `{ user: {...} }` | `{ record: {...} }` | Create user |
| PUT | /api/v1/users/:id | API Key | `{ user: {...} }` | `{ record: {...} }` | Update user |
| DELETE | /api/v1/users/:id | API Key | — | `{ record: {...} }` | Delete user |
| POST | /api/v1/auth/login | — | `{ email, password }` | `{ record: { token, expires_at } }` | Login para app movil, retorna JWT |
| POST | /api/v1/auth/register | — | `{ name, email, password, password_confirmation }` | `{ record: { token, expires_at } }` | Registro desde la app movil (201) |
| POST | /api/v1/auth/password | — | `{ email }` | `{ record: { sent: true } }` | Envia instrucciones de recuperacion; responde 200 aunque el correo no exista |
| PATCH | /api/v1/auth/password | JWT Bearer | `{ current_password, password, password_confirmation }` | `{ record: { id, email, name, currency } }` | Cambio de contraseña |
| GET | /api/v1/auth/me | JWT Bearer | — | `{ record: { id, email, name, currency } }` | Datos del usuario autenticado por token |
| PATCH | /api/v1/auth/me | JWT Bearer | `{ name, currency_id }` | `{ record: { id, email, name, currency } }` | Actualiza perfil (nombre, moneda predeterminada) |
| GET | /api/v1/catalogs | JWT Bearer | — | `{ record: { transaction_types, categories, budgets, transaction_icons, colors, frequency_types, currencies } }` | Opciones de formularios de la app movil |
| GET | /api/v1/calendar | JWT Bearer | — | `{ record: { month, transactions, reminders } }` | Movimientos y recordatorios de un mes. `?month=YYYY-MM` |
| GET | /api/v1/obligatory_payments | JWT Bearer | — | `{ records: [...] }` | Recordatorios del usuario, por proxima fecha. `?reminder_type=payment\|income` |
| POST | /api/v1/obligatory_payments | JWT Bearer | `{ obligatory_payment: {...} }` | `{ record: {...} }` | Crea recordatorio unico o recurrente (201) |
| GET | /api/v1/saving_goals | JWT Bearer | — | `{ records: [...] }` | Metas de ahorro con saldo asignado por prioridad |
| POST | /api/v1/saving_goals | JWT Bearer | `{ saving_goal: { name, target_amount, deadline } }` | `{ record: {...} }` | Crea meta de ahorro (201) |
| GET | /api/v1/dashboard | JWT Bearer | — | `{ record: { financial_summary, trend_data, upcoming_payments, active_budgets, credit_cards_summary, savings_summary, recent_transactions, latest_insight } }` | Dashboard financiero consolidado para app movil. Soporta `?period=month\|30days\|year` |
| GET | /api/v1/transactions | JWT Bearer | — | `{ records: [...], meta: { current_page, total_pages, total_count, net_total } }` | Listado paginado y filtrable (`q`, `transaction_type`, `category`, `start_date`, `end_date`), orden `transaction_date DESC` |
| POST | /api/v1/transactions | JWT Bearer | `{ transaction: {...} }` | `{ record: {...} }` | Crea una transaccion (201) |
| GET | /api/v1/transactions/:id | JWT Bearer | — | `{ record: {...} }` | Detalle de una transaccion del usuario |

---

## Endpoint Details

### GET /api/v1/users

**Auth:** API Key

#### Response Body

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | Database ID |
| created_at | datetime | ISO8601 timestamp |
| updated_at | datetime | ISO8601 timestamp |

---

### GET /api/v1/users/:id

**Auth:** API Key

#### Response Body

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | Database ID |
| created_at | datetime | ISO8601 timestamp |
| updated_at | datetime | ISO8601 timestamp |

---

### POST /api/v1/users

**Auth:** API Key

#### Request Body

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| field_name | string | Yes/No | Field description |

#### Response Body

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | Database ID |
| created_at | datetime | ISO8601 timestamp |
| updated_at | datetime | ISO8601 timestamp |

---

### PUT /api/v1/users/:id

**Auth:** API Key

#### Request Body

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| field_name | string | Yes/No | Field description |

#### Response Body

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | Database ID |
| created_at | datetime | ISO8601 timestamp |
| updated_at | datetime | ISO8601 timestamp |

---

### DELETE /api/v1/users/:id

**Auth:** API Key

---

### POST /api/v1/auth/login

**Auth:** Ninguna (endpoint publico)

Autentica un usuario con email y password, y retorna un token JWT valido por 30 dias. Usado por la app movil para iniciar sesion.

#### Request Body

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| email | string | Si | Email del usuario |
| password | string | Si | Password del usuario |

#### Response Body (200)

```json
{
  "record": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "expires_at": "2026-10-14T05:38:11-06:00"
  }
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| token | string | JWT firmado con HS256, contiene `user_id` y `exp` |
| expires_at | datetime | ISO8601, 30 dias desde la generacion |

#### Response Body (401)

```json
{ "errors": ["Credenciales inválidas"] }
```

---

### GET /api/v1/auth/me

**Auth:** JWT Bearer (`Authorization: Bearer <token>`)

Retorna los datos basicos del usuario dueño del token, para restaurar sesiones guardadas en la app movil.

#### Response Body (200)

```json
{
  "record": {
    "id": 123,
    "email": "user@example.com",
    "name": "Usuario Ejemplo",
    "currency": "MXN"
  }
}
```

#### Response Body (401)

Se retorna cuando el token esta ausente, es invalido, expiro, o el usuario ya no existe:

```json
{ "errors": ["Token inválido o expirado"] }
```

---

### GET /api/v1/dashboard

**Auth:** JWT Bearer (`Authorization: Bearer <token>`)

Devuelve el dashboard financiero consolidado del usuario autenticado, optimizado para la app movil: resumen del periodo, tendencia de los ultimos 6 meses, proximos pagos obligatorios, progreso de presupuestos activos, resumen de tarjetas de credito, resumen de fondos de ahorro, ultimas 10 transacciones y ultimo insight de IA (cacheado 15 minutos). Todas las consultas se aislan por el usuario del token.

#### Query Params

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| period | string | No | Rango de `financial_summary`: `month` (default), `30days` o `year`. Invalido → 400 |

#### Response Body (200)

```json
{
  "record": {
    "financial_summary": {
      "total_income": 15000.0, "total_expenses": 8000.0, "balance": 7000.0,
      "month": 9, "year": 2026,
      "category_breakdown": [
        { "category_name": "Comida", "amount": 3000.0, "percentage": 60.0 },
        { "category_name": "Sin categoría", "amount": 2000.0, "percentage": 40.0 }
      ]
    },
    "trend_data": [
      { "month": "2026-04", "income": 15000.0, "expenses": 9000.0, "balance": 6000.0 },
      { "month": "2026-09", "income": 15000.0, "expenses": 8000.0, "balance": 7000.0 }
    ],
    "upcoming_payments": [
      { "id": 1, "title": "Renta", "amount": 5000.0, "currency": "MXN",
        "due_date": "2026-09-30", "days_until_due": 16, "category": "Vivienda" }
    ],
    "active_budgets": [
      { "budget_id": 1, "category_name": "Plata", "category_color": "orange-500",
        "budget_type": "credit_card", "debt_amount": 1023.7, "limit_amount": 30000.0,
        "available_amount": 28976.3, "spent_this_month": 970.0, "percentage_used": 3.41 }
    ],
    "credit_cards_summary": [
      { "card_id": 1, "card_name": "Tarjeta Oro", "current_balance": 2000.0,
        "credit_limit": 10000.0, "available_credit": 8000.0,
        "next_cutting_date": "2026-09-25", "next_payment_date": "2026-09-30" }
    ],
    "savings_summary": [
      { "fund_id": 1, "fund_name": "Fondo Emergencia", "current_amount": 5000.0,
        "goal_amount": 20000.0, "percentage_achieved": 25.0,
        "target_date": "2027-03-01", "feasibility": "achievable" }
    ],
    "recent_transactions": [
      { "id": 1, "description": "Super", "amount": 500.0, "currency": "MXN",
        "transaction_date": "2026-09-14", "category_name": "Comida",
        "category_color": "Purple", "transaction_type": "expense" }
    ],
    "latest_insight": {
      "id": 1, "content": { "raw_content": "..." },
      "created_at": "2026-09-10T12:00:00-06:00", "expires_at": null
    }
  }
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| financial_summary | object | Ingresos, gastos, balance y `category_breakdown` del periodo solicitado |
| financial_summary.category_breakdown | array | Gastos agrupados por categoria: `category_name`, `amount`, `percentage`; ordenado por `amount` DESC; los porcentajes suman 100.0 |
| trend_data | array | Ultimos 6 meses (incluye el actual), ordenados cronologicamente: `month` (YYYY-MM), `income`, `expenses`, `balance` |
| upcoming_payments | array | Maximo 10 pagos obligatorios en los proximos 30 dias, ordenados por `due_date` ascendente |
| active_budgets | array | Presupuestos activos con las mismas cifras que el index web (`Budget#debt_amount`/`#limit_amount`/`#current_amount`/`#budget_percentage`): `debt_amount` es la deuda de la tarjeta, `limit_amount` su linea de credito, `available_amount` el disponible y `percentage_used` = deuda/limite. En tipos sin linea de credito (`cash`, `debit_card`) deuda, limite y porcentaje son `0.0`; la referencia util ahi es `available_amount` + `spent_this_month`. `budget_type` es el code del catalogo, para agrupar igual que `Budget.grouped_by_type`. Excluye `savings_fund`/`term_saving` (ver `savings_summary`) |
| credit_cards_summary | array | Tarjetas de credito activas, ordenadas por `next_cutting_date` |
| savings_summary | array | Fondos de ahorro activos con saldo actual, progreso hacia la meta, `target_date` y `feasibility` (`easily_achievable`, `achievable`, `challenging`, `unrealistic`, `impossible` o `no_target_date`, de `SavingsFund#goal_feasibility`) |
| recent_transactions | array | Ultimas 10 transacciones del usuario, ordenadas por `transaction_date` DESC |
| latest_insight | object o null | Ultimo reporte IA exitoso (tipo `general`), cacheado 15 minutos; `null` si no hay reporte |

#### Response Body (400)

```json
{ "error": { "code": "invalid_period", "message": "Invalid period. Allowed: month, 30days, year" } }
```

#### Response Body (401)

```json
{ "errors": ["Token inválido o expirado"] }
```

---

### GET /api/v1/transactions

**Auth:** JWT Bearer (`Authorization: Bearer <token>`)

Listado paginado de las transacciones del usuario autenticado, ordenadas por `transaction_date` descendente. Usado por la app movil para el listado de movimientos.

#### Query Params

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| page | integer | No | Pagina solicitada, default 1 |
| per_page | integer | No | Tamaño de pagina, default 20 |
| q | string | No | Busca en descripcion o nombre de categoria (sin distinguir mayusculas) |
| transaction_type | string | No | `income`, `expense`, `transfer` o `refund` |
| category | string | No | Nombre exacto de la categoria |
| start_date / end_date | date | No | Rango inclusivo de `transaction_date` (`YYYY-MM-DD`). Formato invalido → 400 |

#### Response Body (200)

```json
{
  "records": [
    { "id": 1, "date": "2026-09-10", "amount": 300.0, "currency": "MXN",
      "description": "Super", "category_name": "Comida", "transaction_type": "expense",
      "icon": "🛒", "color": "blue-500",
      "created_at": "2026-09-10T12:00:00-06:00", "updated_at": "2026-09-10T12:00:00-06:00" }
  ],
  "meta": { "current_page": 1, "total_pages": 3, "total_count": 45, "net_total": -1200.0 }
}
```

`total_count`, `total_pages` y `net_total` (ingresos − gastos) se calculan sobre todas las transacciones que cumplen el filtro, no solo la pagina. `icon`/`color` son los valores de catalogo (emoji y color Tailwind).

#### Response Body (400)

```json
{ "error": { "code": "invalid_date", "message": "Fecha inválida. Usa el formato YYYY-MM-DD" } }
```

#### Response Body (401)

```json
{ "errors": ["Token inválido o expirado"] }
```

---

### POST /api/v1/transactions

**Auth:** JWT Bearer

#### Request Body

```json
{ "transaction": { "transaction_type_id": 2, "amount": 150.5, "description": "Cine",
                   "category_id": 10, "transaction_date": "2026-09-12", "budget_id": 3,
                   "icon_id": 40, "color_id": 5 } }
```

Todos los campos son requeridos. Los ids salen de `GET /api/v1/catalogs`; `budget_id` debe pertenecer al usuario. La moneda es la predeterminada del usuario (o MXN). Transferencias no soportadas desde la API (requieren `related_budget_id`).

#### Response Body (201)

`{ "record": { ...mismos campos que el listado... } }`

#### Response Body (422)

```json
{ "error": { "code": "validation_error", "message": "Budget debe pertenecer al mismo usuario",
             "details": { "budget_id": ["debe pertenecer al mismo usuario"] } } }
```

---

### POST /api/v1/auth/register

**Auth:** Ninguna

Request: `{ "name": "Luis Pérez", "email": "luis@example.com", "password": "secret123", "password_confirmation": "secret123" }`.
Response (201): `{ "record": { "token": "...", "expires_at": "..." } }` — el usuario queda autenticado.
Response (422): `{ "error": { "code": "validation_error", "message": "...", "details": { "email": ["ya está en uso"] } } }`.

---

### POST /api/v1/auth/password

**Auth:** Ninguna

Request: `{ "email": "user@example.com" }`. Envia el correo de recuperacion de Devise. Responde siempre 200 `{ "record": { "sent": true } }` para no revelar que correos estan registrados. En produccion requiere `APP_HOST` (host de los enlaces del correo).

---

### PATCH /api/v1/auth/me · PATCH /api/v1/auth/password

**Auth:** JWT Bearer

- `PATCH /auth/me` — `{ "name": "Ana López", "currency_id": 3 }` (ambos opcionales).
- `PATCH /auth/password` — `{ "current_password", "password", "password_confirmation" }`; contraseña actual incorrecta → 422.

Ambos responden 200 con el mismo `record` que `GET /auth/me`, o 422 con `validation_error`.

---

### GET /api/v1/catalogs

**Auth:** JWT Bearer

```json
{
  "record": {
    "transaction_types": [ { "id": 1, "code": "income", "value": "Ingreso" }, { "id": 2, "code": "expense", "value": "Gasto" } ],
    "categories": { "income": [ { "id": 5, "name": "Sueldo" } ], "expense": [ { "id": 10, "name": "Supermercado" } ] },
    "budgets": [ { "id": 3, "name": "Efectivo de Ana", "budget_type": "cash", "personal": true } ],
    "transaction_icons": [ { "id": 40, "code": "restaurants", "value": "🍽️" } ],
    "colors": [ { "id": 5, "code": "blue", "value": "blue-500" } ],
    "frequency_types": [ { "id": 60, "code": "monthly", "value": "Mensual" } ],
    "currencies": [ { "id": 3, "code": "MXN", "name": "Peso mexicano" } ]
  }
}
```

Solo `income`/`expense` en `transaction_types`; categorias con el mismo criterio que el formulario web; solo presupuestos activos del usuario.

---

### GET /api/v1/calendar

**Auth:** JWT Bearer

Query: `month=YYYY-MM` (default: mes actual). Formato invalido → 400 `invalid_month`.

```json
{
  "record": {
    "month": "2026-10",
    "transactions": [ { "...": "mismo formato que GET /transactions" } ],
    "reminders": [ { "id": 1, "name": "Renta", "amount": 5000.0, "date": "2026-10-01",
                     "reminder_type": "payment", "category_name": "Vivienda", "icon": "🏘️" } ]
  }
}
```

`transactions` en orden ascendente de fecha. Los recordatorios recurrentes aparecen una vez por cada fecha en que ocurren dentro del mes.

---

### GET · POST /api/v1/obligatory_payments

**Auth:** JWT Bearer

GET (`?reminder_type=payment|income` opcional) → `{ "records": [...] }`, ordenados por `next_due_date` (los que ya no tienen proxima fecha al final):

```json
{ "id": 1, "name": "Renta", "amount": 6700.0, "reminder_type": "payment", "category_name": "Vivienda",
  "icon": "🏘️", "color": "orange-500", "due_date": null, "next_due_date": "2026-10-01",
  "recurrence": { "frequency": "monthly", "frequency_value": 1, "start_date": "2026-09-01", "end_date": null } }
```

POST (201):

```json
{ "obligatory_payment": { "name": "Renta", "amount": 6700, "reminder_type": "payment",
    "category_id": 10, "icon_id": 40, "color_id": 5, "description": "opcional",
    "due_date": "2026-10-01",
    "recurrence": { "frequency_type_id": 60, "frequency_value": 1, "start_date": "2026-09-01", "end_date": null } } }
```

Sin `recurrence` es un recordatorio unico y `due_date` es requerido; con `recurrence` se ignora `due_date`. Errores → 422 `validation_error`.

---

### GET · POST /api/v1/saving_goals

**Auth:** JWT Bearer

GET → `{ "records": [...] }`: primero las metas activas por prioridad, luego el resto (mas recientes primero).

```json
{ "id": 1, "name": "Viaje", "target_amount": 60000.0, "allocated_amount": 8400.0,
  "progress_percentage": 14.0, "deadline": "2027-12-01", "days_remaining": 441,
  "status": "active", "priority_order": 1 }
```

`allocated_amount` reparte el saldo disponible (efectivo + debito + fondos − deuda de tarjetas) entre metas activas en orden de prioridad (`SavingGoalServices::PriorityAllocator`, igual que el web).

POST `{ "saving_goal": { "name", "target_amount", "deadline" } }` → 201 con el mismo formato; errores → 422.

---

### GET /api/v1/transactions/:id

**Auth:** JWT Bearer (`Authorization: Bearer <token>`)

Detalle completo de una transaccion del usuario autenticado. Usado por la app movil para navegar del listado al detalle.

#### Response Body (200)

```json
{
  "record": {
    "id": 1, "date": "2026-09-10", "amount": 300.0, "currency": "MXN",
    "description": "Super", "category_name": "Comida", "transaction_type": "expense",
    "icon": "🛒", "color": "blue-500",
    "created_at": "2026-09-10T12:00:00-06:00", "updated_at": "2026-09-10T12:00:00-06:00"
  }
}
```

#### Response Body (404)

```json
{ "error": { "code": "not_found", "message": "Recurso no encontrado" } }
```

#### Response Body (401)

```json
{ "errors": ["Token inválido o expirado"] }
```

---


## Response Formats

### Success — Single record
```json
{ "record": { "id": 1, "..." : "..." } }
```

### Success — Collection
```json
{ "records": [ { "id": 1 }, { "id": 2 } ] }
```

### Error
```json
{ "error": { "code": "not_found", "message": "...", "details": {} } }
```

---


## Maintenance Rule

Any ticket that creates, modifies, or removes an endpoint MUST update this file before the final commit.
See ENGINEERING_STANDARDS.md — API Changes section for details.
