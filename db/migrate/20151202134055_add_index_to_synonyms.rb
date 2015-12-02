class AddIndexToSynonyms < ActiveRecord::Migration
  def change
    # INSERT INTO `schema_migrations` (`version`) VALUES ('20151202134055')
    add_index :synonyms, [:hierarchy_id, :identifier], name: "by_provider",
      length: {identifier: 64}
  end
end
