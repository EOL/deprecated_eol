class CreateManyToManyRelationshipsForCollections < ActiveRecord::Migration
  def self.up
    create_table :collections_communities do |t|
      t.integer :collection_id
      t.integer :community_id
    end
    create_table :collections_users do |t|
      t.integer :collection_id
      t.integer :user_id
    end
    Collection.each do |col|
      if col[:community_id]
        Collection.connection.execute("INSERT INTO collections_communities (collection_id, community_id)
                                         VALUES (#{col.id}, #{col[:community_id]})"
      elsif col[:user_id]
        Collection.connection.execute("INSERT INTO collections_users (collection_id, user_id)
                                         VALUES (#{col.id}, #{col[:user_id]})"
      end
    end
    remove_column :collections, :community_id
    remove_column :collections, :user_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
    # if you REALLY need to reverse this, you could *guess* at which value in each of the join tables to put as the
    # single user/community id on the collection entry.  ...but that would be expensive for me to write and the
    # chances that we'd need it are very low, so I don't think it's worth it until it becomes required.
  end
end
