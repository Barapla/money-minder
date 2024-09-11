# README

# MoneyMinder

MoneyMinder es un gestor de gastos personales, en el cual se podran visualizar de manera grafica cada una de las compras, ventas y transacciones realizadas a lo largo de un periodo determinado.

## Características principales

- Registro de ingresos y gastos
- Categorización de transacciones
- Múltiples monedas
- Transacciones recurrentes
- Informes y visualizaciones

## Tecnologías utilizadas

- Ruby 3.2.2
- Rails 7.0.7
- PostgreSQL 14
- Tailwind CSS 3.3.3
- Node.js 18.18.0
- Yarn 1.22.x

### Prerrequisitos

Asegúrate de tener instalado lo siguiente:

- Ruby
- Rails
- PostgreSQL
- Node.js
- Yarn

## Pasos

### Creación del proyecto

Para crear el proyecto con base de tailwindCSS, Postgresql y esbuild se corre el siguiente comando 

```
   rails new expense-tracker -d postgresql -j esbuild --css tailwind
```

### Agregar Devise y activar ActiveStorage

Para nuestro sistema de Auth utilizaremos la gema Devise y activaremos ActiveStorage para la gestion de archivos

1.- Agregamos la gema en nuestro Gemfile

```
   # Gemfile
   gem 'devise'
```

2.- En la terminal instalamos dependencias y generamos lo necesario

```
   # En la terminal
   bundle install
   rails generate devise:install
   rails active_storage:install
```

3.- Agregamos dominio por default para el envio de correos

```rb
   # config/environments/development.rb
   config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

### Modificar template de migraciones

Modificamos el template de migración en lib/templates/migration/templates/create_table_migration.rb.tt

```tt
   # frozen_string_literal: true

   # <%= migration_class_name %> Class
   class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
   def change
      create_table :<%= table_name %> do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
   <% attributes.each do |attribute| -%>
   <% if attribute.password_digest? -%>
         t.string :password_digest<%= attribute.inject_options %>
   <% elsif attribute.token? -%>
         t.string :<%= attribute.name %><%= attribute.inject_options %>
   <% elsif attribute.reference? -%>
         t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %><%= foreign_key_type %>
   <% elsif !attribute.virtual? -%>
         t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
   <% end -%>
   <% end -%>
   <% if options[:timestamps] %>
         t.timestamps
   <% end -%>
      end

      add_index :<%= table_name %>, :uuid, unique: true
   <% attributes.select(&:token?).each do |attribute| -%>
      add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>, unique: true
   <% end -%>
   <% attributes_with_index.each do |attribute| -%>
      add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
   <% end -%>
   end
   end
```

Esto nos ayudara a poder tener por defecto uuid y active para todos los modelos sin necesidad de agregarlos manualmente

### Creacion de modelos

Para la creacion de nuestros modelos utlizamos los comandos correspondientes siguiendo nuestro diagrama

#### Modelo de roles

```
   rails g model Role name:string
```

#### Modelo de Monedas
```
   rails g model Currency name:string code:string symbol:string exchange_rate:decimal
```

#### Modelo de Usuarios   
```
   rails generate devise User
```

#### Modelo de Categoría
```
   rails g model Category name:string description:text parent_category_id:references
```

#### Modelo de Transacciones
```
   rails g model Transaction amount:decimal description:text transaction_type:integer category:references user:references currency:references transaction_date:date
```

#### Modelo de Transacciones Recurrentes
```
   rails g model RecurringTransaction amount:decimal description:text transaction_type:integer category:references user:references currency:references frequency:integer start_date:date end_date:date
```

Para Continuar modificaremos nuestra migración de usuarios generada por devise, para que contenga los campos uuid, active y el usuario tenga la configuración de confirmar su correo

```rb
# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.0]
   def change
      create_table :users do |t|
         ## Database authenticatable
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :first_name
         t.string :last_name
         t.string :email,              null: false, default: ''
         t.string :encrypted_password, null: false, default: ''

         ## Recoverable
         t.string   :reset_password_token
         t.datetime :reset_password_sent_at

         ## Rememberable
         t.datetime :remember_created_at

         ## Trackable
         # t.integer  :sign_in_count, default: 0, null: false
         # t.datetime :current_sign_in_at
         # t.datetime :last_sign_in_at
         # t.string   :current_sign_in_ip
         # t.string   :last_sign_in_ip

         ## Confirmable
         t.string   :confirmation_token
         t.datetime :confirmed_at
         t.datetime :confirmation_sent_at
         # t.string   :unconfirmed_email # Only if using reconfirmable

         ## Lockable
         # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
         # t.string   :unlock_token # Only if unlock strategy is :email or :both
         # t.datetime :locked_at

         # relationships
         t.references :role, null: false, foreign_key: true
         t.references :currency, null: true, foreign_key: true

         t.timestamps null: false
      end

      add_index :users, :email,                unique: true
      add_index :users, :reset_password_token, unique: true
      add_index :users, :uuid, unique: true
      add_index :users, :confirmation_token, unique: true
      # add_index :users, :unlock_token,         unique: true
   end
