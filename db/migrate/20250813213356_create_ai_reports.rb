# frozen_string_literal: true

# CreateAiReports Class
class CreateAiReports < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_reports do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :user, null: false, foreign_key: { to_table: :users, name: 'fk_ai_reports_users' }

      # Tipo de reporte y contexto
      t.references :report_type, null: false, foreign_key: { to_table: :catalogs, name: 'fk_ai_reports_report_type' }
      t.references :report_subtype, null: true, foreign_key: { to_table: :catalogs, name: 'fk_ai_reports_report_subtype' }
      t.references :reportable, polymorphic: true, null: true, index: true

      # Datos del análisis
      t.date :analysis_period_start
      t.date :analysis_period_end
      t.text :analysis_context

      # Request y Response de IA
      t.jsonb :ai_request_data
      t.jsonb :ai_response_data
      t.jsonb :parsed_insights

      # Metadatos
      t.string :ai_model_used
      t.string :tokens_used
      t.decimal :processing_time, precision: 8, scale: 3
      t.boolean :processing_success, default: true
      t.text :error_message

      # Estados y control
      t.datetime :expires_at, index: true
      t.jsonb :metadata

      t.timestamps
    end

    add_index :ai_reports, :uuid, unique: true
    add_index :ai_reports, [:user_id, :report_type_id, :created_at]
    add_index :ai_reports, [:report_type_id, :analysis_period_start, :analysis_period_end], name: 'index_ai_reports_on_type_and_period'
    add_index :ai_reports, [:user_id, :reportable_type, :reportable_id], name: 'index_ai_reports_on_user_and_reportable'
  end
end
