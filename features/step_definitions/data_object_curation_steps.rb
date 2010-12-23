Then /^I it should have a new comment with "([^"]*)" and "([^"]*)" for the main picture$/ do |phrase1, phrase2|
  comments = Comment.find_all_by_user_id(User.find_by_username('cucumber_curator').id)
  [phrase1, phrase2].each { |phrase| comments.last.body.should match(phrase) }
end
