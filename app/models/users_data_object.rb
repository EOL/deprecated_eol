require 'eol/activity_log_item'

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

  delegate :created_at, :summary_name, :description_teaser, to: :data_object

  before_create :auto_vet

  alias :link_to :data_object # Needed for rendering links; we need to know which association to make the link to

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

  def guid
    data_object.guid
  end

  # Used when a user-submitted text is replicated. Note that before_create makes vet/vis moot until afterwards.
  def replicate(new_dato)
    udo = UsersDataObject.create(
      user_id: user_id,
      data_object: new_dato,
      taxon_concept_id: taxon_concept_id,
    )
    udo.update_attributes(
      visibility_id: visibility_id,
      vetted_id: vetted_id
    )
    udo
  end

  def italicized_name
    @name ||= taxon_concept.title
  end
  alias :name :italicized_name # Again, duck-typed for Associations. TODO

  def can_be_deleted_by?(requestor)
    false # The original association with the taxon concept while creating the udo should not be removed(same like we don't remove the DOHE associations provided by CPs).
  end

  # Duck-typed method for curation, don't change unless you know what you're doing. :)  TODO - extract to class
  def curatable_object(dato) # I'm ignoring this argument but keeping it to model the duck type.
    UsersDataObject.find_by_data_object_id(data_object.latest_published_version_in_same_language.id)
  end

private
  
  # DataObject#create_user_text and #replicate count on this working, so if you change this, check those!
  def auto_vet
    # full curators and admins get to have it auto-trusted and other users get to have it auto-unreviewed
    self.vetted_id = (user.min_curator_level?(:full) || user.is_admin?) ? Vetted.trusted.id : Vetted.unknown.id
    self.visibility_id = Visibility.visible.id # should be visible if a new revision is created by anyone.
  end

end
