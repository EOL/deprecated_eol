class AdminMailer < ActionMailer::Base
  helper :application, :taxa

  default from: $NO_REPLY_EMAIL_ADDRESS
  default content_type: 'text/html'

  layout "email"

  def harvest_complete(summary)
    @summary = summary
    EOL.log("Sending mail to admins...")
    mail(
      subject: "Harvesting Complete",
      to: Permission.harvest_notifications.users.pluck(:email)
    )
  end
end
