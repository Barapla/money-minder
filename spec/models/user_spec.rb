# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe '#generate_jwt_token' do
    let(:user) { create(:user) }

    it 'retorna un hash con token y expires_at' do
      result = user.generate_jwt_token

      expect(result[:token]).to be_a(String)
      expect(result[:expires_at]).to be_a(String)
    end

    it 'expires_at es 30 dias desde la generacion' do
      travel_to Time.zone.parse('2026-01-01T10:00:00Z') do
        result = user.generate_jwt_token

        expect(result[:expires_at]).to eq(30.days.from_now.iso8601)
      end
    end

    it 'el token generado es decodificable con el user_id correcto' do
      token = user.generate_jwt_token[:token]

      decoded = User.decode_jwt_token(token)

      expect(decoded[0]['user_id']).to eq(user.id)
    end
  end

  describe '.decode_jwt_token' do
    let(:user) { create(:user) }

    it 'decodifica un token valido' do
      token = user.generate_jwt_token[:token]

      decoded = User.decode_jwt_token(token)

      expect(decoded[0]['user_id']).to eq(user.id)
    end

    it 'retorna nil para un token invalido' do
      expect(User.decode_jwt_token('token-invalido')).to be_nil
    end

    it 'retorna nil para un token expirado' do
      token = nil
      travel_to 31.days.ago do
        token = user.generate_jwt_token[:token]
      end

      expect(User.decode_jwt_token(token)).to be_nil
    end
  end
end
