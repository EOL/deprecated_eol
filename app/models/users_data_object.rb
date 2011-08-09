class UsersDataObject < ActiveRecord::Base

  include EOL::ActivityLogItem
  include EOL::CuratableAssociation

  validates_presence_of :user_id, :data_object_id
  validates_uniqueness_of :data_object_id

  belongs_to :user
  belongs_to :data_object
  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility

  def self.get_user_submitted_data_object_ids(user_id)
    if(user_id == 'All') then
      sql="Select data_object_id From users_data_objects"
      rset = UsersDataObject.find_by_sql([sql])
    else
      sql="Select data_object_id From users_data_objects where user_id = ? "
      rset = UsersDataObject.find_by_sql([sql, user_id])
    end
    obj_ids = Array.new
    rset.each do |rec|
      obj_ids << rec.data_object_id
    end
    return obj_ids
  end

end
