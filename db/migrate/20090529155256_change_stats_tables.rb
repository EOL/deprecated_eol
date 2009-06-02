class ChangeStatsTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    remove_column :page_stats, :type
    remove_column :page_stats, :taxa_vetted
    remove_column :page_stats, :taxa_unvetted
    remove_column :page_stats, :no_vet_obj
    remove_column :page_stats, :vetted_unknown_published_visible_uniqueGuid
    remove_column :page_stats, :vetted_untrusted_published_visible_uniqueGuid
    remove_column :page_stats, :vetted_unknown_published_notVisible_uniqueGuid
    remove_column :page_stats, :vetted_untrusted_published_notVisible_uniqueGuid
    remove_column :page_stats, :txtfile
    remove_column :page_stats, :total_taxa_inCol_withObject
    remove_column :page_stats, :total_taxa_inCol_withoutObject
    remove_column :page_stats, :total_taxa_notinCol_withObject
    remove_column :page_stats, :total_taxa_notinCol_withoutObject
    
    execute('alter table page_stats add `a_vetted_not_published` longtext default null')
    execute('alter table page_stats add `a_vetted_unknown_published_visible_notinCol` longtext default null')
    execute('alter table page_stats add `a_vetted_unknown_published_visible_inCol` longtext default null')
    
    rename_table :page_stats, :page_stats_taxa
    
    create_table :page_stats_dataobjects do |t|
      t.string :active, :limit  => 1, :default => "n"
      t.integer :taxa_count
      t.integer :vetted_unknown_published_visible_uniqueGuid
      t.integer :vetted_untrusted_published_visible_uniqueGuid
      t.integer :vetted_unknown_published_notVisible_uniqueGuid
      t.integer :vetted_untrusted_published_notVisible_uniqueGuid
      t.date :date_created
      t.time :time_created
      t.timestamp :timestamp
      t.text :a_vetted_unknown_published_visible_uniqueGuid
      t.text :a_vetted_untrusted_published_visible_uniqueGuid
      t.text :a_vetted_unknown_published_notVisible_uniqueGuid
      t.text :a_vetted_untrusted_published_notVisible_uniqueGuid
    end
    
    execute('alter table page_stats_dataobjects modify `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP')
    execute('alter table page_stats_dataobjects modify a_vetted_unknown_published_visible_uniqueGuid longtext default null')
    execute('alter table page_stats_dataobjects modify a_vetted_untrusted_published_visible_uniqueGuid longtext default null')
    execute('alter table page_stats_dataobjects modify a_vetted_unknown_published_notVisible_uniqueGuid longtext default null')
    execute('alter table page_stats_dataobjects modify a_vetted_untrusted_published_notVisible_uniqueGuid longtext default null')
    
    create_table :page_stats_marine do |t|
      t.integer :active, :default => 0
      t.integer :names_from_xml
      t.integer :names_in_eol
      t.integer :marine_pages
      t.integer :pages_with_objects
      t.integer :pages_with_vetted_objects
      t.date :date_created
      t.time :time_created
      t.timestamp :timestamp
    end
    
    execute('alter table page_stats_marine modify `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP')
    execute('alter table page_stats_marine modify active tinyint(1) default 0')
    
  end

  def self.down
    
    drop_table :page_stats_marine
    drop_table :page_stats_dataobjects
    
    rename_table :page_stats_taxa, :page_stats
    
    remove_column :page_stats, :a_vetted_unknown_published_visible_inCol
    remove_column :page_stats, :a_vetted_unknown_published_visible_notinCol
    remove_column :page_stats, :a_vetted_not_published
    
    execute('alter table page_stats add `type` varchar(11) default NULL after `active`')
    execute('alter table page_stats add `taxa_vetted` int(11) default NULL after `type`')
    execute('alter table page_stats add `taxa_unvetted` int(11) default NULL NULL after `taxa_vetted`')
    execute('alter table page_stats add `no_vet_obj` int(11) default NULL after `vet_obj`')
    execute('alter table page_stats add `vetted_unknown_published_visible_uniqueGuid` int(11) default NULL after `vetted_unknown_published_visible_notinCol`')
    execute('alter table page_stats add `vetted_untrusted_published_visible_uniqueGuid` int(11) default NULL after `vetted_unknown_published_visible_uniqueGuid`')
    execute('alter table page_stats add `vetted_unknown_published_notVisible_uniqueGuid` int(11) default NULL after `vetted_untrusted_published_visible_uniqueGuid`')
    execute('alter table page_stats add `vetted_untrusted_published_notVisible_uniqueGuid` int(11) default NULL after `vetted_unknown_published_notVisible_uniqueGuid`')
    execute('alter table page_stats add `txtfile` varchar(255) default NULL after `time_created`')
    execute('alter table page_stats add `total_taxa_inCol_withObject` int(11) default NULL after `txtfile`')
    execute('alter table page_stats add `total_taxa_inCol_withoutObject` int(11) default NULL after `total_taxa_inCol_withObject`')
    execute('alter table page_stats add `total_taxa_notinCol_withObject` int(11) default NULL after `total_taxa_inCol_withoutObject`')
    execute('alter table page_stats add `total_taxa_notinCol_withoutObject` int(11) default NULL after `total_taxa_notinCol_withObject`')
  end
end
