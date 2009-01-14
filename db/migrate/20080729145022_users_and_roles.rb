class UsersAndRoles < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :default_taxonomic_browser, :expertise, :remote_ip , :limit=> 24
      t.integer :content_level
      t.string  :email, :given_name, :family_name, :identity_url
      t.string  :username, :hashed_password, :limit => 32
      t.boolean :flash_enabled, :vetted, :mailing_list, :active
      t.references :language
      t.timestamps      
  end

    create_table(:roles_users, :id => false) do |t|
      t.references :user, :role
    end
#    create_table(:roles_users, :id => false) do |t|
#      t.integer :user_id
#      t.integer :role_id
#    end
    
    execute 'ALTER IGNORE TABLE `roles_users` ADD PRIMARY KEY `key_id_for_users_and_roles` (`role_id`, `user_id`)'
    create_table(:roles) do |t|
      t.string :title
      t.timestamps      
    end

    Role.create(:title=>'Administrator')
    Role.create(:title=>'Curator')
    Role.create(:title=>'Moderator')
    Role.create(:title=>'Administrator - Contact Us Submissions')
    Role.create(:title=>'Administrator - Site CMS')
    Role.create(:title=>'Administrator - Web Users')    
    Role.create(:title=>'Administrator - Content Partners')
    Role.create(:title=>'Administrator - Error Logs')
    Role.create(:title=>'Administrator - Usage Reports')
    
    # The solution is to define the table old-schools style...
    ActiveRecord::Base.connection.execute("INSERT INTO users(`id`,`active`, `given_name`, `family_name`, `username`, `hashed_password`, `email`) VALUES(2,true, 'administrator', 'master', 'admin', '21232f297a57a5a743894a0e4a801fc3', 'no_reply@example.com')") #username admin, password admin
    u_id = User.find_by_username('admin').id
    
    roles = ['Administrator',
    'Administrator - Contact Us Submissions',
    'Administrator - Site CMS',
    'Administrator - Content Partners',
    'Administrator - Error Logs',
    'Administrator - Web Users',
    'Administrator - Usage Reports']
    for r in roles do
      r_id = Role.find_by_title(r).id
      ActiveRecord::Base.connection.execute("INSERT INTO roles_users(`user_id`, `role_id`) VALUES(#{u_id}, #{r_id})")
    end
    
  end

  def self.down
    drop_table :users
    drop_table :roles
    drop_table :roles_users
  end
end
