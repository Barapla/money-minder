# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recurrence, type: :model do
  let(:frequency_types_group) { create(:group_catalog, code: 'frequency_types') }
  let(:recurrenceable_types_group) { create(:group_catalog, code: 'recurrenceable_types') }
  let(:frequency_type_catalog) { create(:catalog, code: 'monthly', group_catalog: frequency_types_group) }
  let(:recurrenceable_type_catalog) do
    create(:catalog, code: 'obligatory_payment', group_catalog: recurrenceable_types_group)
  end

  def build_recurrence(start_date:, frequency_value:, end_date: nil)
    create(:recurrence,
           start_date: start_date,
           frequency_value: frequency_value,
           end_date: end_date,
           frequency_type: frequency_type_catalog,
           recurrenceable_type_catalog: recurrenceable_type_catalog)
  end

  describe '#calculate_next_monthly_occurrence (via #next_occurrence_from)' do
    context 'CA3: intervalo mensual N=1 (mensual simple)' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 15), frequency_value: 1) }

      it 'retorna la ocurrencia del mes actual si el día aún no ha pasado' do
        expect(recurrence.next_occurrence_from(Date.new(2024, 2, 1))).to eq(Date.new(2024, 2, 15))
      end

      it 'retorna la ocurrencia del mes siguiente si el día ya pasó' do
        expect(recurrence.next_occurrence_from(Date.new(2024, 2, 16))).to eq(Date.new(2024, 3, 15))
      end

      it 'genera ocurrencias cada mes sin saltar ninguno' do
        occurrences = recurrence.next_n_occurrences(6, Date.new(2024, 1, 14))
        expect(occurrences).to eq([
                                    Date.new(2024, 1, 15),
                                    Date.new(2024, 2, 15),
                                    Date.new(2024, 3, 15),
                                    Date.new(2024, 4, 15),
                                    Date.new(2024, 5, 15),
                                    Date.new(2024, 6, 15)
                                  ])
      end
    end

    context 'CA1: intervalo mensual N=2 (cada 2 meses)' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 15), frequency_value: 2) }

      it 'no genera ocurrencia en febrero (mes intermedio)' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))
        expect(occurrences).to be_empty
      end

      it 'genera ocurrencia en marzo (mes válido)' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 3, 1), Date.new(2024, 3, 31))
        expect(occurrences).to eq([Date.new(2024, 3, 15)])
      end

      it 'genera ocurrencias solo en enero, marzo, mayo, julio, etc.' do
        occurrences = recurrence.next_n_occurrences(6, Date.new(2024, 1, 14))
        expect(occurrences).to eq([
                                    Date.new(2024, 1, 15),
                                    Date.new(2024, 3, 15),
                                    Date.new(2024, 5, 15),
                                    Date.new(2024, 7, 15),
                                    Date.new(2024, 9, 15),
                                    Date.new(2024, 11, 15)
                                  ])
      end
    end

    context 'CA2: intervalo mensual N=3 (cada 3 meses)' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 10), frequency_value: 3) }

      it 'no genera ocurrencia en febrero ni marzo' do
        expect(recurrence.occurrences_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))).to be_empty
        expect(recurrence.occurrences_in_range(Date.new(2024, 3, 1), Date.new(2024, 3, 31))).to be_empty
      end

      it 'genera ocurrencia en abril' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 4, 1), Date.new(2024, 4, 30))
        expect(occurrences).to eq([Date.new(2024, 4, 10)])
      end

      it 'genera ocurrencias en enero, abril, julio, octubre' do
        occurrences = recurrence.next_n_occurrences(4, Date.new(2024, 1, 9))
        expect(occurrences).to eq([
                                    Date.new(2024, 1, 10),
                                    Date.new(2024, 4, 10),
                                    Date.new(2024, 7, 10),
                                    Date.new(2024, 10, 10)
                                  ])
      end
    end

    context 'intervalo mensual N=6 (semestral)' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 20), frequency_value: 6) }

      it 'genera ocurrencias en enero y julio únicamente' do
        occurrences = recurrence.next_n_occurrences(3, Date.new(2024, 1, 19))
        expect(occurrences).to eq([
                                    Date.new(2024, 1, 20),
                                    Date.new(2024, 7, 20),
                                    Date.new(2025, 1, 20)
                                  ])
      end

      it 'no genera ocurrencias en meses intermedios' do
        %w[2 3 4 5 6].each do |month|
          occurrences = recurrence.occurrences_in_range(
            Date.new(2024, month.to_i, 1),
            Date.new(2024, month.to_i, -1)
          )
          expect(occurrences).to be_empty, "Se esperaba sin ocurrencias en mes #{month}"
        end
      end
    end

    context 'edge case: día 31 en meses con menos días' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 31), frequency_value: 1) }

      it 'ajusta al último día del mes cuando el mes no tiene ese día' do
        expect(recurrence.next_occurrence_from(Date.new(2024, 2, 1))).to eq(Date.new(2024, 2, 29))
        expect(recurrence.next_occurrence_from(Date.new(2024, 3, 1))).to eq(Date.new(2024, 3, 31))
        expect(recurrence.next_occurrence_from(Date.new(2024, 4, 1))).to eq(Date.new(2024, 4, 30))
      end
    end

    context 'edge case: año bisiesto' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 2, 29), frequency_value: 12) }

      it 'retorna el último día de febrero en año no bisiesto' do
        expect(recurrence.next_occurrence_from(Date.new(2025, 2, 1))).to eq(Date.new(2025, 2, 28))
      end
    end

    context 'CA4: cambio de intervalo de 1 a 2 meses' do
      it 'respeta el nuevo intervalo al recalcular ocurrencias futuras' do
        recurrence = build_recurrence(start_date: Date.new(2024, 1, 15), frequency_value: 1)

        expect(recurrence.occurrences_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))).not_to be_empty

        recurrence.update!(frequency_value: 2)

        expect(recurrence.occurrences_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))).to be_empty
        expect(recurrence.occurrences_in_range(Date.new(2024, 3, 1), Date.new(2024, 3, 31))).not_to be_empty
      end
    end

    context 'con end_date configurado' do
      let(:recurrence) do
        build_recurrence(
          start_date: Date.new(2024, 1, 15),
          frequency_value: 2,
          end_date: Date.new(2024, 3, 31)
        )
      end

      it 'no genera ocurrencias después del end_date' do
        expect(recurrence.next_occurrence_from(Date.new(2024, 4, 1))).to be_nil
        expect(recurrence.next_occurrence_from(Date.new(2024, 5, 1))).to be_nil
      end

      it 'genera la ocurrencia correcta antes del end_date' do
        expect(recurrence.next_occurrence_from(Date.new(2024, 3, 1))).to eq(Date.new(2024, 3, 15))
      end
    end
  end

  describe 'validación de start_date (BUG-003)' do
    context 'CA1/CA4: meses anteriores a start_date no generan instancias' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 15), frequency_value: 1) }

      it 'CA1: no retorna instancias para diciembre 2023 cuando start_date es enero 2024' do
        result = recurrence.occurrences_in_range(Date.new(2023, 12, 1), Date.new(2023, 12, 31))
        expect(result).to be_empty
      end

      it 'CA4: no retorna instancias varios meses antes del start_date' do
        result = recurrence.occurrences_in_range(Date.new(2023, 6, 1), Date.new(2023, 6, 30))
        expect(result).to be_empty
      end

      it 'la primera ocurrencia al consultar desde antes es el propio start_date' do
        expect(recurrence.next_occurrence_from(Date.new(2023, 12, 1))).to eq(Date.new(2024, 1, 15))
      end
    end

    context 'CA2: start_date al inicio del mes de inicio' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 6, 1), frequency_value: 1) }

      it 'CA2: la primera instancia aparece el día 1 del mes de inicio' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 6, 1), Date.new(2024, 6, 30))
        expect(occurrences).to eq([Date.new(2024, 6, 1)])
      end

      it 'no genera instancias en el mes anterior al inicio' do
        expect(recurrence.occurrences_in_range(Date.new(2024, 5, 1), Date.new(2024, 5, 31))).to be_empty
      end
    end

    context 'CA3: start_date en medio del mes con frecuencia mensual' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 3, 10), frequency_value: 1) }

      it 'CA3: solo aparece la instancia del día 10 en marzo 2024, no antes' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 3, 1), Date.new(2024, 3, 31))
        expect(occurrences).to eq([Date.new(2024, 3, 10)])
      end

      it 'no genera instancias en febrero 2024 (mes anterior al start_date)' do
        expect(recurrence.occurrences_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))).to be_empty
      end
    end

    context 'CA5: next_n_occurrences no retorna fechas previas a start_date' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 3, 10), frequency_value: 1) }

      it 'CA5: ninguna ocurrencia es anterior a start_date' do
        occurrences = recurrence.next_n_occurrences(5, Date.new(2024, 1, 1))
        expect(occurrences).to all(be >= recurrence.start_date)
      end

      it 'retorna exactamente N ocurrencias válidas a partir de start_date' do
        occurrences = recurrence.next_n_occurrences(3, Date.new(2024, 1, 1))
        expect(occurrences).to eq([
                                    Date.new(2024, 3, 10),
                                    Date.new(2024, 4, 10),
                                    Date.new(2024, 5, 10)
                                  ])
      end
    end

    context 'frecuencia bimestral con fecha anterior a start_date' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 15), frequency_value: 2) }

      it 'no genera instancias 2 meses antes del start_date (mes alineado en ciclo)' do
        expect(recurrence.occurrences_in_range(Date.new(2023, 11, 1), Date.new(2023, 11, 30))).to be_empty
      end

      it 'no genera instancias 1 mes antes del start_date' do
        expect(recurrence.occurrences_in_range(Date.new(2023, 12, 1), Date.new(2023, 12, 31))).to be_empty
      end

      it 'la primera instancia es en start_date al consultar desde antes' do
        expect(recurrence.next_occurrence_from(Date.new(2023, 11, 1))).to eq(Date.new(2024, 1, 15))
      end
    end

    context 'edge case: start_date día 31 en mes siguiente con menos días' do
      let(:recurrence) { build_recurrence(start_date: Date.new(2024, 1, 31), frequency_value: 1) }

      it 'no genera instancias en diciembre 2023' do
        expect(recurrence.occurrences_in_range(Date.new(2023, 12, 1), Date.new(2023, 12, 31))).to be_empty
      end

      it 'la primera ocurrencia al consultar antes de start_date es el 31 de enero' do
        expect(recurrence.next_occurrence_from(Date.new(2023, 11, 1))).to eq(Date.new(2024, 1, 31))
      end
    end
  end

  describe '#occurrences_in_range' do
    context 'regresión: intervalo diario no afectado por el fix mensual' do
      let(:daily_catalog) { create(:catalog, code: 'daily', group_catalog: frequency_types_group) }
      let(:recurrence) do
        create(:recurrence,
               start_date: Date.new(2024, 1, 1),
               frequency_value: 3,
               frequency_type: daily_catalog,
               recurrenceable_type_catalog: recurrenceable_type_catalog)
      end

      it 'genera ocurrencias cada 3 días correctamente' do
        occurrences = recurrence.occurrences_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
        expect(occurrences).to eq([
                                    Date.new(2024, 1, 1),
                                    Date.new(2024, 1, 4),
                                    Date.new(2024, 1, 7),
                                    Date.new(2024, 1, 10)
                                  ])
      end
    end
  end
end
