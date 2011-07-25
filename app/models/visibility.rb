class Visibility < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :data_objects

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

  def self.inappropriate
    cached_find_translated(:label, 'Inappropriate')
  end

  def self.invisible
    cached_find_translated(:label, 'Invisible')
  end
end
