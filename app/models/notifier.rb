class Notifier < ActionMailer::Base
  helper :application

  @@test_recipient = "junk@example.com" # testing only if needed

  def agent_is_ready_for_agreement(agent,recipient)
    subject    I18n.t(:email_subject_partner_ready_for_agreement)
    recipients recipient
    from       $WEBSITE_EMAIL_FROM_ADDRESS
    body       :agent =>agent
  end

  def reset_password(user, url)
    subject     I18n.t(:email_subject_reset_password)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user, :password_reset_url => url
  end

  def verify_user(user, url)
    subject     I18n.t(:email_subject_verify_user)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user, :verify_user_url => url
  end

  def account_activated(user)
    subject     I18n.t(:email_subject_account_activated)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def contact_us_auto_response(contact)
    subject     I18n.t(:email_subject_thanks_for_contacting_the_eol)
    recipients  contact.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def media_contact_auto_response(contact)
    subject     I18n.t(:email_subject_thanks_for_contacting_the_eol)
    recipients  contact.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def curator_approved(user)
    subject     I18n.t(:email_subject_your_request_tobe_a_curator_is_approved)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def curator_unapproved(user)
    subject     I18n.t(:email_subject_your_request_tobe_a_curator_is_disapproved)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def user_message(name,email,message)
    subject     I18n.t(:email_subject_a_message_from_the_eol)
    recipients  email
    cc          "affiliate@eol.org"
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :name => name, :message => message
  end

  def user_changed_mailer_setting(old_user,new_user,recipient)
    subject     I18n.t(:email_subject_eol_user_changed_their_mail_settings)
    recipients  recipient
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :old_user => old_user, :new_user=>new_user
  end

  def contact_email(contact)
    contact_subject=ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }

    subject     I18n.t(:email_subject_eol_contact_us_with_subject, :subject => contact_subject.title)
    recipients  contact_recipients
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def monthly_stats(contact_recipient,month,year)
    subject     I18n.t(:email_subject_eol_monthly_stats_notification)
    recipients  contact_recipient["email"]
    from        $STATISTICS_EMAIL_FROM_ADDRESS
    body        :contact => contact_recipient , :month => month , :year => year , :SITE_DOMAIN_OR_IP => $SITE_DOMAIN_OR_IP
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
      from        $WEBSITE_EMAIL_FROM_ADDRESS
      body        :agent_or_user => agent_or_user, :activity => activity
    end
  end

  # below this line is currently not being used anymore
  # ---------------------------------------------------------

  # def agent_contact_form_email(agent, contact, recipient)
  #   subject     "EOL Content Partner Contact"
  #   recipients  recipient
  #   from        $WEBSITE_EMAIL_FROM_ADDRESS
  #   body        :agent => agent, :contact => contact
  # end

  # def donation_eol_email(donation)
  #   subject     "New Donation"
  #   recipients  @@test_recipient
  #   from        $WEBSITE_EMAIL_FROM_ADDRESS
  #   body        :donation => donation
  # end

  # def donation_donator_email(donation)
  #   subject     "Thank you for your donation"
  #   recipients  donation.email
  #   from        $WEBSITE_EMAIL_FROM_ADDRESS
  #   body        :donation => donation
  # end

end
