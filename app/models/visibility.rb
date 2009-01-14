class Visibility < SpeciesSchemaModel

  has_many :data_objects

  @@invisible = nil

  # These are just the class methods to grab the ones you want, without hitting the DB every time...

  def self.all_ids
    @@all_ids ||= Visibility.all.collect {|v| v.id}
  end
  def self.visible
    @@visible ||= Visibility.find_by_label('Visible')
  end
  def self.preview
    @@preview ||= Visibility.find_by_label('Preview')
  end
  def self.inappropriate
    @@inappropriate ||= Visibility.find_by_label('Inappropriate')
  end
  def self.invisible
    @@hidden ||= Visibility.find_by_label('Invisible')
  end
  
  def self.invisible
    return @@invisible unless @@invisible.nil?
    @@invisible = Visibility.find_by_label('Invisible')
    # The ID *must* be 0 (PHP hard-coded; it also makes /sense/).  If it's not, we fix it now:
    if @@invisible.id != 0
      Visibility.connection.execute("UPDATE visibilities SET id = 0 WHERE id = #{@@invisible.id}")
      @@invisible = Visibility.find_by_label('Invisible')
    end
    return @@invisible
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

