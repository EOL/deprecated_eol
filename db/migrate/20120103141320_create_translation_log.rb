class CreateTranslationLog < EOL::LoggingMigration
  def self.up
    create_table :translation_logs do |t|
      t.string :key, :limit => 128
      t.integer :count, :default => 1
    end
  end

  def self.down
    drop_table :translation_logs
  end
end
