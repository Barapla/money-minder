# frozen_string_literal: true

# ApplicationPresenter is the base class for all presenters in the application.
class ApplicationPresenter
  def initialize(resource)
    @resource = resource
  end
end
