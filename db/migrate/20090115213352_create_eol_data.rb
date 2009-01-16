class CreateEolData < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    ActiveRecord::Migration.not_okay_in_production
    # Basically, I want to throw an error if we're not using MySQL, while at the same time providing the framework
    # for adding other DB support in the future...
    if ActiveRecord::Base.connection.class == ActiveRecord::ConnectionAdapters::MysqlAdapter
      # I was having trouble running the whole thing at once, so I'll break it up by command:
      # Note that this assumes that the file has been DOS-ified.
      IO.readlines("#{RAILS_ROOT}/db/eol_data.sql").to_s.split(/;\s*[\r\n]+/).each do |cmd|
        if cmd =~ /\w/m # Only run commands with text in them.  :)  A few were "\n\n".
          filtered_cmd = cmd.strip
          execute filtered_cmd.gsub(/`([^\.`]+)\.([^`]+)`/, "\\1.`\\2`")
        end
      end
    else
      # Perhaps not the right error class to throw, but I'm not aware of good alternatives:
      raise ActiveRecord::IrreversibleMigration.new("Migration error: Unsupported database for initial schema--this was not written portably.")
    end
  end

  def self.down
    ActiveRecord::Migration.not_okay_in_production
    drop_table "agent_contact_roles"
    drop_table "agent_contacts"
    drop_table "agent_data_types"
    drop_table "agent_provided_data_types"
    drop_table "agent_roles"
    drop_table "agent_statuses"
    drop_table "agents"
    drop_table "agents_data_objects"
    drop_table "agents_hierarchy_entries"
    drop_table "agents_resources"
    drop_table "agents_synonyms"
    drop_table "audiences"
    drop_table "audiences_data_objects"
    drop_table "canonical_forms"
    drop_table "clean_names"
    drop_table "collections"
    drop_table "common_names"
    drop_table "common_names_taxa"
    drop_table "content_partner_agreements"
    drop_table "content_partners"
    drop_table "data_objects"
    drop_table "data_objects_harvest_events"
    drop_table "data_objects_info_items"
    drop_table "data_objects_refs"
    drop_table "data_objects_table_of_contents"
    drop_table "data_objects_taxa"
    drop_table "data_types"
    drop_table "harvest_events"
    drop_table "harvest_events_taxa"
    drop_table "hierarchies"
    drop_table "hierarchies_content"
    drop_table "hierarchies_content_test"
    drop_table "hierarchies_resources"
    drop_table "hierarchy_entries"
    drop_table "hierarchy_entry_names"
    drop_table "hierarchy_entry_relationships"
    drop_table "info_items"
    drop_table "item_pages"
    drop_table "languages"
    drop_table "licenses"
    drop_table "mappings"
    drop_table "mime_types"
    drop_table "name_languages"
    drop_table "names"
    drop_table "normalized_links"
    drop_table "normalized_names"
    drop_table "normalized_qualifiers"
    drop_table "page_names"
    drop_table "publication_titles"
    drop_table "random_taxa"
    drop_table "ranks"
    drop_table "ref_identifier_types"
    drop_table "ref_identifiers"
    drop_table "refs"
    drop_table "refs_taxa"
    drop_table "resource_agent_roles"
    drop_table "resource_statuses"
    drop_table "resources"
    drop_table "resources_taxa"
    drop_table "service_types"
    drop_table "statuses"
    drop_table "synonym_relations"
    drop_table "synonyms"
    drop_table "table_of_contents"
    drop_table "taxa"
    drop_table "taxon_concept_content"
    drop_table "taxon_concept_content_test"
    drop_table "taxon_concept_names"
    drop_table "taxon_concept_relationships"
    drop_table "taxon_concepts"
    drop_table "title_items"
    drop_table "top_images"
    drop_table "top_unpublished_images"
    drop_table "vetted"
    drop_table "visibilities"
  end
end
