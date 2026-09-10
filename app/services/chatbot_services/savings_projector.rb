# frozen_string_literal: true

module ChatbotServices
  # Proyecta la liquidez disponible a una fecha futura, considerando el flujo neto
  # mensual de transacciones recurrentes y pagos obligatorios (recurrentes y unicos).
  class SavingsProjector
    MONTHS = {
      'enero' => 1, 'febrero' => 2, 'marzo' => 3, 'abril' => 4, 'mayo' => 5, 'junio' => 6,
      'julio' => 7, 'agosto' => 8, 'septiembre' => 9, 'octubre' => 10, 'noviembre' => 11, 'diciembre' => 12
    }.freeze

    DEFAULT_HORIZON_MONTHS = 6
    INCOMPLETE_DATA_WARNING = 'No tienes pagos obligatorios registrados; ' \
                              'esta proyección podría no reflejar todos tus compromisos futuros.'

    def initialize(user:, message:)
      @user = user
      @message = message.to_s
    end

    def calculate
      Result.success(data: { result: result_hash, assumptions: assumptions, warnings: warnings })
    end

    private

    attr_reader :user, :message

    def result_hash
      months = months_between(Date.current, target_date)
      one_time = one_time_obligatory_total(target_date)

      {
        primary_metric: (current_liquidity + (monthly_net_flow * months) - one_time).round(2),
        breakdown: breakdown_for(months, one_time)
      }
    end

    def breakdown_for(months, one_time)
      [
        { label: 'Liquidez actual', amount: current_liquidity.round(2) },
        { label: 'Flujo neto mensual estimado', amount: monthly_net_flow.round(2) },
        { label: 'Meses proyectados', amount: months },
        { label: 'Pagos obligatorios únicos en el periodo', amount: -one_time.round(2) }
      ]
    end

    def assumptions
      net_flow_note = 'El flujo neto mensual se calcula con transacciones recurrentes ' \
                       'activas y pagos obligatorios recurrentes.'
      ["Fecha objetivo proyectada: #{target_date.strftime('%d/%m/%Y')}.", net_flow_note]
    end

    def warnings
      user.obligatory_payments.none? ? [INCOMPLETE_DATA_WARNING] : []
    end

    def current_liquidity
      @current_liquidity ||= LiquidityServices::Calculator.new(user).total_available_money.to_f
    end

    def monthly_net_flow
      @monthly_net_flow ||= ChatbotServices::NetFlowCalculator.new(user).monthly_net_flow
    end

    def explicit_date?
      message.match?(/\d{4}/) || MONTHS.keys.any? { |m| message.downcase.include?(m) }
    end

    def target_date
      @target_date ||= explicit_date? ? date_from_message : DEFAULT_HORIZON_MONTHS.months.from_now.to_date
    end

    def date_from_message
      year = message[/(20\d{2})/, 1]&.to_i || Date.current.year
      month_name = MONTHS.keys.find { |m| message.downcase.include?(m) }
      month_name ? Date.new(year, MONTHS[month_name], 1).end_of_month : Date.new(year, 12, 31)
    end

    def months_between(from, to)
      ((to.year - from.year) * 12 + (to.month - from.month)).clamp(1, 120)
    end

    def one_time_obligatory_total(target)
      user.obligatory_payments.one_time.where(due_date: Date.current..target).sum(:amount).to_f
    end
  end
end
