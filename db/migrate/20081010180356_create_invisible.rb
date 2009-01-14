class CreateInvisible < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    vis = Visibility.create(:label => 'Invisible')
    Visibility.connection.execute("UPDATE visibilities SET id = 0 WHERE id = #{vis.id}")
  end

  def self.down
    v = Visibility.find_by_label('Invisible')
    v.destroy if v
  end

end
