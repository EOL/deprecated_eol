class AddIndexToDataObjectsTranslations < ActiveRecord::Migration
  def self.up
    execute("CREATE INDEX original_data_object_id ON data_object_translations(original_data_object_id)")
  end

  def self.down
    remove_index :data_object_translations, :original_data_object_id
  end
end
