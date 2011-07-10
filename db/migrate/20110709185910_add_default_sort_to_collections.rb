class AddDefaultSortToCollections < ActiveRecord::Migration
  def self.up
    create_table :sort_styles do |t|
      # Yes, that's right.  Just an ID.  Man, this is a pain in the...
    end
    create_table :translated_sort_styles do |t|
      t.string :name, :limit => 32
      t.references :language, :null => false
      t.references :sort_style, :null => false
    end
    add_column :collections, :sort_style_id, :integer, :null => true
    SortStyle.create_defaults
  end

  def self.down
    remove_column :collections, :sort_style_id
    drop_table :translated_sort_styles
    drop_table :sort_styles
  end
end
