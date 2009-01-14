class AddNewRightsAndRole < ActiveRecord::Migration
  def self.up
    # gives the administrator rights for the new general site admin controller
    ActiveRecord::Base.connection.execute("INSERT INTO rights(`title`, `controller`,`created_at`) VALUES('General Site Administrator', 'site', NOW())")

  #  role_id = Role.find_by_title('Administrator - Site CMS').id.to_s
  #  right_id = Right.find_by_title('General Site Administrator').id.to_s
  #  ActiveRecord::Base.connection.execute("INSERT INTO rights_roles(`right_id`,`role_id`) VALUES(" + right_id + "," + role_id + ")")
      
  end

  def self.down
    role = Role.find_by_title('Administrator - Site CMS')
   # right=Right.find_by_title('General Site Administrator')
  #  ActiveRecord::Base.connection.execute("DELETE FROM rights_roles WHERE role_id=" + role.id.to_s + " AND right_id=" + right.id.to_s) unless role.nil? || right.nil?
  #  right.destroy unless right.nil?
  end
end
