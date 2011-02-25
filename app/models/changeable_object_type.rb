class ChangeableObjectType < ActiveRecord::Base

  has_many :actions_histories

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

  def self.synonym
    cached_find(:ch_object_type, 'synonym')
  end

  def self.tag
    cached_find(:ch_object_type, 'tag')
  end

  def self.taxon_concept_name
    cached_find(:ch_object_type, 'taxon_concept_name')
  end

  def self.users_submitted_text
    cached_find(:ch_object_type, 'users_submitted_text')
  end

end
