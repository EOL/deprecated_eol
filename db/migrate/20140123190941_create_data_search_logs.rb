class CreateDataSearchLogs < EOL::LoggingMigration
  def self.up
    connection.create_table :data_search_logs do |t|
      t.string :q, limit: 512
      t.string :uri, limit: 512
      t.float :from
      t.float :to
      t.string :sort, limit: 64
      t.string :unit_uri, limit: 512
      t.integer :taxon_concept_id
      t.boolean :clade_was_ignored, default: false
      t.integer :user_id
      t.string :ip_address, limit: 512
      t.integer :number_of_results
      t.float :time_in_seconds
      t.integer :known_uri_id
      t.integer :language_id
      t.timestamps
    end
  end

  def self.down
    connection.drop_table :data_search_logs
  end

end
