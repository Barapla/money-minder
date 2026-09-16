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
| GET | /api/v1/auth/me | JWT Bearer | — | `{ record: { id, email, name } }` | Datos del usuario autenticado por token |
| GET | /api/v1/dashboard | JWT Bearer | — | `{ record: { financial_summary, trend_data, upcoming_payments, active_budgets, credit_cards_summary, savings_summary, recent_transactions, latest_insight } }` | Dashboard financiero consolidado para app movil. Soporta `?period=month\|30days\|year` |
| GET | /api/v1/transactions | JWT Bearer | — | `{ records: [...], meta: { current_page, total_pages, total_count } }` | Listado paginado de transacciones del usuario, orden `transaction_date DESC` |
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
    "name": "Usuario Ejemplo"
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
      { "budget_id": 1, "category_name": "Comida", "category_color": "Purple",
        "budgeted_amount": 2000.0, "spent_amount": 800.0, "remaining_amount": 1200.0,
        "percentage_used": 40.0 }
    ],
    "credit_cards_summary": [
      { "card_id": 1, "card_name": "Tarjeta Oro", "current_balance": 2000.0,
        "credit_limit": 10000.0, "available_credit": 8000.0,
        "next_cutting_date": "2026-09-25", "next_payment_date": "2026-09-30" }
    ],
    "savings_summary": [
      { "fund_id": 1, "fund_name": "Fondo Emergencia", "current_amount": 5000.0,
        "goal_amount": 20000.0, "percentage_achieved": 25.0 }
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
| active_budgets | array | Progreso de cada presupuesto activo del usuario contra el gasto del mes actual |
| credit_cards_summary | array | Tarjetas de credito activas, ordenadas por `next_cutting_date` |
| savings_summary | array | Fondos de ahorro activos con saldo actual y progreso hacia la meta |
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

#### Response Body (200)

```json
{
  "records": [
    { "id": 1, "date": "2026-09-10", "amount": 300.0, "currency": "MXN",
      "description": "Super", "category_name": "Comida", "transaction_type": "expense",
      "created_at": "2026-09-10T12:00:00-06:00", "updated_at": "2026-09-10T12:00:00-06:00" }
  ],
  "meta": { "current_page": 1, "total_pages": 3, "total_count": 45 }
}
```

#### Response Body (401)

```json
{ "errors": ["Token inválido o expirado"] }
```

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
