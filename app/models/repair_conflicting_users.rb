class RepairConflictingUsers < ActionMailer::Base
  
  def none_active(email, name)
    subject "Inactive User Accounts at www.eol.org"
    body :name => name
    recipients ['jrice.blue@gmail.com', 'klans@eol.org']
    from 'support@eol.org'
  end

  def some_active(email, name)
    subject "Inactive User Accounts at www.eol.org"
    body :name => name
    recipients ['jrice.blue@gmail.com', 'klans@eol.org']
    from 'support@eol.org'
  end

  def renamed_user(email, name, new_name)
    subject "User Account Changes at www.eol.org"
    body :name => name, :new_username => new_name
    recipients ['jrice.blue@gmail.com', 'klans@eol.org']
    from 'support@eol.org'
  end

end
