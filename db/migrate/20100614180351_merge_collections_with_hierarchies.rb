class MergeCollectionsWithHierarchies < EOL::DataMigration
  def self.up
    execute('alter table hierarchies add `outlink_uri` varchar(255) NULL after `url`')
    execute('alter table hierarchies add `ping_host_url` varchar(255) NULL after `outlink_uri`')
    execute('create table collection_types_hierarchies like collection_types_collections')
    execute('alter table collection_types_hierarchies change `collection_id` `hierarchy_id` int unsigned NOT NULL')
  end
  
  def self.down
    execute('drop table collection_types_hierarchies')
    remove_column :hierarchies, :ping_host_url
    remove_column :hierarchies, :outlink_uri
  end
end
