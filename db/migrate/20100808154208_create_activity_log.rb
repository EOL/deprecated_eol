class CreateActivityLog < EOL::LoggingMigration
  def self.up
    # create_table :activity_logs do |t|
    #   t.integer  :taxon_concept_id
    #   t.integer  :activity_id
    #   t.integer  :link_id
    #   t.integer  :user_id
    #   t.string   :value
    #   t.datetime :created_at
    # end
    # create_table :activities do |t|
    #   t.string :name
    # end
    # create_table :links do |t|
    #   t.string :url
    # end
    # %w(activity_logs activities links).each do |table_name|
    #   LoggingModel.connection.execute("ALTER TABLE #{table_name} ENGINE = MyISAM")
    # end
  end

  def self.down
    drop_table :activity_logs
    drop_table :activities
    drop_table :links
  end
end
