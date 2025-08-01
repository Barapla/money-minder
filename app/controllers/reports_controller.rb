# frozen_string_literal: true

# ReportsController
class ReportsController < ApplicationController
    def index
        @budget_datasets = Budget.flow_dataset

        if params[:period].present?
            case params[:period]
            when 'daily'
                @labels = (30.days.ago.to_date..Date.current).map { |date|
                                                                date.strftime('%d/%m')
                                                                }
                @income_data = Budget.first.earned_per_frequency('daily')
                @expense_data = Budget.first.expensed_per_frequency('daily')
            when 'weekly'
                @labels = []
                4.downto(1) do |i|
                @labels << "Hace #{i} #{'semana'.pluralize(i)}"
                end
                @labels << 'Esta semana'
                @income_data = Budget.first.earned_per_frequency('weekly')
                @expense_data = Budget.first.expensed_per_frequency('weekly')
            when 'monthly'
                @labels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
                @income_data = Budget.first.earned_per_frequency
                @expense_data = Budget.first.expensed_per_frequency
            end
        end

        respond_to do |format|
            format.html
            format.json do
                render json: {
                    labels: @labels,
                    incomeData: @income_data,
                    expenseData: @expense_data
                }
            end
        end

    end

end
