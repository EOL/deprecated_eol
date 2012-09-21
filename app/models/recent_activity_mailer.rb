class RecentActivityMailer < ActionMailer::Base

  helper :application

  layout "v2/email"

  def recent_activity(user, notes, fqz) # :immediately, :daily, :weekly are the only values allowed.
    @user = user # for the layout
    supress_activity_email = SiteConfigurationOption.find_by_parameter('supress_activity_email').value rescue nil
    puts "++ ACTIVITY EMAIL SUPRESSED." if supress_activity_email
    puts "++ #{Time.now.strftime("%F %T")} - Sending #{notes.count} messages from #{$NO_REPLY_EMAIL_ADDRESS} to: #{supress_activity_email || user.email}"
    set_locale(user)
    subject      I18n.t(:default_subject, :scope => [:recent_activity])
    recipients   supress_activity_email || user.email
    from         $NO_REPLY_EMAIL_ADDRESS
    body         :notes => notes, :user => user, :frequency => fqz
    content_type 'text/html'
  end

  #:user => user, :note_ids => notes.map(&:id),
  #:error => e.message, :frequency => fqz)
  def notification_error(options = {})
    puts "!! NOTIFICATIONS FAILED."
    subject "Notifications not sent due to error"
    user_id = SiteConfigurationOption.find_by_parameter('notification_error_user_id').value
    user = user_id ? User.find(user_id) : User.first
    recipients user.email
    from       $NO_REPLY_EMAIL_ADDRESS
    body       :user => options[:user] || 'unknown', :note_ids => options[:note_ids] || ['unknown'],
               :error => options[:error] || 'unknown', :frequency => options[:fqz].to_s || 'unknown'
    content_type 'text/html'
  end

  def set_locale(user)
    user_id = (user.class == User) ? user.id : user
    locale_iso_code = User.find(user,
                            :select => "users.id, users.email, languages.id, languages.iso_639_1",
                            :joins => "JOIN languages ON (users.language_id = languages.id)").language_abbr rescue APPLICATION_DEFAULT_LANGUAGE_ISO
    I18n.locale = locale_iso_code
  end

end
