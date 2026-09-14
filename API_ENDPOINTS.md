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
