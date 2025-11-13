# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoneyMinder is a Spanish-language personal expense management application built with Ruby on Rails. It allows users to track income/expenses, categorize transactions, manage multiple currencies, create recurring transactions, and visualize financial data through reports and charts.

**Tech Stack:**
- Ruby 3.2.2
- Rails 7.0.8+
- PostgreSQL 14
- Tailwind CSS 3.4+
- Stimulus (Hotwire)
- Turbo Rails
- esbuild for JavaScript bundling
- Chart.js for visualizations

## Development Commands

### Starting the Development Server

Use Foreman to start the server with automatic CSS/JS rebuilding:
```bash
foreman start -f Procfile.dev
```

This runs three processes:
- Rails server on port 3000
- JavaScript bundler (watch mode)
- CSS bundler (watch mode)

### Database Commands

```bash
# Create, migrate, and seed database
rails db:create db:migrate db:seed

# Reset database (drop, create, migrate, seed)
rails db:reset

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback
```

### Testing

The project uses RSpec for testing:
```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/transaction_spec.rb

# Run specs matching a pattern
bundle exec rspec spec/models/
```

The project also has legacy Minitest files in `test/` directory.

### Asset Building

```bash
# Build JavaScript (one-time)
yarn build

# Build CSS (one-time)
yarn build:css

# Watch mode (automatically handled by Foreman)
yarn build --watch
yarn build:css --watch
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -a
```

### Background Jobs

The application uses Sidekiq for background processing:
```bash
# Access Sidekiq web interface at /sidekiq (when server is running)
```

## Architecture and Key Patterns

### Database Schema Conventions

**All models include:**
- `uuid`: String field with `gen_random_uuid()` default, indexed (unique)
- `active`: Boolean field, defaults to `true`
- Standard Rails timestamps (`created_at`, `updated_at`)

These are automatically added via a custom migration template in `lib/templates/migration/templates/create_table_migration.rb.tt`.

### Component System

The application uses a custom component architecture (similar to ViewComponent):

**ApplicationComponent** (`app/components/application_component.rb`):
- Base class for all components
- Supports `renders_one` and `renders_many` helpers
- Components render partials from `app/views/components/`
- Components are Ruby classes in `app/components/` (e.g., `InputFieldComponent`)
- Partials follow naming: `_component_name.html.erb` (e.g., `_input_field.html.erb`)

**Component Structure:**
```
app/
  components/
    buttons/          # Button components
    calendar/         # Calendar-specific components
    charts/           # Chart.js wrapper components
    forms/            # Form field components
    shared/           # Shared UI components
    table/            # Table components
```

**Example component usage:**
```erb
<%= render InputFieldComponent.new(form: form, name: :email, options: { autofocus: true }) %>
```

### Custom Tailwind CSS

Custom CSS classes are defined in `app/assets/stylesheets/components/`:
- Import new component styles in `application.tailwind.css` using `@import "components/your_file"`
- Use `@apply` directive to compose Tailwind utilities
- Custom color schemes: `azure-radiance` (primary blue) and `bunker` (dark grays)

### Authentication & Authorization

- Uses Devise for authentication with custom controllers in `app/controllers/users/`
- User model includes email confirmation (`:confirmable`)
- Users belong to a Role and have an optional default Currency
- Custom routes defined in `config/routes.rb` for sessions, registrations, and password management

### Key Models

**Core Models:**
- `User`: Devise-based authentication with role and currency associations
- `Transaction`: Income/expense records with category, currency, and user
- `RecurringTransaction`: Template for recurring transactions
- `Category`: Hierarchical (supports parent/child with `parent_category_id`)
- `Budget`: Budget tracking functionality
- `CreditCard` / `CreditCardCycle`: Credit card management with billing cycles
- `Currency`: Multi-currency support with exchange rates
- `ObligatoryPayment`: Recurring payment obligations
- `SavingsFund`: Savings goal tracking
- `AiReport`: AI-generated financial insights

**Utility Models:**
- `Catalog` / `GroupCatalog`: For categorization systems
- `Status`: Status tracking for various entities
- `Recurrence`: Frequency patterns for recurring transactions

### Services

Located in `app/services/`:
- `FinancialInsightsService`: Generates AI-powered financial insights
- `ClaudeService`: Wrapper for Claude AI API integration (uses HTTParty)
- `AiReportService`: Manages AI report generation
- `credit_card_services/`: Credit card-specific business logic

### Controllers

**Main Controllers:**
- `TransactionsController`: CRUD for transactions with filtering (`change_categories`, `transactions_table`)
- `RecurringTransactionsController`: Recurring transaction management with modal support
- `BudgetsController`: Budget management with dynamic type switching
- `CalendarController`: Calendar view with month navigation and day details
- `ReportsController`: Financial reports with various chart endpoints (distribution, flow, comparison)
- `FinancialInsightsController`: AI-generated insights with raw data endpoint for debugging
- `ObligatoryPaymentsController`: Payment obligations management

### Frontend (Stimulus Controllers)

Located in `app/javascript/controllers/`:
- `form_validator_controller.js`: Client-side form validation
- `date_picker_controller.js`: Date picker implementation
- `multiselect_controller.js`: Multi-select dropdowns
- `modal_controller.js`: Modal dialog handling
- `calendar_filter_controller.js` / `calendar_loader_controller.js`: Calendar functionality
- `charts/`: Chart.js integration controllers
- `budgets/`: Budget-specific controllers
- `datatable_filters_controller.js`: Table filtering
- `pagination_controller.js`: Pagination handling
- `recurring_transaction_form_controller.js`: Recurring transaction form logic

### Database Seeding

Seeds are stored as JSON files in `db/seeds/`:
- `currencies.json`: Default currencies (USD, EUR, MXN)
- `categories.json`: Hierarchical expense/income categories with subcategories

The `db/seeds.rb` file reads these JSON files and creates records.

### Environment Configuration

Database connection uses environment variables:
- `PGDATABASE`: Database name
- `PGUSER`: PostgreSQL username
- `PGPASSWORD`: PostgreSQL password
- `PGHOST`: Database host
- `PGPORT`: Database port

The `.env` file (gitignored) contains these values for local development.

## Important Considerations

### Migration Template

When generating new models, the custom migration template automatically adds `uuid` and `active` fields. You don't need to manually specify these in generator commands.

### Devise Configuration

The User model requires:
- `role_id` (belongs_to :role, required)
- `currency_id` (belongs_to :currency, optional)
- Email confirmation is enabled

### PostCSS Pipeline

When adding new CSS:
1. Create files in `app/assets/stylesheets/components/`
2. Import in `application.tailwind.css`
3. Use PostCSS plugins: `postcss-import`, `tailwindcss`, `autoprefixer`

### Component Rendering

Components expect:
- A Ruby class in `app/components/` (inheriting from `ApplicationComponent`)
- A partial in `app/views/components/`
- Access component instance via `component` variable in the partial

### Turbo/Stimulus Integration

- The app uses Turbo for navigation and form submissions
- Stimulus controllers handle client-side interactivity
- Many controllers interact with server endpoints that return Turbo Stream responses
