class Admins::MonthlyNotificationController < AdminsController

  def index
    @page_title = I18n.t(:admin_content_partner_notification)
  end

  def send_email
    @page_title = I18n.t(:admin_content_partner_notification)
    last_month = Time.now - 1.month
    @year = last_month.year.to_s
    @month = last_month.month.to_s
    @recipients = ContentPartner.contacts_for_monthly_stats(@month, @year)
    @recipients.each do |recipient|
      Notifier.deliver_monthly_stats(recipient, @month, @year)
    end
  end

end