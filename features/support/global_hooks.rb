def cleanup_database
  User.connection.execute("delete from users where username = 'cucumber_member'")
end

####################################
# Create initial global state here #
####################################
cleanup_database

#normal user
member = User.create(:username => 'cucumber_member', :given_name => 'Cuke', :entered_password => 'cucumber_member', :entered_password_confirmation => 'cucumber_member', :email => 'cucumber_member@example.com', :active => true)
member.password = 'cucumber_member'
member.save!

###########################
# Reset global state here #
###########################
at_exit do
  cleanup_database
end
