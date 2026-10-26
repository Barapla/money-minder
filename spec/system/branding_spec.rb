# frozen_string_literal: true

require 'rails_helper'

# FEAT-039: nuevo logo en navbar, login, favicon y correos.
RSpec.describe 'Branding (FEAT-039)', type: :system do
  let(:user) { create(:user) }

  it 'CA1: muestra el logo y los favicons en la pagina de login' do
    visit new_user_session_path

    expect(page).to have_css('img.auth-logo[src*="logo"]', count: 2)
    expect(page).to have_css('link[rel="icon"][href="/favicon.ico"]', visible: :all)
    expect(page).to have_css('link[rel="icon"][href="/icon.svg"]', visible: :all)
    expect(page).to have_css('link[rel="apple-touch-icon"][href="/apple-touch-icon.png"]', visible: :all)
    expect(page).to have_css('link[rel="manifest"]', visible: :all)
  end

  it 'CA2 y CA3: muestra el logo en el navbar y los favicons estando autenticado' do
    sign_in user
    visit root_path

    expect(page).to have_css('nav img.navbar-logo[src*="logo"]')
    expect(page).to have_css('link[rel="icon"][href="/favicon.ico"]', visible: :all)
  end

  it 'CA4: los correos transaccionales llevan el logo en el encabezado' do
    user.send_reset_password_instructions
    html = ActionMailer::Base.deliveries.last.body.to_s

    expect(html).to include('logo@2x')
  end

  it 'CA3 y CA5: los iconos publicos existen y no estan vacios' do
    %w[favicon.ico icon.svg apple-touch-icon.png icon-192.png icon-512.png].each do |file|
      expect(Rails.public_path.join(file).size).to be_positive
    end
  end
end
