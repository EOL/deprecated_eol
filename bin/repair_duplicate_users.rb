#!/opt/local/bin/ruby

@active_emails   = 0
@inactive_emails = 0
@renamed_emails  = 0

def send_none_active_email(email, name)
  puts "   --> **** SENDING NONE ACTIVE EMAIL TO '#{email}'"
  @inactive_emails += 1
  RepairConflictingUsers.deliver_none_active(email, name) unless @inactive_emails > 3
end

def send_some_active_email(email, name)
  puts "   --> **** SENDING SOME ACTIVE EMAIL TO '#{email}' using name '#{name}'"
  @active_emails += 1
  RepairConflictingUsers.deliver_some_active(email, name) unless @active_emails > 3
end

def send_renamed_user_email(email, name, new_name)
  puts "   --> **** SENDING RENAMED USER EMAIL TO '#{email}'"
  @renamed_emails += 1
  RepairConflictingUsers.deliver_renamed_user(email, name, new_name) unless @renamed_emails > 3
end

def delete_user(user)
  puts "   --> Deleting user '#{user.username}'"
  # user.destroy
end

def get_name(user)
  name = user.given_name
  if name.blank?
    family_name = user.family_name
    if family_name.blank? 
      name = "Sir or Madam"
    else 
      name = "Mr. or Mrs. #{family_name}"
    end
  end
  return name
end

def add_number_to_username(user)
  base_name = user.username
  number = 2
  base_name.sub!(/(\d+)$/, '')
  match = $1
  unless match.blank?
    number = match.to_i
    puts "   --> '#{user.username}' already had the number '#{number}' at the end. Using that (appending to #{base_name})."
  end
  while(User.find_by_username("#{base_name}#{number}"))
    puts "   -----> Found existing #{base_name}#{number}"
    number += 1
  end
  return "#{base_name}#{number}"
end

def rename_user(user, new_name)
  puts "   --> Renaming user '#{user.username}' (#{user.id}) to '#{new_name}'"
  # user.username = new_name ; user.save!
end

handled_user_ids = []

# Populating them:
by_email = User.find_by_sql("select email, count(*) c from users group by email having c > 1")
by_email.each do |user_by_email|
  email = user_by_email.email
  next if email.blank? # Not much we can do about these.
  inactive_users = User.find_all_by_email_and_active(email, 0)
  active_users   = User.find_all_by_email_and_active(email, 1)
  if active_users.empty? and inactive_users.empty?
    puts "** WARNING: Could not find any users for '#{email}'... what's up with that?"
  elsif active_users.empty?
    puts "++ Only inactive accounts for '#{email}'... "
    inactive_users.each do |user|
      delete_user(user)
      handled_user_ids << user.id
    end
    send_none_active_email(email, get_name(inactive_users.first))
  elsif inactive_users.empty?
    puts "++ Only active accounts for '#{email}'... Nothing to do."
  else # Neither is empty.
    puts "++ Both active and inactive accounts for '#{email}'... "
    get_name(active_users.first)
    inactive_users.each do |user|
      delete_user(user)
      handled_user_ids << user.id
    end
    send_some_active_email(email, get_name(active_users.first))
  end 
end

by_username = User.find_by_sql("select username, count(*) c from users group by username having c > 1")
by_username.each do |user_by_username|
  users = User.find_all_by_username(user_by_username.username).sort_by(&:id)
  lucky_user = users.shift 
  users.each do |user|
    if handled_user_ids.include? user.id
      puts "   --> We already handled user #{user.id}"
      next
    end
    new_name = add_number_to_username(user)
    rename_user(user, new_name)
    send_renamed_user_email(user.email, get_name(user), new_name)
  end
end

puts '-' * 80
puts "Totals:\n"
puts "Active Emails: #{@active_emails}"
puts "Inactive Emails: #{@inactive_emails}"
puts "Renamed Emails: #{@renamed_emails}"
