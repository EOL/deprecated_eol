class AddDefaultRatingTwoPointFive < EOL::DataMigration

  def self.up
    change_column :data_objects, :data_rating, :float, :default => 2.5
  end

  def self.down
    change_column :data_objects, :data_rating, :float
  end
end
