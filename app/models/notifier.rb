class Notifier < ActionMailer::Base
 
  @@from = $WEBSITE_EMAIL_FROM_ADDRESS
  @@test_recipient = "junk@example.com" # testing only if needed

  def forgot_password_email(username,password,email)
    subject     "EOL Forgot Password"
    recipients  email
    from        @@from
    body        :username => username,:password=>password
  end
  
  def agent_forgot_password_email(agent, new_password)
    subject     "EOL Content Partner Forgot Password"
    recipients  agent.email
    from        @@from
    body        :agent => agent, :password => new_password
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
  
  def contact_email(contact)
    
    contact_subject=ContactSubject.find(contact.contact_subject_id)
    contact_recipients = contact_subject.recipients
    contact_recipients = contact_recipients.split(',').map { |c| c.strip }
    
    subject     "EOL Contact Us: #{contact_subject.title}"
    recipients  contact_recipients
    from        @@from
    body        :contact => contact    
    
  end  
  
end
