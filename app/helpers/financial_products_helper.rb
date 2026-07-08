# frozen_string_literal: true

# Helpers para vistas de productos financieros y sus beneficios.
module FinancialProductsHelper
  def product_type_badge_class(product_type)
    case product_type.to_s
    when 'cash'         then 'bg-amber-500/20 text-amber-300'
    when 'debit'        then 'bg-blue-500/20 text-blue-300'
    when 'credit'       then 'bg-purple-500/20 text-purple-300'
    when 'savings_fund' then 'bg-emerald-500/20 text-emerald-300'
    else 'bg-bunker-700/50 text-bunker-400'
    end
  end

  def benefit_type_badge_class(benefit_type)
    case benefit_type.to_s
    when 'annual_yield' then 'bg-emerald-500/20 text-emerald-300'
    when 'cashback'     then 'bg-blue-500/20 text-blue-300'
    when 'points'       then 'bg-amber-500/20 text-amber-300'
    when 'discount'     then 'bg-purple-500/20 text-purple-300'
    else 'bg-bunker-700/50 text-bunker-400'
    end
  end

  def benefit_display_value(benefit, field = :base)
    value = field == :reduced ? benefit.reduced_value : benefit.base_value
    return '-' if value.nil?

    case benefit.unit
    when 'percentage'   then "#{number_with_precision(value, precision: 2, strip_insignificant_zeros: true)}%"
    when 'points'       then "#{number_with_delimiter(value.to_i)} #{t('helpers.benefit_display_value.points')}"
    when 'fixed_amount' then number_to_currency(value, unit: '$', delimiter: ',', separator: '.')
    else value.to_s
    end
  end
end
