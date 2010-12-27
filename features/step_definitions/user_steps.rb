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
  login_as(user)
  Then "I am logged in"
end

Given /^a number comments from (?:a |an |the )?(.+)$/ do |user_type_or_name|
  user = get_user(user_type_or_name)
  @comments = Comment.find_all_by_user_id(user.id)
end

Then /^a number of comments from (?:a |an |the )?(.+) should increase by "([^"]*)"$/ do |user_type_or_name, comments_delta|
  user = get_user(user_type_or_name)
  @comments_current = Comment.find_all_by_user_id(user.id)
  (@comments_current.size - @comments.size).should == comments_delta.to_i
end


When /^I logout$/ do
  visit('/logout')
  Then "I am not logged in"
end
