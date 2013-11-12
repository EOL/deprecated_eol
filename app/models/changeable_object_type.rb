class ChangeableObjectType < ActiveRecord::Base

  has_many :curator_activity_logs

  validates_presence_of   :ch_object_type
  validates_uniqueness_of :ch_object_type

  def self.default_values
    %w(comment data_object synonym taxon_concept_name tag users_data_object hierarchy_entry
       curated_data_objects_hierarchy_entry data_objects_hierarchy_entry users_submitted_text
       curated_taxon_concept_preferred_entry taxon_concept classification_curation data_point_uri
       user_added_data)
  end

  def self.create_defaults
    default_values.each do |type|
      ChangeableObjectType.create(:ch_object_type => type)
    end

  end

  def self.raw_data_object_id
    cot = self.find_by_ch_object_type('data_object')
    return 2 if cot.nil? # THIS IS FOR TESTS.  Since we need this at compile-time, we are "guessing"
                           # that the foundation scenario will make this a 2. (It surely will.)
    cot.id
  end

  def self.taxon_concept
    @@taxon_concept ||= cached_find(:ch_object_type, 'taxon_concept')
  end

  def self.comment
    @@comment ||= cached_find(:ch_object_type, 'comment')
  end

  def self.data_object
    @@data_object ||= cached_find(:ch_object_type, 'data_object')
  end

  # Adding common names:
  def self.synonym
    @@synonym ||= cached_find(:ch_object_type, 'synonym')
  end

  def self.tag
    @@tag ||= cached_find(:ch_object_type, 'tag')
  end

  # Removing common names:
  def self.taxon_concept_name
    @@taxon_concept_name ||= cached_find(:ch_object_type, 'taxon_concept_name')
  end

  def self.users_data_object
    @@users_data_object ||= cached_find(:ch_object_type, 'users_submitted_text') || cached_find(:ch_object_type, 'users_data_object')
  end
  class << self
    alias_method :users_submitted_text, :users_data_object
  end

  def self.hierarchy_entry
    @@hierarchy_entry ||= cached_find(:ch_object_type, 'hierarchy_entry')
  end

  def self.data_objects_hierarchy_entry
    @@data_objects_hierarchy_entry ||= cached_find(:ch_object_type, 'data_objects_hierarchy_entry')
  end

  def self.curated_data_objects_hierarchy_entry
    @@curated_data_objects_hierarchy_entry ||= cached_find(:ch_object_type, 'curated_data_objects_hierarchy_entry')
  end

  def self.curated_taxon_concept_preferred_entry
    @@curated_taxon_concept_preferred_entry ||= cached_find(:ch_object_type, 'curated_taxon_concept_preferred_entry')
  end

  def self.classification_curation
    @@classification_curation ||= cached_find(:ch_object_type, 'classification_curation')
  end

  def self.data_point_uri
    @@data_point_uri ||= cached_find(:ch_object_type, 'data_point_uri')
  end

  def self.user_added_data
    @@user_added_data ||= cached_find(:ch_object_type, 'user_added_data')
  end

  def self.data_object_scope
    [ChangeableObjectType.data_object.id, ChangeableObjectType.users_data_object.id, 
     ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.data_objects_hierarchy_entry.id]
  end

end
