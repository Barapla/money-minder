class ClaudeService
  include HTTParty

  base_uri 'https://api.anthropic.com'

  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    raise 'ANTHROPIC_API_KEY no está configurada' if @api_key.blank?
  end

  def send_message(prompt:, context: nil, data: nil, model: 'claude-sonnet-4-20250514')
    # Construir el mensaje con contexto y datos
    full_message = build_message(prompt, context, data)

    response = self.class.post(
      '/v1/messages',
      headers: headers,
      body: {
        model: model,
        max_tokens: 4000,
        messages: [
          {
            role: 'user',
            content: full_message
          }
        ]
      }.to_json
    )

    handle_response(response)
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'x-api-key' => @api_key,
      'anthropic-version' => '2023-06-01'
    }
  end

  def build_message(prompt, context, data)
    message_parts = []

    # Agregar contexto si existe
    if context.present?
      message_parts << "Contexto: #{context}"
    end

    # Agregar datos en formato JSON si existen
    if data.present?
      json_data = data.is_a?(String) ? data : data.to_json
      message_parts << "Datos: #{json_data}"
    end

    # Agregar el prompt principal
    message_parts << "Instrucción: #{prompt}"

    message_parts.join("\n\n")
  end

  def handle_response(response)
    case response.code
    when 200
      {
        success: true,
        content: response.parsed_response.dig('content', 0, 'text'),
        usage: response.parsed_response['usage']
      }
    when 400
      {
        success: false,
        error: 'Solicitud inválida',
        details: response.parsed_response['error']
      }
    when 401
      {
        success: false,
        error: 'API Key inválida'
      }
    when 429
      {
        success: false,
        error: 'Límite de rate exceeded'
      }
    else
      {
        success: false,
        error: 'Error desconocido',
        code: response.code,
        details: response.parsed_response
      }
    end
  end
end
