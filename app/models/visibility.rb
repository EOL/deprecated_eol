class Visibility < SpeciesSchemaModel

  has_many :data_objects

  def self.all_ids
    Rails.cache.fetch('all_visibility_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end
  def self.visible
    YAML.load(Rails.cache.fetch('visibile_vis') do
      Visibility.find_by_label('Visible').to_yaml
    end)
  end
  def self.preview
    YAML.load(Rails.cache.fetch('preview_vis') do
      Visibility.find_by_label('Preview').to_yaml
    end)
  end
  def self.inappropriate
    YAML.load(Rails.cache.fetch('inappropriate_vis') do
      Visibility.find_by_label('Inappropriate').to_yaml
    end)
  end
  
  def self.invisible
    YAML.load(Rails.cache.fetch('invisible_vis') do
      invisible = Visibility.find_by_label('Invisible')
      # The ID *must* be 0 (PHP hard-coded; it also makes /sense/).  If it's not, we fix it now:
      if invisible.id != 0
        Visibility.connection.execute("UPDATE visibilities SET id = 0 WHERE id = #{invisible.id}")
        invisible = Visibility.find_by_label('Invisible')
      end
      invisible.to_yaml
    end)
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

