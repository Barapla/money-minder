# frozen_string_literal: true

# Serializa datos basicos de usuario para la API movil.
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: user.id,
      email: user.email,
      name: "#{user.first_name} #{user.last_name}".strip,
      currency: user.currency&.code
    }
  end

  private

  attr_reader :user
end
