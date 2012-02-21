class Notifier < ActionMailer::Base
  helper :application

  @@test_recipient = "junk@example.com" # testing only if needed

  def recent_activity(user, notes)
    subject     I18n.t(:subject, :scope => [:notifier, :recent_activity])
    recipients  user.email
    from        $SUPPORT_EMAIL_ADDRESS
    body        :notes => notes, :user => user
  end

  def curator_approved(user)
    subject     I18n.t(:subject, :curator_level => user.curator_level.label, :scope => [:notifier, :curator_approved])
    recipients  user.email
    from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    body        :user => user
  end

  def contact_us_auto_response(contact)
    contact_subject = ContactSubject.find(contact.contact_subject_id)
    contact_from = contact_subject.recipients
    contact_from = contact_from.split(',').map { |c| c.strip }
    subject     I18n.t(:subject, :title => contact_subject.title, :scope => [:notifier, :contact_us_auto_response])
    recipients  contact.email
    from        contact_from
    body        :contact => contact
  end

  def contact_us_message(contact)
    contact_subject = ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }

    subject     I18n.t(:subject, :title => contact_subject.title, :scope => [:notifier, :contact_us_message])
    recipients  contact_recipients
    from        contact.email
    body        :contact => contact
  end

  def content_partner_statistics_reminder(content_partner, content_partner_contact, month, year)
    subject     I18n.t(:subject, :partner_full_name => content_partner.full_name, :month => month,
                                 :year => year, :scope => [:notifier, :content_partner_statistics_reminder])
    recipients  content_partner_contact.email
    from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    body        :content_partner => content_partner, :content_partner_contact => content_partner_contact,
                :month => month, :year => year
  end

  def content_partner_created(partner, user)
    subject       I18n.t(:subject, :partner_full_name => partner.full_name, :user_full_name => user.full_name,
                         :scope => [:notifier, :content_partner_created])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :user => user
  end

  def content_partner_resource_created(partner, resource, user)
    subject       I18n.t(:subject, :partner_full_name => partner.full_name, :resource_title => resource.title,
                         :user_full_name => user.full_name, :scope => [:notifier, :content_partner_resource_created])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :resource => resource, :user => user
  end

  def content_partner_resource_force_harvest_request(partner, resource, user)
    subject       I18n.t(:subject, :partner_full_name => partner.full_name, :resource_title => resource.title,
                         :user_full_name => user.full_name, :scope => [:notifier, :content_partner_resource_force_harvest_request])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :resource => resource, :user => user
  end

  def content_partner_resource_hierarchy_publish_request(partner, resource, hierarchy, user)
    subject       I18n.t(:subject, :partner_full_name => partner.full_name, :resource_title => resource.title,
                         :user_full_name => user.full_name, :scope => [:notifier, :content_partner_resource_hierarchy_publish_request])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :resource => resource, :hierarchy => hierarchy, :user => user
  end

  # TODO: ContentPartnerContact does not have language preference so we can't I18nise this email
  # TODO: What about sending to content partner owner, (WEB-2806)?
  def activity_on_content_partner_content(content_partner, content_partner_contact, activity)
    recipient = set_recipient(content_partner_contact.email)
    unless recipient.blank?
      subject     I18n.t(:subject, :partner_full_name => content_partner.full_name,
                         :scope => [:notifier, :activity_on_content_partner_content])
      recipients  recipient
      from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
      body        :content_partner => content_partner, :content_partner_contact => content_partner_contact,
                  :activity => activity
    end
  end

  # TODO: Since this is a system sent message we should probably be passing the recipient language preference into the I18n strings that make up this message.
  def activity_on_user_content(user, activity)
    recipient = set_recipient(user.email)
    unless recipient.blank?
      subject     I18n.t(:subject, :scope => [:notifier, :activity_on_user_content])
      recipients  recipient
      from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
      body        :user => user, :activity => activity
    end
  end

  def user_activated(user)
    subject     I18n.t(:subject, :scope => [:notifier, :user_activated])
    recipients  user.email
    from        $SUPPORT_EMAIL_ADDRESS
    body        :user => user
  end

  def user_reset_password(user, url)
    subject     I18n.t(:subject, :scope => [:notifier, :user_reset_password])
    recipients  user.email
    from        $SUPPORT_EMAIL_ADDRESS
    body        :user => user, :password_reset_url => url
  end

  def user_verification(user, url)
    subject     I18n.t(:subject, :scope => [:notifier, :user_verification])
    recipients  user.email
    from        $SUPPORT_EMAIL_ADDRESS
    body        :user => user, :verify_user_url => url
  end

  def user_message(name, email, message)
    subject     I18n.t(:subject, :scope => [:notifier, :user_message])
    recipients  email
    cc          $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from        $SUPPORT_EMAIL_ADDRESS
    body        :name => name, :message => message
  end

private
  def set_recipient(email_address)
    # Override recipient if site is configured to send all reports to a single email address
    # TODO: Maybe change this config parameter name, why would we be emailing all reports to a curator?
    # TODO: Cache this parameter, so we don't get SQL call every time?
    parameter = SiteConfigurationOption.find_by_parameter('email_actions_to_curators_address')
    if parameter && parameter.value
      parameter.value
    else
      email_address
    end
  end
end
