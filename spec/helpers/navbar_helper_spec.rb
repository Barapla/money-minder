# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavbarHelper, type: :helper do
  describe '#navbar_active_class' do
    context 'cuando la ruta coincide con la página actual' do
      it 'retorna la clase activa' do
        allow(helper).to receive(:current_page?).and_return(true)
        expect(helper.navbar_active_class('/cualquier-ruta')).to eq('navbar-link active')
      end
    end

    context 'cuando la ruta no coincide con la página actual' do
      it 'retorna la clase base' do
        allow(helper).to receive(:current_page?).and_return(false)
        expect(helper.navbar_active_class('/otra-ruta')).to eq('navbar-link')
      end
    end
  end

  describe '#navbar_dropdown_active?' do
    context 'cuando alguna de las rutas coincide con la página actual' do
      it 'retorna true' do
        allow(helper).to receive(:current_page?).with('/ruta-a').and_return(false)
        allow(helper).to receive(:current_page?).with('/ruta-b').and_return(true)
        expect(helper.navbar_dropdown_active?(['/ruta-a', '/ruta-b'])).to be(true)
      end
    end

    context 'cuando ninguna ruta coincide con la página actual' do
      it 'retorna false' do
        allow(helper).to receive(:current_page?).and_return(false)
        expect(helper.navbar_dropdown_active?(['/ruta-a', '/ruta-b'])).to be(false)
      end
    end
  end

  describe '#navbar_dropdown_trigger_class' do
    context 'cuando alguna ruta del grupo está activa' do
      it 'retorna la clase de trigger activa' do
        allow(helper).to receive(:current_page?).and_return(true)
        expect(helper.navbar_dropdown_trigger_class(['/ruta'])).to eq('navbar-dropdown-trigger active')
      end
    end

    context 'cuando ninguna ruta del grupo está activa' do
      it 'retorna la clase base del trigger' do
        allow(helper).to receive(:current_page?).and_return(false)
        expect(helper.navbar_dropdown_trigger_class(['/ruta'])).to eq('navbar-dropdown-trigger')
      end
    end
  end

  describe '#navbar_dropdown_item_class' do
    context 'cuando la ruta es la página actual' do
      it 'retorna la clase activa' do
        allow(helper).to receive(:current_page?).and_return(true)
        expect(helper.navbar_dropdown_item_class('/ruta')).to eq('navbar-dropdown-item active')
      end
    end

    context 'cuando la ruta no es la página actual' do
      it 'retorna la clase base' do
        allow(helper).to receive(:current_page?).and_return(false)
        expect(helper.navbar_dropdown_item_class('/ruta')).to eq('navbar-dropdown-item')
      end
    end
  end

  describe '#navbar_dropdown_item_to' do
    it 'genera un enlace con la clase correcta cuando está activo' do
      allow(helper).to receive(:current_page?).and_return(true)
      result = helper.navbar_dropdown_item_to('Transacciones', '/transactions')
      expect(result).to include('navbar-dropdown-item active')
      expect(result).to include('Transacciones')
    end

    it 'genera un enlace con la clase base cuando no está activo' do
      allow(helper).to receive(:current_page?).and_return(false)
      result = helper.navbar_dropdown_item_to('Transacciones', '/transactions')
      expect(result).to include('navbar-dropdown-item')
      expect(result).not_to include('active')
    end
  end
end
