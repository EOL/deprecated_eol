class RecentActivityMailer < ActionMailer::Base

  helper :application, :taxa
  default :from => $NO_REPLY_EMAIL_ADDRESS
  default :content_type => 'text/html'

  layout "v2/email"

  def recent_activity(user, notes, fqz) # :immediately, :daily, :weekly are the only values allowed.
    @user = user
    @notes = notes
    @frequency = fqz
    supress_activity_email = SiteConfigurationOption.find_by_parameter('supress_activity_email').value rescue nil
    puts "++ ACTIVITY EMAIL SUPRESSED." if supress_activity_email
    puts "++ #{Time.now.strftime("%F %T")} - Sending #{notes.count} messages from #{$NO_REPLY_EMAIL_ADDRESS} to: #{supress_activity_email || user.email}"
    set_locale(user)
    mail(
      :subject => I18n.t(:default_subject, :scope => [:recent_activity]),
      :to =>   supress_activity_email || user.email
    )
  end

  #:user => user, :note_ids => notes.map(&:id),
  #:error => e.message, :frequency => fqz)
  def notification_error(options = {})
    puts "!! NOTIFICATIONS FAILED."
    subject "Notifications not sent due to error"
    user_id = SiteConfigurationOption.find_by_parameter('notification_error_user_id').value
    to = user_id ? User.find(user_id) : User.first
    @user = options[:user] || 'unknown'
    @note_ids = options[:note_ids] || ['unknown']
    @error = options[:error] || 'unknown'
    @frequency = options[:fqz].to_s || 'unknown'
    mail(
      :to => to.email
    )
  end

  def set_locale(user)
    user_id = (user.class == User) ? user.id : user
    locale_iso_code = User.find(user,
                            :select => "users.id, users.email, languages.id, languages.iso_639_1",
                            :joins => "JOIN languages ON (users.language_id = languages.id)").language_abbr rescue APPLICATION_DEFAULT_LANGUAGE_ISO
    I18n.locale = locale_iso_code
  end

end
