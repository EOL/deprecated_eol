class AddNewsInPreferredLanguageToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :news_in_preferred_language, :boolean, :default => false
  end

  def self.down
    remove_column :users, :news_in_preferred_language
  end
end