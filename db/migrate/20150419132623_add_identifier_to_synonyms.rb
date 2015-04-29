class AddIdentifierToSynonyms < ActiveRecord::Migration
  def change
      add_column :synonyms, :identifier, :text , limit: 10
  end
end
