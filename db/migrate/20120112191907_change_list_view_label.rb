class ChangeListViewLabel < ActiveRecord::Migration
  def self.up
    execute "UPDATE translated_view_styles SET name='List' WHERE name='Names Only'"
  end

  def self.down
    execute "UPDATE translated_view_styles SET name='Names Only' WHERE name='List'"
  end
end
