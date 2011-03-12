class Visibility < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :data_objects

  def self.all_ids
    cached('all_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end
  
  def self.visible
    cached_find(:label, 'Visible')
  end
  
  def self.preview
    cached_find(:label, 'Preview')
  end
  
  def self.inappropriate
    cached_find(:label, 'Inappropriate')
  end
  
  def self.invisible
    cached_find(:label, 'Invisible')
  end
end
