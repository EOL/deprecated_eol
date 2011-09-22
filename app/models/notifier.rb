class Notifier < ActionMailer::Base
  helper :application

  @@test_recipient = "junk@example.com" # testing only if needed

  def curator_approved(user)
    subject     I18n.t(:subject, :curator_level => user.curator_level.label, :scope => [:notifier, :curator_approved])
    recipients  user.email
    from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    body        :user => user
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

  def user_updated_email_preferences(user_before_update, user_after_update, recipient)
    subject     I18n.t(:subject, :user_full_name => user_after_update.full_name, :scope => [:notifier, :user_updated_email_preferences])
    recipients  recipient
    from        $SUPPORT_EMAIL_ADDRESS
    body        :user_before_update => user_before_update,
                :user_after_update => user_after_update
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

#  # TODO: Not being called from anywhere - applicable if we reinstate contact us form - should be tested then
#  def contact_us_auto_response(contact)
#    subject     I18n.t(:subject, :title => contact_subject.title, :scope => [:notifier, :contact_us_auto_response])
#    recipients  contact.email
#    from        $SUPPORT_EMAIL_ADDRESS
#    body        :contact => contact
#  end

  def contact_us_message(contact)
    contact_subject = ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }

    subject     I18n.t(:subject, :title => contact_subject.title, :scope => [:notifier, :contact_us_message])
    recipients  contact_recipients
    from        $SUPPORT_EMAIL_ADDRESS
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

  def comments_and_actions_to_partner_or_user(agent_or_user, activity)
    unless agent_or_user.email.blank?
      # by default send all emails to the curator
      recipient_email = agent_or_user.email

      # Check to see if we have it configured to send all reports to a single email address
      parameter = SiteConfigurationOption.find_by_parameter('email_actions_to_curators_address')
      if parameter && parameter.value
        recipient_email = parameter.value
      end

      subject     I18n.t(:email_subject_summary_of_recent_comments_and_curator_actions_for_your_eol_content)
      recipients  recipient_email
      from        $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
      body        :agent_or_user => agent_or_user, :activity => activity
    end
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

  def content_partner_resource_published(partner, resource, user)
    subject       I18n.t(:subject, :scope => [:notifier, :content_partner_resource_published])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :resource => resource, :user => user
  end

  def content_partner_resource_force_harvest_request(partner, resource, user)
    subject       I18n.t(:subject, :scope => [:notifier, :content_partner_resource_force_harvest_request])
    recipients    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    from          $SUPPORT_EMAIL_ADDRESS
    body          :partner => partner, :resource => resource, :user => user
  end

end
