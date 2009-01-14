class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.string :body, :limit=>1500, :null=>false
      t.string :title, :default=>''
      t.datetime :display_date
      t.datetime :activated_on
      t.references :user
      t.boolean :active, :default=>true
      t.timestamps
    end
   
    ActiveRecord::Base.connection.execute("INSERT INTO rights(`title`, `controller`,`created_at`) VALUES('News Item Administrator', 'news_item', NOW())")
    ActiveRecord::Base.connection.execute("INSERT INTO roles(`title`,`created_at`) VALUES('Administrator - News Items', NOW())")

  #  role_id = Role.find_by_title('Administrator - News Items').id.to_s
  #  right_id = Right.find_by_title('News Item Administrator').id.to_s
  #  user_id = User.find_by_username('admin').id.to_s
  #  ActiveRecord::Base.connection.execute("INSERT INTO rights_roles(`right_id`,`role_id`) VALUES(" + right_id + "," + role_id + ")")
  #  ActiveRecord::Base.connection.execute("INSERT INTO roles_users(`user_id`,`role_id`) VALUES(" + user_id + "," + role_id + ")")
        
  end

  def self.down
    drop_table :news_items
    role=Role.find_by_title('Administrator - News Items')
  #  right=Right.find_by_title('News Item Administrator')
  #  ActiveRecord::Base.connection.execute("DELETE FROM rights_roles WHERE role_id=" + role.id.to_s + " AND right_id=" + right.id.to_s) unless role.nil? || right.nil?
  #  ActiveRecord::Base.connection.execute("DELETE FROM roles_users WHERE role_id=" + role.id.to_s) unless role.nil?
  #  role.destroy unless role.nil?
  #  right.destroy unless right.nil?
  end
end
