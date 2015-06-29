class RecentActivityMailer < ActionMailer::Base

  helper :application, :taxa
  default from: $NO_REPLY_EMAIL_ADDRESS
  default content_type: 'text/html'

  layout "email"

  def recent_activity(user, notes, fqz) # :immediately, :daily, :weekly are the only values allowed.
    @user = user
    @notes = notes.compact # NOTE - we would occasionally get notification failures due to nil notes...
    @frequency = fqz
    supress_activity_email =
      EolConfig.find_by_parameter('supress_activity_email').try(:value)
    Rails.logger.error("++ ACTIVITY EMAIL SUPRESSED.") if supress_activity_email
    Rails.logger.error("++ #{Time.now.strftime("%F %T")} - Sending #{notes.count} messages from #{$NO_REPLY_EMAIL_ADDRESS} to: #{supress_activity_email || user.email}")
    set_locale(user)
    mail(
      subject: I18n.t(:default_subject, scope: [:recent_activity]),
      to: supress_activity_email || user.email
    )
  end

  #user: user, note_ids: notes.map(&:id),
  #error: e.message, frequency: fqz)
  def notification_error(options = {})
    Rails.logger.error("!! NOTIFICATIONS FAILED.")
    subject = "Notifications not sent due to error"
    user_id = EolConfig.find_by_parameter('notification_error_user_id').value
    to = user_id ? User.find(user_id) : User.first
    @user = options[:user] || 'unknown'
    @note_ids = options[:note_ids] || ['unknown']
    @error = options[:error] || 'unknown'
    @frequency = options[:fqz].to_s || 'unknown'
    @backtrace = options[:backtrace].to_s || 'unknown'
    set_locale(to)
    mail(
      to: to.email
    )
  end

  def data_search_file_download_ready(data_search_file)
    @user = data_search_file.user
    @show_activity_links_in_email = false
    set_locale(@user)
    mail(
      subject: I18n.t(:subject, scope: [:recent_activity_mailer, :data_search_file_download_ready]),
      to: @user.email,
      from: $NO_REPLY_EMAIL_ADDRESS,
      content_type: 'text/html')
  end
  
  def collection_file_download_ready(collection_download_file)
    @user = collection_download_file.user
    @data_search_file = collection_download_file
    @show_activity_links_in_email = false
    set_locale(@user)
    mail(
      subject: I18n.t(:subject, scope: [:recent_activity_mailer, :collection_download_ready]),
      to: @user.email,
      from: $NO_REPLY_EMAIL_ADDRESS,
      content_type: 'text/html')
  end

  def set_locale(user)
    ActionMailer::Base.default_url_options[:host] ||= 'eol.org' # Sorry, this is a fallback. You should really be
                                                                # specifying this elsewhere.
    user_id = (user.class == User) ? user.id : user
    locale_iso_code = User.find(user,
                            select: "users.id, users.email, languages.id, languages.iso_639_1",
                            joins: "JOIN languages ON (users.language_id = languages.id)").language_abbr rescue APPLICATION_DEFAULT_LANGUAGE_ISO
    I18n.locale = locale_iso_code
  end

end
