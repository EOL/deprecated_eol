class CreateCollectionEndorsements < ActiveRecord::Migration
  def self.up
    execute('CREATE TABLE `collection_endorsements` (
      `id` int unsigned NOT NULL AUTO_INCREMENT,
      `collection_id` int unsigned NOT NULL,
      `community_id` int unsigned NOT NULL,
      `member_id` int unsigned,
      PRIMARY KEY  (`id`),
      UNIQUE (`collection_id`, `community_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8') # Clearly doesn't need charset, but you never know, later.
    add_index :collection_endorsements, :collection_id, :name => 'collection_id'
    add_index :collection_endorsements, :community_id, :name => 'community_id'
  end

  def self.down
    drop_table :collection_endorsements
  end
end
