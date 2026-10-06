# RAILS_STANDARDS.md — Ruby on Rails Standards
> Stack-specific rules for Rails projects. Complements ENGINEERING_STANDARDS.md.
> Base stack: Rails 7.0.8, PostgreSQL 16, Redis, Sidekiq 6.5, RSpec.

---

## Result Pattern

Every service object returns a `Result`. Never throw exceptions to the caller — encapsulate them in Result.

```ruby
# Success
Result.success(data: value)
Result.success(record: model_instance)

# Failure
Result.failure(error: :validation_error, message: "human-readable description")
Result.failure(error: e.message)
```

### Verification in the Caller
```ruby
result = MyService.new(params).call

if result.success?
  render json: { record: MySerializer.new(result.data) }
else
  render json: { error: { code: result.error, message: result.message } }, status: :unprocessable_entity
end
```

---

## Service Objects

### Structure
```ruby
class MyService
  def initialize(param_one:, param_two:)
    @param_one = param_one
    @param_two = param_two
  end

  def call
    # main logic
    Result.success(data: result)
  rescue StandardError => e
    Result.failure(error: e.message)
  end

  private

  attr_reader :param_one, :param_two

  def helper_method
    # ...
  end
end
```

### Namespacing
- Sin namespace raiz para servicios simples: `AiReportService`, `ClaudeService`, `FinancialInsightsService`
- Sub-namespace por dominio cuando hay multiples servicios relacionados: `CreditCardServices::CycleRecalculationService`

### Rules
- One service, one responsibility
- Any logic that is not simple CRUD → service object
- Controllers only call services and render — no business logic
- Do not use `rescue Exception` — only `rescue StandardError` (or specific subclasses)

---

## Presenters

Los presenters encapsulan lógica de presentación compleja. Se usan para formateo de moneda, fechas y estructuras de datos para la vista.

```ruby
class TransactionPresenter < ApplicationPresenter
  def initialize(transaction)
    @transaction = transaction
  end

  def formatted_amount
    # lógica de presentación
  end

  private

  attr_reader :transaction
end
```

Presenters existentes:
- `BudgetPresenter`
- `TransactionPresenter`
- `RecurringTransactionPresenter`
- `CurrencyPresenter`
- `DatePresenter`

---

## Serializers

```ruby
class MySerializer
  def initialize(record)
    @record = record
  end

  def as_json(*)
    {
      id: record.id,
      name: record.name,
      created_at: record.created_at.iso8601
    }
  end

  private

  attr_reader :record
end
```

### Prohibitions
```ruby
render json: @record          # nunca — siempre usar serializer
render json: @record.to_json  # nunca
```

### Response Format
```ruby
# Single resource
render json: { record: MySerializer.new(@record).as_json }

# Collection
render json: { records: @records.map { |r| MySerializer.new(r).as_json } }

# Error
render json: { error: { code: "not_found", message: "..." } }, status: :not_found
```

---

## Controllers

### Structure
```ruby
class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:show, :update, :destroy]

  def show
    render json: { record: TransactionSerializer.new(@transaction).as_json }
  end

  def create
    result = CreateTransactionService.new(transaction_params).call
    if result.success?
      render json: { record: TransactionSerializer.new(result.record).as_json }, status: :created
    else
      render json: { error: { code: result.error, message: result.message } }, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: "not_found", message: "Transaccion no encontrada" } }, status: :not_found
  end

  def transaction_params
    params.require(:transaction).permit(:amount, :description, :category_id, :budget_id)
  end
end
```

### Routes
- Recursos Rails convencionales (no API-mode)
- Autenticacion via `authenticate_user!` (Devise)
- snake_case en todos los parametros y respuestas

---

## Database

### Migrations
```ruby
class AddStatusToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :transactions, :status, :string, null: false, default: "pending"
    add_index :transactions, :status
  end
end
```