end
```

Ademas de modificar nuestra migracion de categoria, para modificar la referencia de categoria padre permitiendonos tener subcategorias

```rb
# frozen_string_literal: true

   # CreateCategories Class
   class CreateCategories < ActiveRecord::Migration[7.0]
    def change
        create_table :categories do |t|
          t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
          t.boolean :active, default: true
          t.string :name
          t.text :description
          t.references :parent_category, foreign_key: { to_table: :categories }, null: true

          t.timestamps
        end

        add_index :categories, :uuid, unique: true
    end
   end
```

### Modificación de modelos

#### Role

- Agregamos validaciones al attributo nombre

```rb
# frozen_string_literal: true

# Role model
class Role < ApplicationRecord
  has_many :users

  validates :name, presence: true, uniqueness: true
end
```

#### Currency

- Agregamos validaciones a name, code y symbol, ademas de agregar relaciones faltantes

```rb
# frozen_string_literal: true

# Currency model
class Currency < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true
  validates :symbol, presence: true
end
```

#### Category

- Agregamos validaciones a name, y relaciones 

```rb
# frozen_string_literal: true

# Category model
class Category < ApplicationRecord
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :sub_categories, class_name: 'Category', foreign_key: 'parent_category_id'
  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
```

#### User

- Agregamos Relaciones faltantes y desbloqueamos el apartado de confirmable

```rb
# frozen_string_literal: true

# User model
class User < ApplicationRecord
   # Include default devise modules. Others available are:
   # :lockable, :timeoutable, :trackable and :omniauthable
   devise :database_authenticatable, :registerable,
            :recoverable, :rememberable, :validatable, :confirmable

   belongs_to :role
   belongs_to :currency, optional: true

   has_many :transactions, dependent: :destroy
   has_many :recurring_transactions, dependent: :destroy
