class AddFieldsToDataObjects < ActiveRecord::Migration
  def self.up
    # doing two at once is faster
    execute 'ALTER TABLE data_objects ADD COLUMN derived_from TEXT default NULL, ADD COLUMN spatial_location TEXT default NULL'
    execute 'ALTER TABLE hierarchy_entries ADD COLUMN taxon_remarks TEXT default NULL'
    execute 'ALTER TABLE synonyms ADD COLUMN taxon_remarks TEXT default NULL'
  end

  def self.down
    # doing two at once is faster
    execute 'ALTER TABLE data_objects DROP COLUMN derived_from, DROP COLUMN spatial_location'
    remove_column :hierarchy_entries, :taxon_remarks
    remove_column :synonyms, :taxon_remarks
  end
end
