class ApplicationMailer < ActionMailer::Base
  
  default from: Settings.mail.sender
  
  layout 'mailer'
  
end
