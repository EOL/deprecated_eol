class Notifier < ActionMailer::Base
 
  @@from = $WEBSITE_EMAIL_FROM_ADDRESS
  @@test_recipient = "junk@example.com" # testing only if needed

  def forgot_password_email(user, port)
    subject     "EOL Forgot Password"
    recipients  user.email
    from        @@from
    body        :user => user, :password_reset_url=>user.password_reset_url(port)
  end
  
  def agent_forgot_password_email(agent, new_password)
    subject     "EOL Forgot Password"
    recipients  agent.email
    from        @@from
    body        :agent => agent
  end
  
  def agent_is_ready_for_agreement(agent,recipient)
    subject    "EOL Content Partner Ready For Agreement"
    recipients recipient
    from       @@from
    body       :agent =>agent
  end  
  
  def agent_contact_form_email(agent, contact, recipient)
    subject     "EOL Content Partner Contact"
    recipients  recipient
    from        @@from
    body        :agent => agent, :contact => contact
  end
  
  # NOT CURRENTLY USED
  def donation_eol_email(donation)
    subject     "New Donation"
    recipients  @@test_recipient
    from        @@from
    body        :donation => donation
  end

  # NOT CURRENTLY USED  
  def donation_donator_email(donation)
    subject     "Thank you for your donation"
    recipients  donation.email
    from        @@from
    body        :donation => donation
  end
  
  def welcome_registration(user)
    subject     "Thanks for registering with the Encyclopedia of Life"
    recipients  user.email
    from        @@from
    body        :user => user 
  end

  def registration_confirmation(user)
    subject     "Please confirm your registration with the Encyclopedia of Life"
    recipients  user.email
    from        @@from
    body        :user => user 
  end
  
  def contact_us_auto_response(contact)
    subject     "Thanks for contacting the Encyclopedia of Life"
    recipients  contact.email
    from        @@from
    body        :contact => contact 
  end
  
  def media_contact_auto_response(contact)
    subject     "Thanks for contacting the Encyclopedia of Life"
    recipients  contact.email
    from        @@from
    body        :contact => contact     
  end
  
  def curator_approved(user)
    subject     "Your request to be a curator for the Encyclopedia of Life has been approved"
    recipients  user.email
    from        @@from
    body        :user => user       
  end

  def curator_unapproved(user)
    subject     "Your curator privileges for the Encyclopedia of Life have been removed"
    recipients  user.email
    from        @@from
    body        :user => user       
  end
  
  def user_message(name,email,message)
    subject     "A message from the Encyclopedia of Life"
    recipients  email
    cc          "affiliate@eol.org"
    from        @@from
    body        :name => name, :message => message           
  end
  
  def user_changed_mailer_setting(old_user,new_user,recipient)
    subject     "EOL user changed their mailing list or email address setting"
    recipients  recipient
    from        @@from
    body        :old_user => old_user, :new_user=>new_user
  end
  
  def contact_email(contact)
    
    contact_subject=ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }
    
    subject     "EOL Contact Us: #{contact_subject.title}"
    recipients  contact_recipients
    from        @@from
    body        :contact => contact    
    
  end 

  def monthly_stats(contact_recipient,month,year)
    subject "EOL Monthly Statistics Notification"
    recipients  contact_recipient["email"]
    from        $STATISTICS_EMAIL_FROM_ADDRESS
    body        :contact => contact_recipient , :month => month , :year => year
  end
  
end
