class CreateTableOfContentsTaxonContentSections < EOL::DataMigration
  def self.up
    create_table(:table_of_contents_taxon_content_sections, :id => false) do |t|
      t.integer :table_of_contents_id
      t.integer :taxon_content_section_id
    end
  end

  def self.down
    drop_table :table_of_contents_taxon_content_sections
  end
end