end
```

Los demas modelos se quedan como estan

### Generación de vistas de Devise y controladores

Para generar las vistas de devise ponemos lo siguiente en la terminal 

```
rails g devise:views
```

Para generar los controladores

```
rails g devise:controllers users
```

En las rutas cambiamos el destino a nuestros controladores personalizados de los que sean necesarios, cambiando nuestro config/routes.rb

```rb
devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }
```

### Crear, Migrar y Seedear Base de datos

Para crear algunos seeds personalizados a nuestra bd creamos una carpeta en /db llamada seeds, donde almacenaremos informacion dividad por modelo en jsons 

#### Currency

- Creamos un archivo currencies.json en db/seeds

```json
[
    {
        "name": "Dólar estadounidense",
        "code": "USD",
        "symbol": "$"
    },
    {
        "name": "Euro",
        "code": "EUR",
        "symbol": "€"
    },
    {
        "name": "Peso mexicano",
        "code": "MXN",
        "symbol": "$"
    }
]
```

#### Category

- Creamos un archivo categories.json en db/seeds

```json
{
    "categories": [
      {
        "name": "Vivienda",
        "description": "Gastos relacionados con el hogar y la propiedad. Incluye costos fijos y variables de mantenimiento de la vivienda.",
        "subcategories": [
          {
            "name": "Alquiler/Hipoteca",
            "description": "Pagos mensuales por el lugar de residencia, ya sea alquiler o cuota hipotecaria."
          },
          {
            "name": "Servicios (agua, luz, gas)",
            "description": "Gastos en servicios básicos del hogar, incluyendo agua, electricidad y gas."
          },
          {
            "name": "Internet y teléfono",
            "description": "Costos de conectividad, incluyendo servicio de internet y telefonía fija o móvil."
          },
          {
            "name": "Mantenimiento del hogar",
            "description": "Gastos en reparaciones, mejoras y mantenimiento general de la vivienda."
          },
          {
            "name": "Impuestos sobre la propiedad",
            "description": "Pagos de impuestos relacionados con la propiedad inmobiliaria."
          }
        ]
      },
      {
        "name": "Alimentación",
        "description": "Todos los gastos relacionados con la compra de alimentos y bebidas, tanto en casa como fuera.",
        "subcategories": [
          {
            "name": "Supermercado",
            "description": "Compras de alimentos y artículos de primera necesidad en supermercados o tiendas."
          },
          {
            "name": "Restaurantes",
            "description": "Gastos en comidas en restaurantes, incluyendo propinas y servicios adicionales."
          },
          {
            "name": "Comida rápida",
            "description": "Gastos en establecimientos de comida rápida o para llevar."
          },
          {
            "name": "Café y snacks",
            "description": "Pequeños gastos en cafeterías, máquinas expendedoras o snacks entre comidas."
          }
        ]
      },
      {
        "name": "Transporte",
        "description": "Gastos relacionados con la movilidad y el transporte, incluyendo vehículos propios y transporte público.",
        "subcategories": [
          {
            "name": "Combustible",
            "description": "Gastos en gasolina, diesel u otros combustibles para vehículos."
          },
          {
            "name": "Transporte público",
            "description": "Costos de uso de autobuses, trenes, metro u otros medios de transporte público."
          },
          {
            "name": "Mantenimiento del vehículo",
            "description": "Gastos en reparaciones, revisiones y mantenimiento general de vehículos propios."
          },
          {
            "name": "Seguro del automóvil",
            "description": "Pagos de pólizas de seguro para vehículos."
          },
          {
            "name": "Estacionamiento",
            "description": "Costos de aparcamiento, ya sean regulares o esporádicos."
          }
        ]
      },
      {
        "name": "Salud",
        "description": "Gastos relacionados con el cuidado de la salud física y mental.",
        "subcategories": [
          {
            "name": "Seguro médico",
            "description": "Pagos de primas de seguro de salud, ya sea privado o copagos de seguro público."
          },
          {
            "name": "Medicamentos",
            "description": "Gastos en medicinas recetadas y de venta libre."
          },
          {
            "name": "Consultas médicas",
            "description": "Pagos por visitas a médicos generales o especialistas."
          },
          {
            "name": "Gastos dentales",
            "description": "Costos de tratamientos dentales y cuidado bucal."
          },
          {
            "name": "Gimnasio/Actividades físicas",
            "description": "Gastos en membresías de gimnasio, clases de fitness o equipamiento deportivo."
          }
        ]
      },
      {
        "name": "Educación",
        "description": "Inversiones en formación académica y desarrollo personal.",
        "subcategories": [
          {
            "name": "Matrícula escolar/universitaria",
            "description": "Pagos de matrículas y tasas académicas para educación formal."
          },
          {
            "name": "Libros y materiales",
            "description": "Gastos en libros de texto, material escolar y recursos educativos."
          },
          {
            "name": "Cursos y talleres",
            "description": "Costos de formación adicional, cursos en línea o presenciales, y talleres."
          }
        ]
      },
      {
        "name": "Entretenimiento",
        "description": "Gastos destinados al ocio, diversión y tiempo libre.",
        "subcategories": [
          {
            "name": "Streaming (Netflix, Spotify, etc.)",
            "description": "Suscripciones a servicios de streaming de video, música o podcasts."
          },
          {
            "name": "Cine y eventos",
            "description": "Gastos en entradas para cine, conciertos, teatro u otros eventos culturales."
          },
          {
            "name": "Hobbies",
            "description": "Costos relacionados con pasatiempos personales y actividades recreativas."
          },
          {
            "name": "Viajes y vacaciones",
            "description": "Gastos en viajes, alojamiento y actividades durante vacaciones o escapadas."
          }
        ]
      },
      {
        "name": "Compras personales",
        "description": "Gastos en artículos para uso personal no esenciales.",
        "subcategories": [
          {
            "name": "Ropa y calzado",
            "description": "Compras de prendas de vestir, zapatos y accesorios de moda."
          },
          {
            "name": "Artículos de cuidado personal",
            "description": "Gastos en productos de higiene, cosmética y cuidado personal."
          },
          {
            "name": "Electrónicos y gadgets",
            "description": "Compras de dispositivos electrónicos, accesorios tecnológicos y gadgets."
          }
        ]
      },
      {
        "name": "Deudas y ahorros",
        "description": "Pagos de deudas y asignaciones para ahorro e inversión.",
        "subcategories": [
          {
            "name": "Pago de tarjetas de crédito",
            "description": "Pagos mensuales de saldos de tarjetas de crédito."
          },
          {
            "name": "Préstamos personales",
            "description": "Cuotas de préstamos personales, estudiantiles u otros tipos de créditos."
          },
          {
            "name": "Ahorros e inversiones",
            "description": "Fondos destinados a cuentas de ahorro, inversiones o fondos de emergencia."
          }
        ]
      },
      {
        "name": "Mascotas",
        "description": "Gastos relacionados con el cuidado y mantenimiento de animales domésticos.",
        "subcategories": [
          {
            "name": "Alimentos",
            "description": "Compras de alimentos y snacks para mascotas."
          },
          {
            "name": "Cuidados veterinarios",
            "description": "Gastos en consultas veterinarias, vacunas y tratamientos médicos para mascotas."
          },
          {
            "name": "Accesorios y juguetes",
            "description": "Compras de juguetes, camas, correas y otros accesorios para mascotas."
          }
        ]
      },
      {
        "name": "Regalos y donaciones",
        "description": "Gastos en obsequios para otros y contribuciones caritativas.",
        "subcategories": [
          {
            "name": "Regalos para familiares y amigos",
            "description": "Compras de regalos para cumpleaños, festividades u otras ocasiones especiales."
          },
          {
            "name": "Donaciones a organizaciones benéficas",
            "description": "Contribuciones monetarias a organizaciones sin fines de lucro o causas benéficas."
          }
        ]
      },
      {
        "name": "Servicios profesionales",
        "description": "Gastos en servicios especializados para necesidades personales o profesionales.",
        "subcategories": [
          {
            "name": "Servicios legales",
            "description": "Pagos por asesoría legal, trámites notariales u otros servicios jurídicos."
          },
          {
            "name": "Contabilidad",
            "description": "Gastos en servicios de contabilidad, asesoría fiscal o gestión financiera."
          },
          {
            "name": "Suscripciones profesionales",
            "description": "Cuotas de membresía a organizaciones profesionales o suscripciones a publicaciones especializadas."
          }
        ]
      },
      {
        "name": "Misceláneos",
        "description": "Gastos variados que no encajan en otras categorías específicas.",
        "subcategories": [
          {
            "name": "Gastos imprevistos",
            "description": "Costos inesperados o emergencias no planificadas."
          },
          {
            "name": "Otros gastos no categorizados",
            "description": "Gastos que no encajan en ninguna otra categoría específica."
          }
        ]
      }
    ]
  }
