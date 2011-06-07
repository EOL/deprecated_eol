class CreateTranslatedContentSections < ActiveRecord::Migration
  def self.up
    create_table :translated_content_sections do |t|
      t.references :content_section
      t.references :language
      t.string :name
      t.string :phonetic_name
    end
  end

  def self.down
    drop_table :translated_content_sections
  end
end
