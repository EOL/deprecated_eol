# Step definitions for user accounts and authentication

When /^I am not logged in$/ do
  Then %{I should see "login" within personal space}
  And %{I should not see "logout" within personal space}
end

When /^I am logged in$/ do
  Then %{I should not see "login" within personal space}
  Then %{I should see "logout" within personal space}
end

When /^I am logged in as (?:a |an |the )?(.+)$/ do |user_type_or_name|
  # Get actual username, create user if they don't exist, log user in
  user = get_user(user_type_or_name)
  require 'ruby-debug'; debugger
  login_as(user)
  Then "I am logged in"
end

When /^I logout$/ do
  visit('/logout')
  Then "I am not logged in"
end
