# frozen_string_literal: true

module Payroll
  # Aguinaldo segun el articulo 87 de la Ley Federal del Trabajo.
  #
  # La regla: es una prestacion ANUAL de minimo 15 dias de salario, pagadera
  # antes del 20 de diciembre. Quien no cumplio el año tiene derecho a la parte
  # proporcional al tiempo trabajado DENTRO DE ESE AÑO CALENDARIO.
  #
  # Ojo con dos errores comunes, que esta clase tenia:
  #   1. La antiguedad NO multiplica: alguien con 5 años recibe 15 dias cada
  #      diciembre, nunca 75 de golpe.
  #   2. Lo proporcional se mide sobre el año calendario que se paga, no sobre
  #      los dias transcurridos desde que entro a trabajar. Quien entro en 2024
  #      y sigue ahi trabajo los 365 dias de 2026: le toca completo.
  class AguinaldoCalculator
    def initialize(monthly_gross_salary:, hire_date:, calculation_date: Date.current)
      @monthly_gross_salary = BigDecimal(monthly_gross_salary.to_s)
      @hire_date = hire_date
      @calculation_date = calculation_date
    end

    def call
      return invalid_dates_failure if calculation_date < hire_date

      Result.success(data: {
                       amount: amount,
                       days_worked: days_worked_in_year,
                       days_in_year: days_in_year,
                       year: year,
                       proportional: proportional?
                     })
    rescue ArgumentError, TypeError => e
      Result.failure(error: :configuracion_invalida, message: "#{e.class}: #{e.message}")
    end

    private

    attr_reader :monthly_gross_salary, :hire_date, :calculation_date

    def year
      calculation_date.year
    end

    # El aguinaldo cubre el año completo aunque se pague el 20 de diciembre: si
    # sigues contratado, cuenta hasta el 31.
    def period_start
      [hire_date, Date.new(year, 1, 1)].max
    end

    def days_worked_in_year
      (Date.new(year, 12, 31) - period_start).to_i + 1
    end

    # Se divide entre los dias reales del año para que un año completo de un
    # bisiesto siga dando exactamente 15 dias, no 15.04.
    def days_in_year
      Date.leap?(year) ? 366 : 365
    end

    def proportional?
      days_worked_in_year < days_in_year
    end

    def daily_salary
      monthly_gross_salary / BigDecimal('30')
    end

    def aguinaldo_days
      days = PayrollConstants[:aguinaldo_days]
      raise ArgumentError, 'PayrollConstants[:aguinaldo_days] no está configurado' if days.nil?

      BigDecimal(days.to_s)
    end

    def amount
      (daily_salary * aguinaldo_days * BigDecimal(days_worked_in_year.to_s) /
        BigDecimal(days_in_year.to_s)).round(2)
    end

    def invalid_dates_failure
      Result.failure(
        error: :invalid_dates,
        message: 'La fecha de calculo no puede ser anterior a la fecha de ingreso'
      )
    end
  end
end
