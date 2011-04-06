class CreateTaxonContentSection < EOL::DataMigration

  def self.up
    create_table :translated_taxon_content_sections do |t|
      t.string :name, :limit => 255
      t.string :phonetic_name, :limit => 255
      t.integer :language_id
      t.integer :taxon_content_section_id
    end
    execute("CREATE UNIQUE INDEX `language_id_taxon_content_section_id` ON `translated_taxon_content_sections`  (`language_id`, `taxon_content_section_id`);")
    create_table :taxon_content_sections do |t|
      t.integer :order
    end
  end

  def self.down
    drop_table :translated_taxon_content_sections
    drop_table :taxon_content_sections
  end

end
