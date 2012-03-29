class RecentActivityMailer < ActionMailer::Base

  helper :application

  layout "v2/email"

  def recent_activity(user, notes)
    set_locale(user)
    subject      I18n.t(:subject, :scope => [:notifier, :recent_activity])
    recipients   user.email
    from         $SUPPORT_EMAIL_ADDRESS
    body         :notes => notes, :user => user
    content_type 'text/html'
  end

  def set_locale(user)
    I18n.locale = User.find(user,
                            :select => "users.id, users.email, languages.id, languages.iso_639_1",
                            :joins => "JOIN languages ON (users.language_id = languages.id)").language_abbr
  end

end
