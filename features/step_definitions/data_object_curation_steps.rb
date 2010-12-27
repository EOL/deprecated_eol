Then /^I it should have a new comment with "([^"]*)" and "([^"]*)" for the main picture$/ do |phrase1, phrase2|
  comments = Comment.find_all_by_user_id(get_user('curator').id)
  [phrase1, phrase2].each { |phrase| comments.last.body.should match(phrase) }
end