```

#### Seed

En nuestro archivo seeds.rb agregamos lo necesario para que lea estos archivos e ingrese los registros a la db

```rb
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'json'

# Leer el archivo JSON con las monedas

file = File.read(Rails.root.join('db', 'seeds', 'currencies.json'))
currencies_data = JSON.parse(file)

currencies_data.each do |currency_data|
  Currency.create!(
    name: currency_data['name'],
    code: currency_data['code'],
    symbol: currency_data['symbol']
  )
end

# Leer el archivo JSON con las categorías y subcategorías
file = File.read(Rails.root.join('db', 'seeds', 'categories.json'))
categories_data = JSON.parse(file)

# Crear categorías y subcategorías
categories_data['categories'].each do |category_data|
  # Crear la categoría principal
  parent_category = Category.create!(
    name: category_data['name'],
    description: category_data['description']
  )

  # Crear las subcategorías
  category_data['subcategories'].each do |subcategory_data|
    Category.create!(
      name: subcategory_data['name'],
      description: subcategory_data['description'],
      parent_category:
    )
  end
end

puts 'Categorías y subcategorías creadas exitosamente!'

```

#### Comandos

Una vez terminado creamos, migramos y seedeamos la db

```
rails db:create db:migrate db:seed
```

## TailwindCSS, componentes y postcss

Para poder crear nuestras clases personalizadas de tailwind para los diferentes componentes necesitaremos instalar postcss

### PostCSS

#### Instalación
Instalamos postcss al proyecto con:

```
npm install postcss postcss-cli autoprefixer tailwindcss postcss-import --save-dev
```

#### Configuración

Despues crearemos un archivo postcss.config.js en nuestro ruta main del proyecto e insertamos lo siguiente 

```js
module.exports = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    require('autoprefixer'),
    // Add other PostCSS plugins here
  ]
}
```

Modificamos nuestro archivo app/stylesheets/application.tailwind.css con los siguiente

```scss
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

