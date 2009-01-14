class UserLogDaily < LogDaily
  set_unique_data_column :integer, :user_id
  
  def unique_data_to_s
    u=User.find_by_id(self.user_id)
    if u.blank?
      user_id
    else
      u.full_name
    end
  end
  
end
