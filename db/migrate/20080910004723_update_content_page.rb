class UpdateContentPage < ActiveRecord::Migration
  def self.up
      add_column :content_pages,:language_abbr, :string, :null => false, :default=>'en'
  end

  def self.down
     remove_column :content_pages,:language_abbr
  end
end
