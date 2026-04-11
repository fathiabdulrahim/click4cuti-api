class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEVISE_MAILER_FROM", "noreply@click4cuti.com")
  layout "mailer"
end
