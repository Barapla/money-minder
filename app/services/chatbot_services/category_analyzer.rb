# frozen_string_literal: true

module ChatbotServices
  # Gasto por categoria del mes actual (CA5). Reutiliza ReportFilter#categories,
  # que ya agrupa transacciones de tipo expense scopeadas al usuario.
  class CategoryAnalyzer
    NO_EXPENSES_WARNING = 'No se encontraron gastos registrados en el periodo analizado.'

    def initialize(user:)
      @user = user
    end

    def calculate
      breakdown = category_breakdown
      total_sum = breakdown.sum { |item| item[:amount] }

      Result.success(data: {
                       result: { primary_metric: total_sum.round(2), breakdown: breakdown },
                       assumptions: assumptions,
                       warnings: breakdown.empty? ? [NO_EXPENSES_WARNING] : []
                     })
    end

    private

    attr_reader :user

    def category_breakdown
      totals = ReportFilter.new(start_date: period_start, end_date: period_end, user: user).categories('expense')
      total_sum = totals.values.sum.to_f

      totals.map do |name, amount|
        percentage = total_sum.positive? ? (amount.to_f / total_sum * 100).round(1) : 0.0
        { label: name, amount: amount.to_f, percentage: percentage }
      end
    end

    def assumptions
      period = "#{period_start.strftime('%d/%m/%Y')} a #{period_end.strftime('%d/%m/%Y')}"
      ["Periodo analizado: #{period} (mes actual).", 'Se excluyen transferencias entre cuentas propias.']
    end

    def period_start
      Date.current.beginning_of_month
    end

    def period_end
      Date.current.end_of_month
    end
  end
end
