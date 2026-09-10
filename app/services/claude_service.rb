# frozen_string_literal: true

# ClaudeService
class ClaudeService
  include HTTParty

  base_uri 'https://api.anthropic.com'

  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    raise 'ANTHROPIC_API_KEY no está configurada' if @api_key.blank?
  end

<<<<<<< Updated upstream
  def send_message(prompt:, context: nil, data: nil, model: 'claude-sonnet-4-20250514')
=======
  def send_message(prompt:, context: nil, data: nil, model: 'claude-sonnet-4-5', max_tokens: 8000)
>>>>>>> Stashed changes
    # Construir el mensaje con contexto y datos
    full_message = build_message(prompt, context, data)

    response = self.class.post(
      '/v1/messages',
      headers:,
      timeout: 120,
      body: {
        model:,
        max_tokens:,
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
    message_parts << "Contexto: #{context}" if context.present?

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
      content = response.parsed_response.dig('content', 0, 'text')

      {
        success: true,
        content:,
        parsed_json: extract_and_parse_json(content),
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

  def extract_and_parse_json(content)
    # Estrategia 1: Buscar JSON directo
    return parse_json_safely(content.strip) if content.strip.start_with?('{')

    # Estrategia 2: Extraer de markdown
    json_match = content.match(/```json\s*(\{.*\})\s*```/m)
    return parse_json_safely(json_match[1]) if json_match

    # Estrategia 3: Buscar primer { hasta último }
    start_idx = content.index('{')
    end_idx = content.rindex('}')

    if start_idx && end_idx && start_idx < end_idx
      json_content = content[start_idx..end_idx]
      return parse_json_safely(json_content)
    end

    nil
  end

  def parse_json_safely(content)
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "JSON Parse Error: #{e.message}"
    Rails.logger.error "Content: #{content[0..500]}..."
    nil
  end
end
