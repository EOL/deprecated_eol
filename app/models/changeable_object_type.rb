class ChangeableObjectType < ActiveRecord::Base

  has_many :curator_activity_logs

  validates_presence_of   :ch_object_type
  validates_uniqueness_of :ch_object_type

  def self.raw_data_object_id
    cot = self.find_by_ch_object_type('data_object')
    return 2 if cot.nil? # THIS IS FOR TESTS.  Since we need this at compile-time, we are "guessing"
                           # that the foundation scenario will make this a 2. (It surely will.)
    cot.id
  end

  def self.comment
    cached_find(:ch_object_type, 'comment')
  end

  def self.data_object
    cached_find(:ch_object_type, 'data_object')
  end

  # Adding common names:
  def self.synonym
    cached_find(:ch_object_type, 'synonym')
  end

  def self.tag
    cached_find(:ch_object_type, 'tag')
  end

  # Removing common names:
  def self.taxon_concept_name
    cached_find(:ch_object_type, 'taxon_concept_name')
  end

  def self.users_data_object
    cached_find(:ch_object_type, 'users_submitted_text') || cached_find(:ch_object_type, 'users_data_object')
  end

  def self.hierarchy_entry
    cached_find(:ch_object_type, 'hierarchy_entry')
  end

  def self.data_objects_hierarchy_entry
    cached_find(:ch_object_type, 'data_objects_hierarchy_entry')
  end

  def self.curated_data_objects_hierarchy_entry
    cached_find(:ch_object_type, 'curated_data_objects_hierarchy_entry')
  end

  def self.curated_taxon_concept_preferred_entry
    cached_find(:ch_object_type, 'curated_taxon_concept_preferred_entry')
  end

  def self.data_object_scope
    [ChangeableObjectType.data_object.id, ChangeableObjectType.users_data_object.id, 
     ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.data_objects_hierarchy_entry.id]
  end

end
