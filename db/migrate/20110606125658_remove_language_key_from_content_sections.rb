class RemoveLanguageKeyFromContentSections < ActiveRecord::Migration
  def self.up
    remove_column :content_sections, :language_key
  end

  def self.down
    add_column :content_sections, :language_key, :string
  end
end
