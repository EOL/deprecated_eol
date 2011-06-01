class CreateTranslatedContentTables < ActiveRecord::Migration
  def self.up
    create_table :translated_content_tables do |t|
      t.references :content_table
      t.references :language
      t.string :label
      t.string :phonetic_label
    end
  end

  def self.down
    drop_table :translated_content_tables
  end
end
