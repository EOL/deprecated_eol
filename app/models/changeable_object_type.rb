class ChangeableObjectType < ActiveRecord::Base

  has_many :curator_activity_logs

  validates_presence_of   :ch_object_type
  validates_uniqueness_of :ch_object_type

  include Enumerated
  enumerated :ch_object_type,  # TODO - would be nice to keep this alphabetical. :\
    %w(comment data_object synonym taxon_concept_name tag users_data_object hierarchy_entry
       curated_data_objects_hierarchy_entry data_objects_hierarchy_entry users_submitted_text
       curated_taxon_concept_preferred_entry taxon_concept classification_curation trait
       user_added_data resource_validation)

  class << self
    alias_method :users_data_object, :users_submitted_text
  end

  def self.raw_data_object_id
    cot = self.find_by_ch_object_type('data_object')
    return 2 if cot.nil? # THIS IS FOR TESTS.  Since we need this at compile-time, we are "guessing"
                           # that the foundation scenario will make this a 2. (It surely will.)
    cot.id
  end

  def self.data_object_scope
    [ChangeableObjectType.data_object.id, ChangeableObjectType.users_data_object.id, 
     ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.data_objects_hierarchy_entry.id]
  end

end
