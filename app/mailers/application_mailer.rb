# frozen_string_literal: true

# ApplicationMailer is the base class for all mailers in the application.
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM', 'no-reply@moneyminder.local')
  layout 'mailer'
end