De igual manera modificamos el script que hace build al css de la siguiente manera

```
  "build:css": "tailwindcss --postcss --minify -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css"
```

### TailwindCSS Personalizado

Para crear nuestras propias clases de css creamos una carpeta en app/assets/stylesheets/components

Despues creamos nuestro primer archivo de css personalizado, y en mi caso sera el archivo forms.css y agregamos unas clases

```css
.form-group {
    @apply mb-6 relative;
}
```

Importamos el archivo en el application.tailwind.css como

```scss
@import "components/forms";
```

### Componentes

#### ApplicationComponent

Para la creación de componentes primero crearemos una carpeta en app/components y un archivo llamado application_component.rb, el cual sera la base completa de nuestro rendereo de componentes y su funcionalidad individual, asi como la ruta donde se encontraran los archivos de vista de nuestros componentes

```rb
class ApplicationComponent
  # Content is the value of the block given to the component
  attr_accessor :content

  def self.renders_one(name)
    attr_accessor name

    class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{name}?
        @#{name}.present?
      end
    CODE
  end

  def self.renders_many(name)
    attr_writer name

    class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{name}
        @#{name} || []
      end

      def #{name}?
        @#{name}.present?
      end
    CODE
  end

  # Captures content to be stored later
  def capture_for(name, value = nil, &block)
    value ||= @view_context.capture(&block)
    value = send(name) + [value] if send(name).is_a? Array
    send(:"#{name}=", value)
  end

  # Triggered by Rails' render call
  def render_in(view_context, &block)
    @view_context = view_context
    @content = @view_context.capture(self, &block) if block
    render
  end

  # Handles rendering of the component. Override this to handle rendering differently
  def render
    @view_context.render partial_path, component: self
  end

  def partial_path
    "components/#{component_path}"
  end

  # Scope::MyModalComponent => "components/scope/my_modal"
  def component_path
    self.class.name.delete_suffix('Component').underscore
  end
end
```

#### Componentes

Para crear nuestros componentes tomaremos varios ejemplos en el siguiente archivo README.md

##### Clase Componente

Creamos un archivo llamado input_field_component.rb, el cual será el controlador del componente para los text fields de los formularios

```rb
class InputFieldComponent < ApplicationComponent
  attr_reader :name, :form, :type, :options

  def initialize(name:, form:, type: 'text', options: {})
    @name = name
    @form = form
    @type = type
    @options = options
  end
end

```

##### Vista Componente

Creamos una carpeta llamada app/views/components donde almacenaremos nuestros parciales rendeareables de cada componente

Creamos nuestra vista llamada _input_field.html.erb donde almacenaremos lo necesario para el componente

```html
<%  name = component.name
    form = component.form 
    type = component.type 
    options = component.options || {} %>

<div class="form-group">
    <%= form.label name, class: "form-label" %>
    <%= form.send("#{type}_field", name, class: "form-control", **options) %>
</div>
```

##### Utilización de componentes

Implementamos nuestro componente de la siguiente manera:

```rb
<%= render InputFieldComponent.new(form: form, name: :email, options: { autofocus: true }) %>
```

## Foreman

Para el rendereo automatico del css y los controladores de stimulus utilizaremos foreman 


### Instalación

Primero instalamos la gema en nuestro archivo gemfile

```rb
gem 'foreman'
```

Agregamos la gema con bundle 

```
bundle install
```

### Configuracion

En nuestro archivo config/application.rb agregaremos las configuracion de rendereo de assets al hacer debug

```rb
Rails.application.configure do
  # ... other configurations ...

  # This should be true in development
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # ... other configurations ...
end
```

El proyecto ya viene con un archivo Procfile.dev por defecto, en caso de no ser asi, crea uno en la ruta main y configuralo de esta manera

```
web: env RUBY_DEBUG_OPEN=true bin/rails server
js: yarn build --watch
css: yarn build:css --watch
```

### Implementación

Para abrir un servidor con foreman simplemente corremos el siguiente comando

```
foreman start -f Procfile.dev
```

