class Notifier < ActionMailer::Base
  helper :application

  @@test_recipient = "junk@example.com" # testing only if needed

  def forgot_password_email(user, url)
    subject     I18n.t(:mail_eol_forgot_password_subj)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user, :password_reset_url => url
  end

  def agent_is_ready_for_agreement(agent,recipient)
    subject    "EOL Content Partner Ready For Agreement"
    recipients recipient
    from       $WEBSITE_EMAIL_FROM_ADDRESS
    body       :agent =>agent
  end

  def agent_contact_form_email(agent, contact, recipient)
    subject     "EOL Content Partner Contact"
    recipients  recipient
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :agent => agent, :contact => contact
  end

  # NOT CURRENTLY USED
  def donation_eol_email(donation)
    subject     "New Donation"
    recipients  @@test_recipient
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :donation => donation
  end

  # NOT CURRENTLY USED
  def donation_donator_email(donation)
    subject     "Thank you for your donation"
    recipients  donation.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :donation => donation
  end

  def welcome_registration(user)
    subject     "Thanks for registering with the Encyclopedia of Life"
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def verify_user(user, url)
    subject     I18n.t(:email_validate_user_subject)
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user, :verify_user_url => url
  end

  def contact_us_auto_response(contact)
    subject     "Thanks for contacting the Encyclopedia of Life"
    recipients  contact.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def media_contact_auto_response(contact)
    subject     "Thanks for contacting the Encyclopedia of Life"
    recipients  contact.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def curator_approved(user)
    subject     "Your request to be a curator for the Encyclopedia of Life has been approved"
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def curator_unapproved(user)
    subject     "Your curator privileges for the Encyclopedia of Life have been removed"
    recipients  user.email
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :user => user
  end

  def user_message(name,email,message)
    subject     "A message from the Encyclopedia of Life"
    recipients  email
    cc          "affiliate@eol.org"
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :name => name, :message => message
  end

  def user_changed_mailer_setting(old_user,new_user,recipient)
    subject     "EOL user changed their mailing list or email address setting"
    recipients  recipient
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :old_user => old_user, :new_user=>new_user
  end

  def contact_email(contact)

    contact_subject=ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }

    subject     "EOL Contact Us: #{contact_subject.title}"
    recipients  contact_recipients
    from        $WEBSITE_EMAIL_FROM_ADDRESS
    body        :contact => contact
  end

  def monthly_stats(contact_recipient,month,year)
    subject     "EOL Monthly Statistics Notification"
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

      subject     "Summary of recent comments & curator actions for your Encyclopedia of Life content"
      recipients  recipient_email
      from        $WEBSITE_EMAIL_FROM_ADDRESS
      body        :agent_or_user => agent_or_user, :activity => activity
    end
  end

end
