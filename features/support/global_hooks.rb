def cleanup_database
  curator = User.find_by_username('cucumber_curator')
  if curator
    # tables = User.connection.execute("select distinct table_name from information_schema.columns where table_schema = '#{User.connection.config[:database]}' and column_name = 'user_id'")
  tables = ["actions_histories", "comments", "contacts", "content_uploads", "last_curated_dates", "user_ignored_data_objects", "user_infos", "users_data_objects", "users_data_objects_ratings"]
    tables.each do |table|
      User.connection.execute("delete from #{table} where user_id = #{curator.id}")
    end
  end
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
