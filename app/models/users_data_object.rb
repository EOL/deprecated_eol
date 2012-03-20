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

  before_save :auto_vet

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

  # Used when a user-submitted text is replicated.
  def replicate(new_dato)
    UsersDataObject.create(:user_id => user_id,
                           :data_object => new_dato,
                           :taxon_concept_id => taxon_concept_id,
                           :visibility_id => visibility_id,
                           :vetted_id => vetted_id)
  end

private

  # DataObject#create_user_text and #replicate count on this working, so if you change this, check those!
  def auto_vet
    if user.is_curator? || user.is_admin?
      if user.assistant_curator? # Assistant curators get to keep the vetted value as-is (if it's there)...
        self.vetted_id = Vetted.unknown.id unless self.vetted_id 
      else # ...other curators and admins get to have it auto-trusted:
        self.vetted_id = Vetted.trusted.id
      end
    else
      # ...and other users have it automatically unknown:
      self.vetted_id = Vetted.unknown.id
    end
  end

end
