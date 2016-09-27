class Notifier < ActionMailer::Base

  helper :application, :taxa

  def curator_approved(user)
    @user = user
    mail(
      subject: I18n.t(:subject, curator_level: user.curator_level.translated_label, scope: [:notifier, :curator_approved]),
      to: user.email,
      from: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS )
  end

  def contact_us_auto_response(contact)
    @contact = contact
    contact_subject = ContactSubject.find(contact.contact_subject_id)
    mail(
      subject: I18n.t(:subject, title: contact_subject.title, scope: [:notifier, :contact_us_auto_response]),
      to: contact.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def contact_us_message(contact)
    @contact = contact
    contact_subject = ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }

    mail(
      subject: I18n.t(:subject, title: contact_subject.title, scope: [:notifier, :contact_us_message]),
      to: contact_recipients,
      from: contact.email )
  end

  def content_partner_statistics_reminder(content_partner, content_partner_contact, month, year)
    @content_partner = content_partner
    @content_partner_contact = content_partner_contact
    @month = month
    @year = year
    mail(
      subject: I18n.t(:subject, partner_full_name: content_partner.full_name, month: month,
                                   year: year, scope: [:notifier, :content_partner_statistics_reminder]),
      to: content_partner_contact.email,
      from: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS )
  end

  def content_partner_created(partner, user)
    @partner = partner
    @user = user
    mail(
      subject: I18n.t(:subject, partner_full_name: partner.full_name, user_full_name: user.full_name,
                           scope: [:notifier, :content_partner_created]),
      to: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def content_partner_resource_created(partner, resource, user)
    @partner = partner
    @resource = resource
    @user = user
    mail(
      subject: I18n.t(:subject, partner_full_name: partner.full_name, resource_title: resource.title,
                           user_full_name: user.full_name, scope: [:notifier, :content_partner_resource_created]),
      to: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def content_partner_resource_harvest_requested_request(partner, resource, user)
    @partner = partner
    @resource = resource
    @user = user
    mail(
      subject: I18n.t(:subject, partner_full_name: partner.full_name, resource_title: resource.title,
                           user_full_name: user.full_name, scope: [:notifier, :content_partner_resource_harvest_requested_request]),
      to: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def content_partner_resource_hierarchy_publish_request(partner, resource, hierarchy, user)
    @partner = partner
    @resource = resource
    @hierarchy = hierarchy
    @user = user
    mail(
      subject: I18n.t(:subject, partner_full_name: partner.full_name, resource_title: resource.title,
                           user_full_name: user.full_name, scope: [:notifier, :content_partner_resource_hierarchy_publish_request]),
      to: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  # TODO: ContentPartnerContact does not have language preference so we can't I18nise this email
  # TODO: What about sending to content partner owner, (WEB-2806)?
  def activity_on_content_partner_content(content_partner, content_partner_contact, activity)
    recipient = set_recipient(content_partner_contact.email)
    unless recipient.blank?
      @content_partner = content_partner
      @content_partner_contact = content_partner_contact
      @activity = activity
      mail(
        subject: I18n.t(:subject, partner_full_name: content_partner.full_name,
                           scope: [:notifier, :activity_on_content_partner_content]),
        to: recipient,
        from: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS )
    end
  end

  # TODO: Since this is a system sent message we should probably be passing the recipient language preference into the I18n strings that make up this message.
  def activity_on_user_content(user, activity)
    recipient = set_recipient(user.email)
    unless recipient.blank?
      @user = user
      @activity = activity
      mail(
        subject: I18n.t(:subject, scope: [:notifier, :activity_on_user_content]),
        to: recipient,
        from: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS )
    end
  end

  def user_activated(user)
    @user = user
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :user_activated]),
      to: user.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def user_activated_with_open_authentication(user, translated_oauth_provider)
    @user = user
    @translated_oauth_provider = translated_oauth_provider
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :user_activated_with_open_authentication]),
      to: user.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def user_recover_account(user, temporary_login_url)
    @user = user
    @temporary_login_url = temporary_login_url
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :user_recover_account]),
      to: user.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def user_verification(user, url)
    @user = user
    @verify_user_url = url
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :user_verification]),
      to: user.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def user_message(name, email, message)
    @name = name
    @message = message
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :user_message]),
      to: email,
      cc: $SPECIES_PAGES_GROUP_EMAIL_ADDRESS,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

  def unsubscribed_to_notifications(user)
    @user = user
    mail(
      subject: I18n.t(:subject, scope: [:notifier, :unsubscribed_to_notifications]),
      to: user.email,
      from: $NO_REPLY_EMAIL_ADDRESS )
  end

private
  def set_recipient(email_address)
    # Override recipient if site is configured to send all reports to a single email address
    # TODO: Maybe change this config parameter name, why would we be emailing all reports to a curator?
    # TODO: Cache this parameter, so we don't get SQL call every time?
    parameter = EolConfig.email_actions_to_curators_address
    if parameter
      parameter.value
    else
      email_address
    end
  end
end
