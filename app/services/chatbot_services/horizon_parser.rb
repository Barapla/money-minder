# frozen_string_literal: true

module ChatbotServices
  # Saca la fecha objetivo de un mensaje ("hasta el 25 de diciembre", "para 2027").
  # Vivia dentro de SavingsProjector; se extrajo para que la foto financiera que
  # se manda a Claude proyecte al MISMO horizonte que el calculador, y no uno a
  # diciembre y otra a seis meses.
  class HorizonParser
    MONTHS = {
      'enero' => 1, 'febrero' => 2, 'marzo' => 3, 'abril' => 4, 'mayo' => 5, 'junio' => 6,
      'julio' => 7, 'agosto' => 8, 'septiembre' => 9, 'octubre' => 10, 'noviembre' => 11,
      'diciembre' => 12
    }.freeze

    DEFAULT_HORIZON_MONTHS = 6

    def initialize(message)
      @message = message.to_s.downcase
    end

    def self.call(message)
      new(message).call
    end

    # Fecha del mensaje, o nil si no menciona ninguna.
    def call
      return nil unless explicit?

      month = month_in_message
      return Date.new(year, 12, 31) unless month

      date_for(month)
    end

    def call_or_default
      call || DEFAULT_HORIZON_MONTHS.months.from_now.to_date
    end

    private

    attr_reader :message

    def explicit?
      message.match?(/\d{4}/) || MONTHS.keys.any? { |name| message.include?(name) }
    end

    def year
      message[/(20\d{2})/, 1]&.to_i || Date.current.year
    end

    def month_in_message
      MONTHS.keys.find { |name| message.include?(name) }
    end

    # Un dia imposible ("45 de febrero") cae al fin de mes en vez de reventar.
    def date_for(month)
      day = day_for(month)
      return end_of(month) unless day

      Date.new(year, MONTHS[month], day)
    rescue Date::Error
      end_of(month)
    end

    def end_of(month)
      Date.new(year, MONTHS[month], 1).end_of_month
    end

    # "el 25 de diciembre" / "25 diciembre": el numero pegado antes del mes.
    def day_for(month)
      day = message[/(\d{1,2})\s*(?:de\s+)?#{month}/, 1]&.to_i
      day if day&.between?(1, 31)
    end
  end
end