### Rules
- Migrations always reversible (`change` or `up`/`down` pair)
- Indexes on columns used in `WHERE`, `ORDER`, `JOIN`
- Constraints in DB + validations in model (both layers)
- String columns without explicit `limit` — Rails + PostgreSQL handle the default
- Do not specify charset in migrations — inherited from DB configuration
- Never modify migrations already merged to `development` — create a new migration

### Models
```ruby
class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :budget, optional: true

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :description, presence: true
end
```

### Prohibitions
```ruby
User.first    # nunca — buscar por atributo especifico
ENV["LIST_ID"] # IDs viven en DB, no en .env
```

---

## RuboCop

### Configuration
El proyecto usa `rubocop`. Configuracion en `.rubocop.yml`.

### Before Each Commit
```bash
bundle exec rubocop
```

### Zero Tolerance
- Push with RuboCop offenses is prohibited
- Do not use `# rubocop:disable` without justification in a comment
- Do not modify `.rubocop.yml` to silence offenses — fix the code

### Common Patterns
```ruby
# rubocop offense
def method()
end

# correct
def method
end

# unnecessary string interpolation
"#{variable}"

# correct
variable.to_s
```

---

## Brakeman (Security)

### Before Each Commit
```bash
bundle exec brakeman --no-pager
```

### Rules
- 0 new warnings — compare against project baseline
- If Brakeman reports a warning in code you did not touch → investigate, do not ignore
- Do not use `brakeman --ignore-config` to silence — fix the code

### Most Common Vulnerabilities to Avoid
- Mass assignment without explicit `permit`
- SQL injection via string interpolation in queries
- Command injection via `system`, `exec`, `%x{}`
- Redirect to user-controlled URLs without validation

---

## Testing with RSpec

### File Structure
```
spec/
  requests/           # Request specs for endpoints
  services/           # Unit specs for services
  models/             # Model specs (validations, scopes)
  factories/          # FactoryBot factories
  support/            # Shared helpers
```

### Conventions
```ruby
RSpec.describe MyService, type: :service do
  subject(:service) { described_class.new(param: value) }

  describe "#call" do
    context "cuando el input es valido" do
      it "retorna un resultado exitoso" do
        result = service.call
        expect(result).to be_success
        expect(result.data).to eq(expected_value)
      end
    end

    context "cuando el registro no existe" do
      it "retorna un resultado fallido" do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to eq(:not_found)
      end
    end
  end
end
```

### Minimum Coverage
- 70% global
- 90% in service objects

### Rules
- FactoryBot always — never fixtures
- Request specs for ALL endpoints
- Validation tests with pure RSpec o `shoulda-matchers` (disponible en el proyecto)
- Factories with `sequence` y `Faker` son validos
- Manual DB constraint testing (bypassing model validations) es el patron correcto para verificar unique indexes

### FactoryBot
```ruby
FactoryBot.define do
  factory :transaction do
    sequence(:description) { |n| "Transaccion #{n}" }
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    association :user
    association :category
  end
end
```

---

## Jobs (Sidekiq)

### Structure
```ruby
class RecurringTransactionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    result = ProcessRecurringTransactionsService.new(user: user).call
    Rails.logger.info("[RecurringTransactionsJob] Completado para user #{user_id}: #{result.success?}")
  end
end
```

### Queues
- `default` — jobs generales y procesamiento de transacciones recurrentes
- `automation` — jobs de automatizacion programados (sidekiq-cron)

### Rules
- Jobs must be idempotent — pueden ejecutarse mas de una vez sin efectos adversos
- Verificar el estado del recurso al inicio del job — no asumir que el estado es el esperado
- External API errors → log without re-raise (no agotar reintentos)
- Internal logic errors → permitir que Sidekiq reintente

### Jobs existentes
- `RecurringTransactionsJob` — procesa transacciones recurrentes pendientes
- `ProcessSingleRecurringTransactionJob` — procesa una transaccion recurrente individual
- `RecurringTransactionsCleanupJob` — limpieza de transacciones recurrentes expiradas
