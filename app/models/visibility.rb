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
    cached('Invisible') do
      invisible = Visibility.find_by_label('Invisible')
      # The ID *must* be 0 (PHP hard-coded; it also makes /sense/).  If it's not, we fix it now:
      if invisible.id != 0
        Visibility.connection.execute("UPDATE visibilities SET id = 0 WHERE id = #{invisible.id}")
        invisible = Visibility.find_by_label('Invisible')
      end
      invisible
    end
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: visibilities
#
#  id         :integer(4)      not null, primary key
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime

