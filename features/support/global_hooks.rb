def cleanup_database
  User.connection.execute("delete from users where username = 'cucumber_member' or username = 'cucumber_curator'")
end

####################################
# Create initial global state here #
####################################
cleanup_database

#normal user
member = User.create(:username => 'cucumber_member', :given_name => 'Cuke', :entered_password => 'cucumber_member', :entered_password_confirmation => 'cucumber_member', :email => 'cucumber_member@example.com', :active => true)
member.password = 'cucumber_member'
member.save!

curator = User.create(:username => 'cucumber_curator', :given_name => 'Cuke', :entered_password => 'cucumber_curator', :entered_password_confirmation => 'cucumber_curator', :email => 'cucumber_curator@example.com', :active => true)
curator.password = 'cucumber_curator'
curator.curator_approved = true
curator.curator_hierarchy_entry_id = 33311700
curator.save!


###########################
# Reset global state here #
###########################
at_exit do
  cleanup_database
end
