class Visibility < ActiveRecord::Base
  uses_translations
  has_many :data_objects_hierarchy_entry
  has_many :curated_data_objects_hierarchy_entry
  has_many :users_data_objects

  def self.all_ids
    cached('all_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end

  def self.visible
    cached_find_translated(:label, 'Visible')
  end

  def self.preview
    cached_find_translated(:label, 'Preview')
  end
  
  def self.invisible
    cached_find_translated(:label, 'Invisible')
  end
end
