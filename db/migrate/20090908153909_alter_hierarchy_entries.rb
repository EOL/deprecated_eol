class AlterHierarchyEntries < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up

    # A quick fix before doing anything else:
    execute("update hierarchies_content_test hct join hierarchies_content hc using (hierarchy_entry_id) set hct.map=1 where hc.gbif_image=1")
    execute("update hierarchies_content hc join hierarchy_entries he on (hc.hierarchy_entry_id=he.id) join taxon_concept_content tcc on (he.taxon_concept_id=tcc.taxon_concept_id) set tcc.gbif_image=1 where hc.gbif_image=1")
    execute("update hierarchies_content hc join hierarchy_entries he on (hc.hierarchy_entry_id=he.id) join taxon_concept_content_test tcct on (he.taxon_concept_id=tcct.taxon_concept_id) set tcct.map=1 where hc.gbif_image=1")
    
    # adding fields to hierarchy_entries for curation
    execute("alter table hierarchy_entries add `vetted_id` tinyint(3) unsigned NOT NULL default '0' after `taxon_concept_id`")
    execute("alter table hierarchy_entries add `published` tinyint(3) unsigned NOT NULL default '0' after `vetted_id`")
    
    # adding fields to synonyms for curation
    execute("alter table synonyms add `vetted_id` tinyint(3) unsigned NOT NULL default '0' after `hierarchy_id`")
    execute("alter table synonyms add `published` tinyint(3) unsigned NOT NULL default '0' after `vetted_id`")
    
    # adding field to canonical_forms and populating it
    execute("alter table canonical_forms add `name_id` int(11) unsigned NULL default NULL after `string`")
    add_index :canonical_forms, :name_id
    execute("update names n join canonical_forms cf on (n.canonical_form_id=cf.id) set cf.name_id=n.id where n.string=cf.string")
    
    
    # add some new fields to some denormalized tables
    execute("alter table hierarchies_content add `text_unpublished` tinyint(3) unsigned NOT NULL after `text`, add `image_unpublished` tinyint(3) unsigned NOT NULL after `image`, add `child_image_unpublished` tinyint(3) unsigned NOT NULL after `child_image`, add `map` tinyint(3) unsigned NOT NULL after `gbif_image`")
    remove_column :hierarchies_content, :internal_image
    remove_column :hierarchies_content, :gbif_image
    
    execute("alter table taxon_concept_content add `text_unpublished` tinyint(3) unsigned NOT NULL after `text`, add `image_unpublished` tinyint(3) unsigned NOT NULL after `image`, add `child_image_unpublished` tinyint(3) unsigned NOT NULL after `child_image`, add `map` tinyint(3) unsigned NOT NULL after `gbif_image`")
    remove_column :taxon_concept_content, :internal_image
    remove_column :taxon_concept_content, :gbif_image
    
    # populate the new fields from the old tables before they are deleted
    execute("update hierarchies_content hc join hierarchies_content_test hct using (hierarchy_entry_id) set hc.text_unpublished = hct.text_unpublished, hc.image_unpublished = hct.image_unpublished, hc.child_image_unpublished = hct.child_image_unpublished, hc.map = hct.map")
    execute("update taxon_concept_content tcc join taxon_concept_content_test tcct using (taxon_concept_id) set tcc.text_unpublished = tcct.text_unpublished, tcc.image_unpublished = tcct.image_unpublished, tcc.child_image_unpublished = tcct.child_image_unpublished, tcc.map = tcct.map")
    
    # remove the unnecessary denormalized tables
    drop_table "hierarchies_content_test"
    drop_table "taxon_concept_content_test"
  end

  def self.down
    
    execute("alter table taxon_concept_content add `internal_image` tinyint(3) unsigned NOT NULL after `youtube`")
    execute("alter table taxon_concept_content add `gbif_image` tinyint(3) unsigned NOT NULL after `internal_image`")
    
    remove_column :taxon_concept_content, :text_unpublished
    remove_column :taxon_concept_content, :image_unpublished
    remove_column :taxon_concept_content, :child_image_unpublished
    remove_column :taxon_concept_content, :map
    
    execute("alter table hierarchies_content add `internal_image` tinyint(3) unsigned NOT NULL after `youtube`")
    execute("alter table hierarchies_content add `gbif_image` tinyint(3) unsigned NOT NULL after `internal_image`")
    
    remove_column :hierarchies_content, :text_unpublished
    remove_column :hierarchies_content, :image_unpublished
    remove_column :hierarchies_content, :child_image_unpublished
    remove_column :hierarchies_content, :map
    
    
    execute("CREATE TABLE `taxon_concept_content_test` (
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `text` tinyint(3) unsigned NOT NULL,
      `text_unpublished` tinyint(3) unsigned NOT NULL,
      `image` tinyint(3) unsigned NOT NULL,
      `image_unpublished` tinyint(3) unsigned NOT NULL,
      `child_image` tinyint(3) unsigned NOT NULL,
      `child_image_unpublished` tinyint(3) unsigned NOT NULL,
      `video` tinyint(3) unsigned NOT NULL,
      `video_unpublished` tinyint(3) unsigned NOT NULL,
      `map` tinyint(3) unsigned NOT NULL,
      `map_unpublished` tinyint(3) unsigned NOT NULL,
      `content_level` tinyint(3) unsigned NOT NULL,
      `image_object_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
    execute("CREATE TABLE `hierarchies_content_test` (
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `text` tinyint(3) unsigned NOT NULL,
      `text_unpublished` tinyint(3) unsigned NOT NULL,
      `image` tinyint(3) unsigned NOT NULL,
      `image_unpublished` tinyint(3) unsigned NOT NULL,
      `child_image` tinyint(3) unsigned NOT NULL,
      `child_image_unpublished` tinyint(3) unsigned NOT NULL,
      `video` tinyint(3) unsigned NOT NULL,
      `video_unpublished` tinyint(3) unsigned NOT NULL,
      `map` tinyint(3) unsigned NOT NULL,
      `map_unpublished` tinyint(3) unsigned NOT NULL,
      `content_level` tinyint(3) unsigned NOT NULL,
      `image_object_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
    remove_column :canonical_forms, :name_id
    
    remove_column :synonyms, :published
    remove_column :synonyms, :vetted_id
    
    remove_column :hierarchy_entries, :published
    remove_column :hierarchy_entries, :vetted_id
  end
end
