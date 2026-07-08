# frozen_string_literal: true

# Helpers para vistas de productos financieros.
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
end
