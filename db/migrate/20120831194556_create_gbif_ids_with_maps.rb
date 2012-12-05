class CreateGbifIdsWithMaps < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `gbif_identifiers_with_maps` (
      `gbif_taxon_id` int(11) NOT NULL,
      PRIMARY KEY  (`gbif_taxon_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :gbif_identifiers_with_maps
  end
end
