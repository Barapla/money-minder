# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_chatbot_bubble', type: :view do
  it 'renderiza la burbuja flotante con el controlador stimulus y el turbo-frame perezoso' do
    render

    expect(rendered).to include('data-controller="chatbot-bubble"')
    expect(rendered).to include('chatbot_bubble_frame')
  end
end
